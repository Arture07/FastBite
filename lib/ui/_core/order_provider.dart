// lib/ui/_core/order_provider.dart
import 'package:flutter/foundation.dart';
import 'package:myapp/model/order.dart' as my_order_model; // Mantém o prefixo para Order e OrderStatus
import 'package:myapp/model/user.dart'; // <<< IMPORTAÇÃO NECESSÁRIA PARA UserRole
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:collection/collection.dart'; // Para firstWhereOrNull

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider _authProvider;

  List<my_order_model.Order> _loadedOrders = [];
  bool _isLoading = false;
  String? _currentUserId;
  UserRole? _currentUserRole; // <<< USA UserRole DIRETAMENTE (do model/user.dart)

  OrderProvider(this._authProvider) {
    debugPrint("OrderProvider (Firestore): Inicializando...");
    _authProvider.addListener(_handleAuthChange);
    _handleAuthChange();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChange);
    debugPrint("OrderProvider (Firestore): Disposed.");
    super.dispose();
  }

  void _handleAuthChange() {
    final newUserId = _authProvider.currentUser?.id;
    final newRole = _authProvider.currentUser?.role; // currentUser.role já é do tipo UserRole

    if (_currentUserId != newUserId || _currentUserRole != newRole) {
      debugPrint("OrderProvider (Firestore): Auth state changed. Old User: $_currentUserId ($_currentUserRole), New User: $newUserId ($newRole)");
      _currentUserId = newUserId;
      _currentUserRole = newRole;
      _loadedOrders = [];
      _isLoading = false;
      notifyListeners();
      if (_currentUserId != null) {
        loadOrdersForCurrentUser();
      }
    }
  }

  List<my_order_model.Order> get loadedOrders => List.unmodifiable(_loadedOrders);
  bool get isLoading => _isLoading;

  Future<void> loadOrdersForCurrentUser() async {
    if (_currentUserId == null) {
      if (_loadedOrders.isNotEmpty || _isLoading) {
        _loadedOrders = [];
        _isLoading = false;
        notifyListeners();
      }
      return;
    }
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();
    debugPrint("OrderProvider (Firestore): Carregando pedidos para $_currentUserRole ID: $_currentUserId...");

    try {
      Query query;
      if (_currentUserRole == UserRole.client) { // <<< USA UserRole DIRETAMENTE
        query = _firestore.collection('orders')
                  .where('userId', isEqualTo: _currentUserId)
                  .orderBy('date', descending: true);
      } else if (_currentUserRole == UserRole.restaurant) { // <<< USA UserRole DIRETAMENTE
        query = _firestore.collection('orders')
                  .where('restaurantId', isEqualTo: _currentUserId)
                  .orderBy('date', descending: true);
      } else {
         _loadedOrders = [];
         _isLoading = false;
         notifyListeners();
         debugPrint("OrderProvider (Firestore): Papel de utilizador desconhecido. Nenhum pedido carregado.");
         return;
      }

      QuerySnapshot snapshot = await query.get();
      _loadedOrders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
        }
        if (data['items'] is List) {
          data['items'] = List<Map<String, dynamic>>.from(
            (data['items'] as List).map((item) => Map<String, dynamic>.from(item as Map))
          );
        } else { data['items'] = <Map<String, dynamic>>[]; }
         if (data['deliveryAddress'] is Map && data['deliveryAddress'] is! Map<String, dynamic>) {
            data['deliveryAddress'] = Map<String, dynamic>.from(data['deliveryAddress'] as Map);
         } else if (data['deliveryAddress'] is! Map) { data['deliveryAddress'] = <String, dynamic>{}; }
         if (data['paymentMethodInfo'] is Map && data['paymentMethodInfo'] is! Map<String, dynamic>) {
            data['paymentMethodInfo'] = Map<String, dynamic>.from(data['paymentMethodInfo'] as Map);
         } else if (data['paymentMethodInfo'] is! Map) { data['paymentMethodInfo'] = <String, dynamic>{}; }

        try {
           return my_order_model.Order.fromJson(data);
        } catch (e,s) {
           debugPrint("OrderProvider (Firestore): ERRO AO CONVERTER DOCUMENTO DE PEDIDO ${doc.id} para Order: $e\n$s");
           debugPrint("Dados do documento com erro: $data");
           return null;
        }
      }).whereType<my_order_model.Order>().toList();

      debugPrint("OrderProvider (Firestore): Pedidos carregados (${_loadedOrders.length} itens).");
    } catch (e, s) {
       debugPrint("OrderProvider (Firestore): Erro ao carregar pedidos: $e\n$s");
       _loadedOrders = [];
    } finally {
       _isLoading = false;
       notifyListeners();
    }
  }

  List<my_order_model.Order> getOrdersForRestaurant(String restaurantId) {
    if (_currentUserRole == UserRole.restaurant && _currentUserId == restaurantId) { // <<< USA UserRole DIRETAMENTE
      return _loadedOrders;
    }
    return [];
  }

  List<my_order_model.Order> getOrdersForUser(String userId) {
    if (_currentUserRole == UserRole.client && _currentUserId == userId) { // <<< USA UserRole DIRETAMENTE
      return _loadedOrders;
    }
    return [];
  }

  my_order_model.Order? getOrderById(String orderId) {
    return _loadedOrders.firstWhereOrNull((order) => order.id == orderId);
  }

  Future<void> placeOrder(my_order_model.Order newOrder) async {
    if (newOrder.userId.isEmpty) throw Exception("ID do utilizador ausente no pedido.");
    try {
      Map<String, dynamic> orderData = newOrder.toJson();
      DocumentReference docRef = await _firestore.collection('orders').add(orderData..remove('id'));
      my_order_model.Order orderWithId = newOrder.copyWith(id: docRef.id);
      _loadedOrders.insert(0, orderWithId);
      _loadedOrders.sort((a, b) => b.date.compareTo(a.date));
      debugPrint("OrderProvider (Firestore): Pedido ${docRef.id} adicionado.");
      notifyListeners();
    } catch (e, s) {
      debugPrint("OrderProvider (Firestore): Erro ao salvar pedido: $e\n$s");
      throw Exception("Falha ao registrar o pedido.");
    }
  }

  Future<bool> updateOrderStatus(String orderId, my_order_model.OrderStatus newStatus) async {
    if (_currentUserRole != UserRole.restaurant) { // <<< USA UserRole DIRETAMENTE
       debugPrint("OrderProvider (Firestore): Apenas restaurantes podem atualizar status de pedidos para $newStatus.");
       return false;
    }
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': newStatus.name});
      int index = _loadedOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _loadedOrders[index] = _loadedOrders[index].copyWith(status: newStatus);
        notifyListeners();
        debugPrint("OrderProvider (Firestore): Status do pedido $orderId atualizado para $newStatus.");
        return true;
      } else {
        debugPrint("OrderProvider (Firestore): Pedido $orderId não encontrado localmente após atualização. Recarregando...");
        await loadOrdersForCurrentUser();
        return false;
      }
    } catch (e, s) {
      debugPrint("OrderProvider (Firestore): Erro ao atualizar status do pedido $orderId: $e\n$s");
      return false;
    }
  }
}
