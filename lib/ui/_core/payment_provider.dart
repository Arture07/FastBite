// lib/ui/_core/payment_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import 'package:myapp/ui/_core/auth_provider.dart'; // Importar AuthProvider

// --- Enums e Classe PaymentCard ---
enum CardType { credit, debit }
enum CardBrand { visa, mastercard, elo, amex, hipercard, other }

class PaymentCard {
  final String id; // ID do documento Firestore
  final String name; // Apelido/Nome no cartão
  final String last4Digits; // Últimos 4 dígitos (SIMULAÇÃO)
  final CardType cardType; // Crédito ou Débito
  final CardBrand brand; // Bandeira (SIMULAÇÃO)

  PaymentCard({
    required this.id,
    required this.name,
    required this.last4Digits,
    required this.cardType,
    required this.brand,
  });

  // Converte para JSON (para salvar no Firestore)
  // Não inclui o ID, pois ele será o ID do documento
  Map<String, dynamic> toJson() => {
    'name': name,
    'last4Digits': last4Digits,
    'cardType': cardType.name, // Salva enum como string (ex: 'credit')
    'brand': brand.name,       // Salva enum como string (ex: 'visa')
  };

  // Cria a partir do JSON (lido do Firestore)
  // Recebe o ID do documento como parâmetro separado
  factory PaymentCard.fromJson(String id, Map<String, dynamic> json) {
     // Converte as strings salvas de volta para os enums correspondentes
     CardType type = CardType.values.firstWhere(
        (e) => e.name == json['cardType'],
        orElse: () => CardType.credit, // Padrão se inválido/ausente
     );
     CardBrand brand = CardBrand.values.firstWhere(
        (e) => e.name == json['brand'],
        orElse: () => CardBrand.other, // Padrão se inválido/ausente
     );

     return PaymentCard(
        id: id, // Usa o ID do documento Firestore
        name: json['name'] ?? 'Cartão Desconhecido',
        last4Digits: json['last4Digits'] ?? '****',
        cardType: type,
        brand: brand,
     );
  }

  // Getter para nome da bandeira (inalterado)
  String get brandName {
    switch (brand) {
      case CardBrand.visa: return "Visa";
      case CardBrand.mastercard: return "Mastercard";
      case CardBrand.elo: return "Elo";
      case CardBrand.amex: return "American Express";
      case CardBrand.hipercard: return "Hipercard";
      default: return "Outro";
    }
  }

  // Método copyWith (inalterado, útil para edição)
  PaymentCard copyWith({
    String? id,
    String? name,
    String? last4Digits,
    CardType? cardType,
    CardBrand? brand,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      name: name ?? this.name,
      last4Digits: last4Digits ?? this.last4Digits,
      cardType: cardType ?? this.cardType,
      brand: brand ?? this.brand,
    );
  }

  // Overrides de igualdade e hashcode são importantes se usar em Sets/Maps
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentCard &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
// --- Fim Enums e Classe ---


/// Gerencia os métodos de pagamento salvos do utilizador, interagindo com o Firestore.
/// ATENÇÃO: Este provider é SIMPLIFICADO e NÃO lida com dados reais de cartão de forma segura.
/// Use gateways de pagamento (Stripe, Mercado Pago, etc.) para produção.
class PaymentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider _authProvider; // Recebe AuthProvider

  List<PaymentCard> _savedCards = []; // Lista local de cartões carregados
  String? _selectedCardId;      // ID do cartão selecionado para checkout
  bool _isLoaded = false;           // Flag de controle de carregamento
  String? _currentUserId;          // Guarda o ID do utilizador atual

