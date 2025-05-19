// lib/ui/_core/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/model/restaurant.dart'; // Para o registo de restaurante
import 'package:myapp/data/restaurant_data.dart'; // Para o registo de restaurante
import 'package:provider/provider.dart'; // Para context.read em registerWithEmailAndPassword
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:myapp/services/image_upload_service.dart'; // Para deletar imagem do storage ao excluir conta

class AuthProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final ImageUploadService _imageUploadService = ImageUploadService();

  User? _currentUserData;
  fb_auth.User? _firebaseUser;
  bool _isLoading = true;
  StreamSubscription<fb_auth.User?>? _authStateSubscription;

  User? get currentUser => _currentUserData;
  fb_auth.User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    debugPrint("AuthProvider (FirebaseAuth): Inicializando e ouvindo estado...");
    _authStateSubscription = _firebaseAuth.authStateChanges().listen(_onAuthStateChanged, onError: (error) {
       debugPrint("AuthProvider: Erro no stream authStateChanges: $error");
       _handleAuthError();
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    debugPrint("AuthProvider (FirebaseAuth): Listener cancelado. Disposed.");
    super.dispose();
  }

  Future<void> _onAuthStateChanged(fb_auth.User? user) async {
    bool needsNotifyForLoading = _isLoading;
    _isLoading = true; 
    if (!needsNotifyForLoading &&_firebaseUser != user) notifyListeners();

    _firebaseUser = user;

    if (user == null) {
      _currentUserData = null;
      debugPrint("AuthProvider: Utilizador deslogado.");
    } else {
      try {
        debugPrint("AuthProvider: Utilizador ${user.uid} logado. Buscando dados Firestore...");
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userDataMap = userDoc.data() as Map<String, dynamic>;
          userDataMap['id'] = user.uid; 
          _currentUserData = User.fromJson(userDataMap);
          debugPrint("AuthProvider: Dados Firestore carregados para ${_currentUserData?.name}");
        } else {
          debugPrint("AuthProvider: ERRO! Utilizador ${user.uid} autenticado mas sem dados no Firestore. Forçando logout.");
          await _forceLogout();
          return;
        }
      } catch (e, s) {
        debugPrint("AuthProvider: Erro ao buscar dados Firestore para ${user.uid}: $e\n$s");
        await _forceLogout();
        return;
      }
    }
    _isLoading = false;
    notifyListeners();
     debugPrint("AuthProvider: _onAuthStateChanged concluído. Autenticado: $isAuthenticated, Utilizador: ${_currentUserData?.name}");
  }

  void _handleAuthError() {
     _firebaseUser = null;
     _currentUserData = null;
     if (_isLoading) {
        _isLoading = false;
        notifyListeners();
     } else if (isAuthenticated) { 
        notifyListeners();
     }
  }

  Future<void> _forceLogout() async {
     try { await _firebaseAuth.signOut(); } catch (_) {}
     _firebaseUser = null; _currentUserData = null;
  }

  Future<void> registerWithEmailAndPassword({
    required BuildContext context, required String name, required String email,
    required String password, required UserRole role,
    String? restaurantName, String? restaurantDescription,
  }) async {
    if (_isLoading) return;
    _setLoading(true);
    final restaurantDataProvider = context.read<RestaurantData>();

    try {
      fb_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final fb_auth.User firebaseUser = userCredential.user!;
      final newUser = User(
        id: firebaseUser.uid,
        name: name.trim(),
        email: firebaseUser.email!,
        role: role,
        userImagePath: null, 
      );
      await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());

      if (role == UserRole.restaurant) {
        final newRestaurant = Restaurant(
          id: newUser.id, imagePath: 'assets/restaurants/default.png', 
          name: restaurantName?.trim() ?? 'Restaurante de ${newUser.name}',
          description: restaurantDescription?.trim() ?? 'Descrição Padrão',
          stars: 0.0, distance: 0, categories: [],
          ratingCount: 0, ratingSum: 0.0, 
        );
        await restaurantDataProvider.addRestaurant(newRestaurant);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      _setLoading(false);
      _rethrowFirebaseAuthException(e, "registo");
    } catch (e, s) {
      _setLoading(false);
      debugPrint("AuthProvider: Erro inesperado no registo: $e\n$s");
      throw Exception('Ocorreu um erro inesperado durante o registo.');
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
    } on fb_auth.FirebaseAuthException catch (e) {
      _setLoading(false);
      _rethrowFirebaseAuthException(e, "login");
    } catch (e, s) {
      _setLoading(false);
      debugPrint("AuthProvider: Erro inesperado no login: $e\n$s");
      throw Exception('Ocorreu um erro inesperado durante o login.');
    }
  }

  Future<void> logout() async {
    debugPrint("AuthProvider: Método logout() chamado.");
    bool wasLoading = _isLoading;
    _isLoading = true;
    if (!wasLoading) notifyListeners();

    try {
      await _firebaseAuth.signOut();
    } catch (e, s) {
       debugPrint("AuthProvider: Erro durante o signOut do Firebase: $e\n$s");
       _handleAuthError();
    }
  }
  
  Future<void> updateUserProfile({
    required String name,
    String? photoURL, 
  }) async {
    if (!isAuthenticated || _firebaseUser == null) {
      throw Exception("Utilizador não está autenticado para atualizar o perfil.");
    }
    if (_isLoading) return;
    _setLoading(true);

    try {
      if (_firebaseUser!.displayName != name || (_firebaseUser!.photoURL != photoURL && photoURL != null)) {
        await _firebaseUser!.updateProfile(displayName: name, photoURL: photoURL);
        await _firebaseUser!.reload(); 
        _firebaseUser = _firebaseAuth.currentUser; 
        debugPrint("AuthProvider: Perfil no Firebase Auth atualizado (nome e/ou photoURL).");
      }

      Map<String, dynamic> dataToUpdate = {'name': name};
      if (photoURL != null) {
        dataToUpdate['userImagePath'] = photoURL; 
      } else if (_currentUserData?.userImagePath != null && photoURL == null) {
        dataToUpdate['userImagePath'] = null;
      }

      await _firestore.collection('users').doc(_firebaseUser!.uid).update(dataToUpdate);
      debugPrint("AuthProvider: Dados do utilizador no Firestore atualizados: $dataToUpdate");

      if (_currentUserData != null) {
        _currentUserData = _currentUserData!.copyWith(
          name: name,
          userImagePath: photoURL ?? _currentUserData!.userImagePath,
        );
      }
      _setLoading(false); 

    } on fb_auth.FirebaseAuthException catch (e) {
      _setLoading(false);
      debugPrint("AuthProvider: Erro de FirebaseAuth ao atualizar perfil: ${e.code} - ${e.message}");
      _rethrowFirebaseAuthException(e, "atualização de perfil no Auth");
    } catch (e, s) {
      _setLoading(false);
      debugPrint("AuthProvider: Erro GERAL ao atualizar perfil (Firestore ou outro): $e\n$s");
      throw Exception('Ocorreu um erro inesperado ao atualizar seu perfil.');
    }
  }

  // <<< MÉTODO PARA ALTERAR SENHA >>>
  Future<void> changePassword(String currentPassword, String newPassword) async {
     if (!isAuthenticated || _firebaseUser == null) {
        throw Exception("Utilizador não está autenticado para mudar a senha.");
     }
     if (_isLoading) return;
     _setLoading(true);

     try {
        fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
           email: _firebaseUser!.email!,
           password: currentPassword,
        );

        debugPrint("AuthProvider: Reautenticando utilizador para mudança de senha...");
        await _firebaseUser!.reauthenticateWithCredential(credential);
        debugPrint("AuthProvider: Reautenticação bem-sucedida.");

        debugPrint("AuthProvider: Atualizando senha no Firebase Auth...");
        await _firebaseUser!.updatePassword(newPassword);
        debugPrint("AuthProvider: Senha atualizada com sucesso no Firebase Auth.");
        _setLoading(false);

     } on fb_auth.FirebaseAuthException catch (e) {
        _setLoading(false);
        debugPrint("AuthProvider: Erro de FirebaseAuth ao mudar senha: ${e.code} - ${e.message}");
        _rethrowFirebaseAuthException(e, "alteração de senha");
     } catch (e, s) {
        _setLoading(false);
        debugPrint("AuthProvider: Erro inesperado ao mudar senha: $e\n$s");
        throw Exception('Ocorreu um erro inesperado ao alterar a senha.');
     }
  }

  Future<void> deleteUserAccount(String currentPassword) async {
     if (!isAuthenticated || _firebaseUser == null) {
      throw Exception("Utilizador não está autenticado para excluir a conta.");
    }
    _setLoading(true);
    try {
      fb_auth.AuthCredential credential = fb_auth.EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );
      await _firebaseUser!.reauthenticateWithCredential(credential);
      
      String? oldUserImagePath = _currentUserData?.userImagePath;
      String userIdToDelete = _firebaseUser!.uid; // Guarda antes de deletar _firebaseUser

      await _firebaseUser!.delete(); 
      // O listener _onAuthStateChanged limpará _firebaseUser e _currentUserData.

      // Tenta deletar a imagem do storage.
      // Idealmente, a exclusão de dados relacionados (Firestore, Storage) seria via Cloud Functions.
      if (oldUserImagePath != null && oldUserImagePath.startsWith('https://firebasestorage.googleapis.com')) {
        debugPrint("AuthProvider: Tentando deletar imagem do Storage ($oldUserImagePath) após exclusão de conta Auth para $userIdToDelete.");
        await _imageUploadService.deleteImageByUrl(oldUserImagePath);
      }
      // TODO: Adicionar chamada a uma Cloud Function para deletar dados do Firestore para userIdToDelete
      debugPrint("AuthProvider: Utilizador $userIdToDelete excluído do Firebase Authentication.");

    } on fb_auth.FirebaseAuthException catch (e) {
      _setLoading(false);
      _rethrowFirebaseAuthException(e, "exclusão de conta");
    } catch (e) {
      _setLoading(false);
      throw Exception("Erro inesperado ao excluir conta: ${e.toString()}");
    }
    // _isLoading será false via _onAuthStateChanged
  }

  void _setLoading(bool value) {
     if (_isLoading != value) {
        _isLoading = value;
        notifyListeners();
     }
  }

  void _rethrowFirebaseAuthException(fb_auth.FirebaseAuthException e, String operation) {
     String message = 'Erro na operação de $operation: ${e.message ?? e.code}';
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
