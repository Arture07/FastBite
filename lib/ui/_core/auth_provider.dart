// lib/ui/_core/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

/// Gerencia o estado de autenticação usando Firebase Authentication
/// e os dados do utilizador armazenados no Cloud Firestore.
class AuthProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;

  User? _currentUserData; // Dados do Firestore
  fb_auth.User? _firebaseUser; // Utilizador do Firebase Auth
  bool _isLoading = true; // Estado de carregamento inicial
  StreamSubscription<fb_auth.User?>? _authStateSubscription;

  // Getters públicos
  User? get currentUser => _currentUserData;
  fb_auth.User? get firebaseUser => _firebaseUser;
  // A fonte da verdade para autenticação é se temos um _firebaseUser
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    debugPrint("AuthProvider (FirebaseAuth): Inicializando e ouvindo estado...");
    _authStateSubscription = _firebaseAuth.authStateChanges().listen(_onAuthStateChanged, onError: (error) {
       debugPrint("AuthProvider: Erro no stream authStateChanges: $error");
       _handleAuthError(); // Trata erro no stream
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    debugPrint("AuthProvider (FirebaseAuth): Listener cancelado. Disposed.");
    super.dispose();
  }

  Future<void> updateUserProfile({
    required String name,
    String? photoURL, // URL da imagem do Firebase Storage
  }) async {
    if (!isAuthenticated || _firebaseUser == null) {
      throw Exception("Utilizador não está autenticado para atualizar o perfil.");
    }
    if (_isLoading) return;
    _setLoading(true);

    try {
      // 1. Atualiza o perfil no Firebase Authentication
      if (_firebaseUser!.displayName != name || (_firebaseUser!.photoURL != photoURL && photoURL != null)) {
        await _firebaseUser!.updateProfile(displayName: name, photoURL: photoURL);
        // Recarrega o _firebaseUser para ter os dados mais recentes do Auth
        await _firebaseUser!.reload(); 
        _firebaseUser = _firebaseAuth.currentUser; // Pega a instância atualizada
        debugPrint("AuthProvider: Perfil no Firebase Auth atualizado.");
      }

      // 2. Atualiza os dados no Firestore na coleção 'users'
      // Prepara os dados para atualização, apenas os que podem mudar
      Map<String, dynamic> dataToUpdate = {
        'name': name,
      };
      if (photoURL != null) {
        // Supondo que seu modelo User tem um campo como 'userImagePath' ou similar
        // Se o modelo User usa 'photoURL' diretamente, ajuste aqui.
        dataToUpdate['userImagePath'] = photoURL; 
      }

      await _firestore.collection('users').doc(_firebaseUser!.uid).update(dataToUpdate);
      debugPrint("AuthProvider: Dados do utilizador no Firestore atualizados.");

      // 3. Atualiza o _currentUserData local para refletir na UI imediatamente
      if (_currentUserData != null) {
        _currentUserData = _currentUserData!.copyWith(
          name: name,
          userImagePath: photoURL ?? _currentUserData!.userImagePath, // Mantém o antigo se o novo for nulo
        );
      }
      _setLoading(false); // Notifica após todas as atualizações
      // notifyListeners() já é chamado por _setLoading

    } on fb_auth.FirebaseAuthException catch (e) {
      _setLoading(false);
      debugPrint("AuthProvider: Erro de FirebaseAuth ao atualizar perfil: ${e.code}");
      if (e.code == 'requires-recent-login') {
         throw Exception('Esta operação requer login recente. Por favor, faça logout e login novamente.');
      }
      throw Exception('Erro ao atualizar perfil no Auth: ${e.message}');
    } catch (e, s) {
      _setLoading(false);
      debugPrint("AuthProvider: Erro inesperado ao atualizar perfil: $e\n$s");
      throw Exception('Ocorreu um erro inesperado ao atualizar seu perfil.');
    }
  }

  /// Chamado quando o estado de autenticação do Firebase muda.
  Future<void> _onAuthStateChanged(fb_auth.User? user) async {
    debugPrint("AuthProvider: _onAuthStateChanged. Novo utilizador Firebase: ${user?.uid}");
    _firebaseUser = user; // Atualiza utilizador do Auth

    if (user == null) {
      // Utilizador deslogou
      _currentUserData = null;
      // _isAuthenticated será false devido ao getter
      debugPrint("AuthProvider: Utilizador deslogado.");
    } else {
      // Utilizador logou ou já estava logado, busca dados no Firestore
      try {
        debugPrint("AuthProvider: Utilizador ${user.uid} logado. Buscando dados Firestore...");
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userDataMap = userDoc.data() as Map<String, dynamic>;
          userDataMap['id'] = user.uid; // Garante ID correto
          _currentUserData = User.fromJson(userDataMap);
          debugPrint("AuthProvider: Dados Firestore carregados para ${_currentUserData?.name}");
        } else {
          debugPrint("AuthProvider: ERRO! Utilizador ${user.uid} autenticado mas sem dados no Firestore. Forçando logout.");
          await logout(); // Força logout para evitar estado inconsistente
          return; // Sai após logout
        }
      } catch (e, s) {
        debugPrint("AuthProvider: Erro ao buscar dados Firestore para ${user.uid}: $e");
        debugPrint("Stacktrace: $s");
        await logout(); // Força logout em caso de erro
        return; // Sai após logout
      }
    }

    // Se estava em loading, marca como concluído
    if (_isLoading) {
       _isLoading = false;
    }
    notifyListeners(); // Notifica a UI sobre a mudança de estado
  }

  /// Lida com erros no stream de autenticação ou erros gerais de carregamento.
  void _handleAuthError() {
     _firebaseUser = null;
     _currentUserData = null;
     _isLoading = false;
     notifyListeners();
  }

  /// Registra um novo utilizador com email e senha.
  Future<void> registerWithEmailAndPassword({
    required BuildContext context, // Necessário para ler RestaurantData
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? restaurantName,
    String? restaurantDescription,
  }) async {
    if (_isLoading) return;
    _setLoading(true); // Usa helper para definir loading e notificar

    try {
      // 1. Cria utilizador no Firebase Auth
      debugPrint("AuthProvider: Criando utilizador Auth para $email...");
      fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final fb_auth.User firebaseUser = userCredential.user!;
      debugPrint("AuthProvider: Utilizador Auth ${firebaseUser.uid} criado.");

      // 2. Cria objeto User local
      final newUser = User(
        id: firebaseUser.uid, // Usa UID real
        name: name.trim(),
        email: firebaseUser.email!,
        role: role,
      );

      // 3. Salva dados no Firestore
      debugPrint("AuthProvider: Salvando dados Firestore para ${newUser.id}...");
      await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());

      // 4. Se for restaurante, cria no Firestore via RestaurantData
      if (role == UserRole.restaurant) {
        debugPrint("AuthProvider: Registrando dados do restaurante...");
        final newRestaurant = Restaurant(
          id: newUser.id,
          imagePath: '',
          name: restaurantName?.trim() ?? 'Restaurante de ${newUser.name}',
          description: restaurantDescription?.trim() ?? 'Descrição Padrão',
          stars: 0.0, distance: 0, categories: [], dishes: [],
        );
        // Usa try-catch para a chamada ao outro provider
        try {
           // Lê o provider ANTES do await (embora read seja geralmente seguro)
           final restaurantDataProvider = context.read<RestaurantData>();
           await restaurantDataProvider.addRestaurant(newRestaurant);
           debugPrint("AuthProvider: Restaurante ${newRestaurant.name} adicionado via RestaurantData.");
        } catch (e) {
           debugPrint("AuthProvider: ERRO ao adicionar restaurante via RestaurantData: $e. Continuando registo do utilizador.");
           // Considerar se deve desfazer a criação do utilizador Auth/Firestore aqui
        }
      }

      // O listener _onAuthStateChanged tratará a atualização do estado interno.
      debugPrint("AuthProvider: Registo completo para ${newUser.email}.");
      // Não precisa chamar setLoading(false) ou notifyListeners aqui, _onAuthStateChanged fará isso.

    } on fb_auth.FirebaseAuthException catch (e) {
      _setLoading(false); // Para loading em caso de erro
      debugPrint("AuthProvider: Erro FirebaseAuth no registo: ${e.code}");
      _rethrowFirebaseAuthException(e, "registo"); // Lança exceção tratada
    } catch (e, s) {
      _setLoading(false); // Para loading
      debugPrint("AuthProvider: Erro inesperado no registo: $e\n$s");
      throw Exception('Ocorreu um erro inesperado durante o registo.');
    }
  }


  /// Autentica um utilizador com email e senha.
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    if (_isLoading) return;
    _setLoading(true);

    try {
      debugPrint("AuthProvider: Tentando login com Firebase Auth para $email...");
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Sucesso! O listener _onAuthStateChanged será chamado.
      debugPrint("AuthProvider: Chamada a signInWithEmailAndPassword bem-sucedida.");
      // _isLoading será definido como false pelo _onAuthStateChanged.

    } on fb_auth.FirebaseAuthException catch (e) {
      _setLoading(false); // Para loading em caso de erro
      debugPrint("AuthProvider: Erro FirebaseAuth no login: ${e.code}");
      _rethrowFirebaseAuthException(e, "login"); // Lança exceção tratada
    } catch (e, s) {
      _setLoading(false); // Para loading
      debugPrint("AuthProvider: Erro inesperado no login: $e\n$s");
      throw Exception('Ocorreu um erro inesperado durante o login.');
    }
  }

  /// Desloga o utilizador atual.
  Future<void> logout() async {
    debugPrint("AuthProvider: Método logout() chamado.");
    // Permite chamar mesmo se estiver carregando, para forçar logout em caso de erro
    // if (_isLoading && !isAuthenticated) return;

    // Define isLoading ANTES da chamada async, mas notifica depois se necessário
    bool wasLoading = _isLoading;
    _isLoading = true;
    if (!wasLoading) notifyListeners(); // Notifica só se não estava em loading

    try {
      await _firebaseAuth.signOut();
      // O listener _onAuthStateChanged tratará a limpeza do estado.
      debugPrint("AuthProvider: Firebase signOut() chamado com sucesso.");
    } catch (e, s) {
       debugPrint("AuthProvider: Erro durante o signOut do Firebase: $e\n$s");
       // Força a limpeza do estado local mesmo se signOut falhar
       _handleAuthError();
    }
    // _isLoading será definido como false pelo _onAuthStateChanged.
  }

  /// Atualiza a senha do utilizador logado.
  Future<void> changePassword(String currentPassword, String newPassword) async {
     if (!isAuthenticated || _firebaseUser == null) {
        throw Exception("Utilizador não está autenticado para mudar a senha.");
     }
     if (_isLoading) return;
     _setLoading(true);

     try {
        // 1. Cria a credencial
        fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
           email: _firebaseUser!.email!,
           password: currentPassword,
        );
        // 2. Reautentica
        debugPrint("AuthProvider: Reautenticando utilizador...");
        await _firebaseUser!.reauthenticateWithCredential(credential);
        debugPrint("AuthProvider: Reautenticação OK.");
        // 3. Atualiza a senha
        debugPrint("AuthProvider: Atualizando senha...");
        await _firebaseUser!.updatePassword(newPassword);
        debugPrint("AuthProvider: Senha atualizada com sucesso.");
        _setLoading(false); // Sucesso, para loading

     } on fb_auth.FirebaseAuthException catch (e) {
        _setLoading(false); // Para loading em caso de erro
        debugPrint("AuthProvider: Erro FirebaseAuth ao mudar senha: ${e.code}");
        _rethrowFirebaseAuthException(e, "alteração de senha"); // Lança exceção tratada
     } catch (e, s) {
        _setLoading(false); // Para loading
        debugPrint("AuthProvider: Erro inesperado ao mudar senha: $e\n$s");
        throw Exception('Ocorreu um erro inesperado ao alterar a senha.');
     }
  }

  // --- Helpers Internos ---

  /// Define o estado de loading e notifica os listeners.
  void _setLoading(bool value) {
     if (_isLoading != value) {
        _isLoading = value;
        notifyListeners();
     }
  }

  /// Converte FirebaseAuthException em Exception com mensagem mais amigável.
  void _rethrowFirebaseAuthException(fb_auth.FirebaseAuthException e, String operation) {
     String message = 'Erro na operação de $operation: ${e.message}'; // Mensagem padrão
     if (e.code == 'weak-password') {
        message = 'A senha fornecida é muito fraca.';
     } else if (e.code == 'email-already-in-use') {
        message = 'Este e-mail já está em uso por outra conta.';
     } else if (e.code == 'invalid-email') {
         message = 'O formato do e-mail é inválido.';
     } else if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'E-mail ou senha inválidos.';
     } else if (e.code == 'user-disabled') {
         message = 'Esta conta de utilizador foi desabilitada.';
     } else if (e.code == 'requires-recent-login') {
         message = 'Esta operação requer login recente. Por favor, faça logout e login novamente.';
     }
     throw Exception(message);
  }

}