  // Construtor 
  PaymentProvider(this._authProvider) {
    debugPrint("PaymentProvider (Firestore): Inicializando...");
    _authProvider.addListener(_handleAuthChange);
    _handleAuthChange(); // Carrega dados iniciais se já logado
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChange);
    debugPrint("PaymentProvider (Firestore): Disposed.");
    super.dispose();
  }

  // Reage a mudanças no login/logout
  void _handleAuthChange() {
    final newUserId = _authProvider.currentUser?.id;
    if (_currentUserId != newUserId) {
      debugPrint("PaymentProvider (Firestore): Auth state changed. Old User: $_currentUserId, New User: $newUserId");
      _currentUserId = newUserId;
      _savedCards = []; // Limpa lista antiga
      _selectedCardId = null; // Limpa seleção
      _isLoaded = false; // Marca como não carregado
      notifyListeners(); // Notifica UI sobre limpeza
      if (_currentUserId != null) {
        loadCardsFromFirestore(); // Carrega cartões do novo utilizador
      }
    }
  }

  // Getters públicos
  List<PaymentCard> get savedCards => List.unmodifiable(_savedCards);
  PaymentCard? get selectedCard {
    if (_selectedCardId == null) return null;
    try {
      return _savedCards.firstWhere((card) => card.id == _selectedCardId);
    } catch (e) {
      _selectedCardId = null;
      return null;
    }
  }
  bool get isLoaded => _isLoaded;

  // --- Selecionar Cartão (Lógica inalterada) ---
  void selectCard(String? cardId) {
    if (_selectedCardId != cardId) {
      _selectedCardId = cardId;
      notifyListeners();
    }
  }

  // --- MÉTODOS CRUD COM FIRESTORE ---

  /// Retorna a referência para a subcoleção 'paymentMethods' do utilizador atual.
  CollectionReference? _userCardsCollection() {
    if (_currentUserId == null) return null;
    return _firestore.collection('users').doc(_currentUserId!).collection('paymentMethods');
  }

  /// Carrega os cartões salvos do Firestore para o utilizador atual.
  Future<void> loadCardsFromFirestore() async {
    if (_currentUserId == null || _isLoaded) return;
    final collectionRef = _userCardsCollection();
    if (collectionRef == null) {
       _isLoaded = true;
       notifyListeners();
       return;
    }

    debugPrint("PaymentProvider (Firestore): Carregando cartões para utilizador $_currentUserId...");
    _isLoaded = true; // Assume carregado
    // notifyListeners(); // Opcional: notificar início do loading

    try {
      QuerySnapshot snapshot = await collectionRef.get();
      // Mapeia os documentos para objetos PaymentCard
      _savedCards = snapshot.docs.map((doc) {
        // Passa o ID do documento e os dados para fromJson
        return PaymentCard.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      debugPrint("PaymentProvider (Firestore): Cartões carregados (${_savedCards.length} itens).");
    } catch (e, s) {
      debugPrint("PaymentProvider (Firestore): Erro ao carregar cartões: $e");
      debugPrint("Stacktrace: $s");
      _savedCards = [];
    } finally {
      notifyListeners(); // Notifica que o carregamento terminou
    }
  }

  /// Adiciona um novo cartão (simplificado) no Firestore.
  Future<void> addCard(PaymentCard newCard) async {
    final collectionRef = _userCardsCollection();
    if (collectionRef == null) {
      debugPrint("PaymentProvider (Firestore): Erro ao adicionar - Utilizador não logado.");
      throw Exception("Utilizador não está logado.");
    }
    try {
      // Adiciona ao Firestore (gera ID automaticamente)
      // Passamos o JSON sem o ID, pois ele será o ID do documento.
      DocumentReference docRef = await collectionRef.add(newCard.toJson());

      // Atualiza o objeto local com o ID real e adiciona à lista
      PaymentCard cardWithId = newCard.copyWith(id: docRef.id);
      _savedCards.add(cardWithId);

      debugPrint("PaymentProvider (Firestore): Cartão ${docRef.id} adicionado.");
      notifyListeners();
    } catch (e) {
      debugPrint("PaymentProvider (Firestore): Erro ao adicionar cartão: $e");
      throw Exception("Falha ao adicionar cartão.");
    }
  }

  /// Remove um cartão do Firestore.
  Future<void> removeCard(String cardId) async {
    final collectionRef = _userCardsCollection();
    if (collectionRef == null) return;
    try {
      await collectionRef.doc(cardId).delete(); // Deleta no Firestore
      // Remove da lista local
      final index = _savedCards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _savedCards.removeAt(index);
        if (_selectedCardId == cardId) {
          _selectedCardId = null; // Limpa seleção se necessário
        }
        debugPrint("PaymentProvider (Firestore): Cartão $cardId removido.");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("PaymentProvider (Firestore): Erro ao remover cartão $cardId: $e");
      throw Exception("Falha ao remover cartão.");
    }
  }

  /// Atualiza um cartão existente no Firestore.
  Future<void> updateCard(PaymentCard updatedCard) async {
    final collectionRef = _userCardsCollection();
    if (collectionRef == null) return;
    try {
      // Atualiza no Firestore usando o ID do cartão
      await collectionRef.doc(updatedCard.id).update(updatedCard.toJson());

      // Atualiza na lista local
      final index = _savedCards.indexWhere((card) => card.id == updatedCard.id);
      if (index != -1) {
        _savedCards[index] = updatedCard;
        debugPrint("PaymentProvider (Firestore): Cartão ${updatedCard.id} atualizado.");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("PaymentProvider (Firestore): Erro ao atualizar cartão ${updatedCard.id}: $e");
      throw Exception("Falha ao atualizar cartão.");
    }
  }
}
