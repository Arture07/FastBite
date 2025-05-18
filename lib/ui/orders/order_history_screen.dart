// lib/ui/orders/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/order.dart' as my_order;
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/ui/_core/order_provider.dart';
import 'package:myapp/ui/orders/order_detail_screen.dart';
import 'package:provider/provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();
      final authProvider = context.read<AuthProvider>();
      // Carrega apenas se logado, não estiver carregando e a lista estiver vazia (ou se o user mudou)
      if (authProvider.isAuthenticated && 
          authProvider.currentUser?.id != null && 
          !orderProvider.isLoading && 
          (orderProvider.loadedOrders.isEmpty || orderProvider.getOrdersForUser(authProvider.currentUser!.id).isEmpty || orderProvider.loadedOrders.first.userId != authProvider.currentUser!.id )
      ) {
        debugPrint("OrderHistoryScreen: Solicitando carregamento de pedidos no initState para utilizador ${authProvider.currentUser?.id}.");
        orderProvider.loadOrdersForCurrentUser();
      }
    });
  }

  Map<String, dynamic> _getStatusInfo(my_order.OrderStatus status) {
    switch (status) {
      case my_order.OrderStatus.delivered:
        return {'text': 'Entregue', 'color': Colors.green[700], 'icon': Icons.check_circle_outline};
      case my_order.OrderStatus.onTheWay:
        return {'text': 'A Caminho', 'color': Colors.teal[700], 'icon': Icons.local_shipping_outlined};
      case my_order.OrderStatus.processing:
        return {'text': 'Em Preparo', 'color': Colors.blue[700], 'icon': Icons.restaurant_menu_outlined};
      case my_order.OrderStatus.cancelled:
        return {'text': 'Cancelado', 'color': Colors.red[700], 'icon': Icons.cancel_outlined};
      case my_order.OrderStatus.pending:
      return {'text': 'Pendente', 'color': Colors.orange[700], 'icon': Icons.hourglass_empty_outlined};
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    final orderProvider = context.watch<OrderProvider>();
    // A lista já vem ordenada por data (do Firestore) do provider
    final List<my_order.Order> userOrders = orderProvider.loadedOrders;
    final bool isLoading = orderProvider.isLoading;

    // Usar 'read' para RestaurantData se a lista de restaurantes não muda frequentemente
    final restaurantData = context.read<RestaurantData>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Pedidos"),
        elevation: 1.0,
      ),
      body: isLoading && userOrders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : userOrders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Você ainda não fez nenhum pedido.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<OrderProvider>().loadOrdersForCurrentUser();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: userOrders.length,
                    itemBuilder: (context, index) {
                      final order = userOrders[index];
                      final statusInfo = _getStatusInfo(order.status);
                      String restaurantName = 'Restaurante Desconhecido';
                      try {
                        final foundRestaurant = restaurantData.listRestaurant.firstWhere(
                          (r) => r.id == order.restaurantId,
                        );
                        restaurantName = foundRestaurant.name;
                      } catch (e) {
                        debugPrint("OrderHistoryScreen: Restaurante ID ${order.restaurantId} não encontrado.");
                      }

                      return Card(
                        key: ValueKey(order.id), // Chave para otimizar rebuilds
                        clipBehavior: Clip.antiAlias,
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailScreen(order: order),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        restaurantName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      currencyFormat.format(order.totalAmount / 100.0), // Divide por 100
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateFormat.format(order.date),
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                const Divider(height: 16, thickness: 0.5),
                                Text(
                                  order.items.map((item) => "${item.quantity}x ${item.dishName}").join(' • '),
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Chip(
                                    avatar: Icon(statusInfo['icon'], color: Colors.white, size: 14),
                                    label: Text(
                                      statusInfo['text'],
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                    backgroundColor: statusInfo['color'] as Color?,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    labelPadding: const EdgeInsets.only(left: 4),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                  ),
                ),
    );
  }
}