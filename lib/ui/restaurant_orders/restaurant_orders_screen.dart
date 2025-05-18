// lib/ui/restaurant_orders/restaurant_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/order.dart' as my_order;
import 'package:myapp/model/user.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/ui/_core/order_provider.dart';
import 'package:myapp/ui/orders/order_detail_screen.dart';
import 'package:provider/provider.dart';

class RestaurantOrdersScreen extends StatefulWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  State<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends State<RestaurantOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated &&
          authProvider.currentUser?.role == UserRole.restaurant && // <<< USA UserRole DIRETAMENTE
          !orderProvider.isLoading &&
          (orderProvider.loadedOrders.isEmpty || orderProvider.getOrdersForRestaurant(authProvider.currentUser!.id).isEmpty || orderProvider.loadedOrders.first.userId != authProvider.currentUser!.id )
          ) {
        debugPrint("RestaurantOrdersScreen: Solicitando carregamento de pedidos no initState.");
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
      return {'text': 'Novo Pedido', 'color': Colors.orange[700], 'icon': Icons.notifications_active_outlined};
    }
  }

  Future<void> _updateOrderStatus(BuildContext context, my_order.Order order, my_order.OrderStatus newStatus) async {
    final orderProvider = context.read<OrderProvider>();
    bool success = await orderProvider.updateOrderStatus(order.id, newStatus);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status do pedido #${order.id.substring(0, 6)} atualizado para "${_getStatusInfo(newStatus)['text']}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar status do pedido.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<bool?> _showCancelConfirmationDialog(BuildContext context, my_order.Order order) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Cancelamento'),
          content: Text('Tem certeza que deseja cancelar o pedido #${order.id.substring(0, 6)}?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Manter Pedido'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancelar Pedido'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM HH:mm', 'pt_BR');
    final theme = Theme.of(context);

    final orderProvider = context.watch<OrderProvider>();
    List<my_order.Order> restaurantOrders = List.from(orderProvider.loadedOrders);
    final bool isLoading = orderProvider.isLoading;

    // Ordenação local para a tela do restaurante
    restaurantOrders.sort((a, b) {
      int statusValue(my_order.OrderStatus status) {
        switch (status) {
          case my_order.OrderStatus.pending: return 0;
          case my_order.OrderStatus.processing: return 1;
          case my_order.OrderStatus.onTheWay: return 2;
          case my_order.OrderStatus.delivered: return 3;
          case my_order.OrderStatus.cancelled: return 4;
          }
      }
      int compareStatus = statusValue(a.status).compareTo(statusValue(b.status));
      if (compareStatus != 0) return compareStatus;
      return b.date.compareTo(a.date); // Mais recentes primeiro para mesmo status
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedidos Recebidos"),
        elevation: 1.0,
      ),
      body: isLoading && restaurantOrders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : restaurantOrders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 70, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Nenhum pedido recebido ainda.", style: TextStyle(fontSize: 17, color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await context.read<OrderProvider>().loadOrdersForCurrentUser();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: restaurantOrders.length,
                    itemBuilder: (context, index) {
                      final order = restaurantOrders[index];
                      final statusInfo = _getStatusInfo(order.status);
                      List<Widget> actionButtons = [];

                      // Define botões de ação baseados no status
                      if (order.status == my_order.OrderStatus.pending) {
                        actionButtons.addAll([
                          ElevatedButton.icon(
                            icon: const Icon(Icons.restaurant_menu_outlined, size: 16),
                            label: const Text("Aceitar"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11),
                              backgroundColor: Colors.green[700], foregroundColor: Colors.white,
                            ),
                            onPressed: () => _updateOrderStatus(context, order, my_order.OrderStatus.processing),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: Icon(Icons.cancel_outlined, size: 16, color: theme.colorScheme.error),
                            label: Text("Cancelar", style: TextStyle(fontSize: 11, color: theme.colorScheme.error)),
                            onPressed: () async {
                               bool? confirmCancel = await _showCancelConfirmationDialog(context, order);
                               if (confirmCancel == true) {
                                  _updateOrderStatus(context, order, my_order.OrderStatus.cancelled);
                               }
                            },
                          )
                        ]);
                      } else if (order.status == my_order.OrderStatus.processing) {
                        actionButtons.addAll([
                          ElevatedButton.icon(
                            icon: const Icon(Icons.local_shipping_outlined, size: 16),
                            label: const Text("A Caminho"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal[700], foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () => _updateOrderStatus(context, order, my_order.OrderStatus.onTheWay),
                          ),
                          // Opcional: Botão Cancelar também para "Em Preparo"
                           const SizedBox(width: 8),
                           TextButton.icon(
                            icon: Icon(Icons.cancel_outlined, size: 16, color: theme.colorScheme.error),
                            label: Text("Cancelar", style: TextStyle(fontSize: 11, color: theme.colorScheme.error)),
                            onPressed: () async {
                               bool? confirmCancel = await _showCancelConfirmationDialog(context, order);
                               if (confirmCancel == true) {
                                  _updateOrderStatus(context, order, my_order.OrderStatus.cancelled);
                               }
                            },
                          )
                        ]);
                      } else if (order.status == my_order.OrderStatus.onTheWay) {
                         actionButtons.add(
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text("Entregue"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () => _updateOrderStatus(context, order, my_order.OrderStatus.delivered),
                          )
                        );
                      }

                      return Card(
                        key: ValueKey(order.id),
                        clipBehavior: Clip.antiAlias,
                        elevation: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailScreen(order: order))),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                     Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Pedido #${order.id.substring(0, 6)}...",
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.primary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(dateFormat.format(order.date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                        ],
                                      ),
                                      Chip(
                                        avatar: Icon(statusInfo['icon'], color: Colors.white, size: 14),
                                        label: Text(statusInfo['text'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                                        backgroundColor: statusInfo['color'] as Color?,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        labelPadding: const EdgeInsets.only(left: 4),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ]
                                ),
                                const Divider(height: 16, thickness: 0.5),
                                Text(
                                  order.items.map((item) => "${item.quantity}x ${item.dishName}").join(' • '),
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Total: ${currencyFormat.format(order.totalAmount / 100.0)}", // Divide por 100
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    if (actionButtons.isNotEmpty)
                                       Row(mainAxisSize: MainAxisSize.min, children: actionButtons)
                                    else if (order.status == my_order.OrderStatus.delivered || order.status == my_order.OrderStatus.cancelled)
                                       Text(order.status == my_order.OrderStatus.delivered ? 'Finalizado' : 'Cancelado', style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                  ),
                ),
    );
  }
}