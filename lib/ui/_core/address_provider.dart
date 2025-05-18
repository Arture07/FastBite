// lib/ui/_core/address_provider.dart
import 'package:flutter/foundation.dart';
import 'package:myapp/model/address.dart'; // Importar o modelo Address
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import 'package:myapp/ui/_core/auth_provider.dart'; // Importar AuthProvider para obter userId

/// Gerencia os endereços salvos do utilizador, interagindo com o Firestore.
class AddressProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider _authProvider; // Recebe AuthProvider via construtor

  List<Address> _savedAddresses = []; // Lista local de endereços carregados
  String? _selectedAddressId;      // ID do endereço selecionado para checkout
  bool _isLoaded = false;           // Flag de controle de carregamento
  String? _currentUserId;          // Guarda o ID do utilizador atual para referência

  // Construtor recebe AuthProvider para saber qual utilizador está logado
  AddressProvider(this._authProvider) {
    debugPrint("AddressProvider (Firestore): Inicializando...");
    // Ouve mudanças no AuthProvider para recarregar/limpar dados quando o utilizador mudar
    _authProvider.addListener(_handleAuthChange);
    // Carrega dados iniciais se já houver um utilizador logado ao iniciar o provider
    _handleAuthChange();
  }

  // Limpa o listener ao descartar o provider para evitar memory leaks
  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChange);
    debugPrint("AddressProvider (Firestore): Disposed.");
    super.dispose();
  }

  // Função chamada quando o estado de autenticação muda (login/logout)
  void _handleAuthChange() {
    final newUserId = _authProvider.currentUser?.id;
    // Verifica se o ID do utilizador realmente mudou
    if (_currentUserId != newUserId) {
      debugPrint("AddressProvider (Firestore): Estado de autenticação mudou. Utilizador antigo: $_currentUserId, Novo utilizador: $newUserId");
      _currentUserId = newUserId;
      _savedAddresses = []; // Limpa a lista de endereços do utilizador anterior
      _selectedAddressId = null; // Limpa a seleção
      _isLoaded = false; // Marca como não carregado para forçar recarga para o novo utilizador
      notifyListeners(); // Notifica a UI sobre a limpeza (ex: mostrar loading ou lista vazia)

      // Se um novo utilizador logou, carrega os endereços dele
      if (_currentUserId != null) {
        loadAddressesFromFirestore();
      }
    }
  }

  // --- Getters Públicos ---
  List<Address> get savedAddresses => List.unmodifiable(_savedAddresses);
  Address? get selectedAddress {
    if (_selectedAddressId == null) return null;
    try {
      // Tenta encontrar o endereço selecionado na lista local
      return _savedAddresses.firstWhere((addr) => addr.id == _selectedAddressId);
    } catch (e) {
      // Se não encontrar (ex: foi removido), deseleciona
      _selectedAddressId = null;
      return null;
    }
  }
  bool get isLoaded => _isLoaded;

  // --- Selecionar Endereço ---
  /// Define qual endereço está selecionado para o checkout.
  void selectAddress(String? addressId) {
    // Só notifica se a seleção realmente mudar
    if (_selectedAddressId != addressId) {
      _selectedAddressId = addressId;
      debugPrint("AddressProvider (Firestore): Endereço selecionado ID: $_selectedAddressId");
      notifyListeners();
    }
  }

  // --- Métodos CRUD com Firestore ---

  /// Retorna a referência para a subcoleção 'addresses' do utilizador atual.
  /// Retorna null se nenhum utilizador estiver logado.
  CollectionReference? _userAddressesCollection() {
    if (_currentUserId == null) {
      debugPrint("AddressProvider (Firestore): Tentativa de acesso à coleção sem utilizador logado.");
      return null;
    }
    return _firestore.collection('users').doc(_currentUserId!).collection('addresses');
  }

  /// Carrega os endereços do Firestore para o utilizador logado atualmente.
  Future<void> loadAddressesFromFirestore() async {
    // Só executa se houver um utilizador e os dados ainda não foram carregados
    if (_currentUserId == null || _isLoaded) return;

    final collectionRef = _userAddressesCollection();
    if (collectionRef == null) {
      _isLoaded = true; // Marca como carregado (sem dados) se não há coleção
      notifyListeners();
      return;
    }

    debugPrint("AddressProvider (Firestore): Carregando endereços para utilizador $_currentUserId...");
    _isLoaded = true; // Assume carregado para evitar múltiplas chamadas concorrentes
    // Notifica a UI que o carregamento iniciou (opcional, se a UI precisar mostrar loading)
    // notifyListeners();

    try {
      QuerySnapshot snapshot = await collectionRef.get();
      // Mapeia os documentos do Firestore para objetos Address
      _savedAddresses = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Garante que o ID do documento do Firestore é usado no objeto Address
        return Address.fromJson(data..['id'] = doc.id); // Adiciona/sobrescreve ID
      }).toList();
      debugPrint("AddressProvider (Firestore): Endereços carregados (${_savedAddresses.length} itens).");
    } catch (e, s) {
      debugPrint("AddressProvider (Firestore): Erro ao carregar endereços: $e");
      debugPrint("Stacktrace: $s");
      _savedAddresses = []; // Zera a lista em caso de erro
    } finally {
      // Notifica a UI que o carregamento terminou (com sucesso ou erro)
      // _isLoaded já está true
      notifyListeners();
    }
  }

  /// Adiciona um novo endereço no Firestore para o utilizador atual.
  Future<void> addAddress(Address newAddress) async {
    final collectionRef = _userAddressesCollection();
    if (collectionRef == null) {
      debugPrint("AddressProvider (Firestore): Erro ao adicionar - Utilizador não logado.");
      throw Exception("Utilizador não está logado."); // Lança exceção para a UI tratar
    }
    try {
      // Adiciona ao Firestore. O Firestore gera o ID do documento automaticamente.
      // Passamos os dados do endereço convertidos para JSON.
      // Removemos o 'id' do JSON se o modelo o incluir, pois o Firestore gerará um novo.
      DocumentReference docRef = await collectionRef.add(newAddress.toJson()..remove('id'));

      // Atualiza o objeto local com o ID real gerado pelo Firestore
      Address addressWithId = newAddress.copyWith(id: docRef.id);
      _savedAddresses.add(addressWithId); // Adiciona à lista local

      debugPrint("AddressProvider (Firestore): Endereço ${docRef.id} adicionado.");
      notifyListeners(); // Notifica a UI sobre a adição
    } catch (e) {
      debugPrint("AddressProvider (Firestore): Erro ao adicionar endereço: $e");
      throw Exception("Falha ao adicionar endereço."); // Lança exceção
    }
  }

  /// Remove um endereço do Firestore.
  Future<void> removeAddress(String addressId) async {
    final collectionRef = _userAddressesCollection();
    if (collectionRef == null) return; // Precisa de utilizador

    try {
      // Deleta o documento no Firestore usando o ID fornecido
      await collectionRef.doc(addressId).delete();

      // Remove da lista local
      final index = _savedAddresses.indexWhere((addr) => addr.id == addressId);
      if (index != -1) {
        _savedAddresses.removeAt(index);
        // Se o endereço removido era o selecionado, limpa a seleção
        if (_selectedAddressId == addressId) {
          _selectedAddressId = null;
        }
        debugPrint("AddressProvider (Firestore): Endereço $addressId removido.");
        notifyListeners(); // Notifica a UI
      }
    } catch (e) {
      debugPrint("AddressProvider (Firestore): Erro ao remover endereço $addressId: $e");
      throw Exception("Falha ao remover endereço."); // Lança exceção
    }
  }

  /// Atualiza um endereço existente no Firestore.
  Future<void> updateAddress(Address updatedAddress) async {
    final collectionRef = _userAddressesCollection();
    if (collectionRef == null) return; // Precisa de utilizador

    try {
      // Atualiza o documento no Firestore usando o ID do endereço
      // Passamos os dados convertidos para JSON. Removemos o 'id' do mapa.
      await collectionRef.doc(updatedAddress.id).update(updatedAddress.toJson()..remove('id'));

      // Atualiza na lista local
      final index = _savedAddresses.indexWhere((addr) => addr.id == updatedAddress.id);
      if (index != -1) {
        _savedAddresses[index] = updatedAddress;
        debugPrint("AddressProvider (Firestore): Endereço ${updatedAddress.id} atualizado.");
        notifyListeners(); // Notifica a UI
      }
    } catch (e) {
      debugPrint("AddressProvider (Firestore): Erro ao atualizar endereço ${updatedAddress.id}: $e");
      throw Exception("Falha ao atualizar endereço."); // Lança exceção
    }
  }
}
