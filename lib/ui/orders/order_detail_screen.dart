import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatação
import 'package:myapp/model/order.dart'; // Modelo Order e OrderItem
// Importar para buscar nome do restaurante (se necessário)
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/model/order.dart' as my_order_model;
import 'package:provider/provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order; // Recebe o pedido completo

  const OrderDetailScreen({super.key, required this.order});

  // Helper para obter informações visuais do status (igual ao de OrderHistoryScreen)
   Map<String, dynamic> _getStatusInfo(my_order_model.OrderStatus status) { // Usa prefixo
     switch (status) {
        case my_order_model.OrderStatus.delivered:
          return {'text': 'Entregue', 'color': Colors.green[700], 'icon': Icons.check_circle_outline};
        case my_order_model.OrderStatus.onTheWay: // <<< CASO ADICIONADO
          return {'text': 'A Caminho', 'color': Colors.teal[700], 'icon': Icons.local_shipping_outlined};
        case my_order_model.OrderStatus.processing:
          return {'text': 'Em Preparo', 'color': Colors.blue[700], 'icon': Icons.restaurant_menu_outlined};
        case my_order_model.OrderStatus.cancelled:
          return {'text': 'Cancelado', 'color': Colors.red[700], 'icon': Icons.cancel_outlined};
        case my_order_model.OrderStatus.pending:
        // default não é mais necessário se todos os casos estão cobertos
          return {'text': 'Pendente', 'color': Colors.orange[700], 'icon': Icons.hourglass_empty_outlined};
     }
  }

  @override
  Widget build(BuildContext context) {
    // Formatadores
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR'); // Formato mais completo
    final statusInfo = _getStatusInfo(order.status);

    // Busca o nome do restaurante (opcional, pode já estar no pedido se modificar o modelo)
    final restaurantData = context.read<RestaurantData>(); // Usa read pois só precisa uma vez
    String restaurantName = 'Restaurante Desconhecido';
    try {
       restaurantName = restaurantData.listRestaurant
           .firstWhere((r) => r.id == order.restaurantId)
           .name;
    } catch (e) { /* Ignora se não achar */ }


    return Scaffold(
      appBar: AppBar(
        title: Text("Detalhes Pedido #${order.id.substring(0, 6)}"), // ID curto no título
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Informações Gerais ---
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildDetailRow(context, Icons.storefront_outlined, "Restaurante:", restaurantName),
                     _buildDetailRow(context, Icons.calendar_today_outlined, "Data:", dateFormat.format(order.date)),
                     _buildDetailRow(context, Icons.receipt_outlined, "Pedido ID:", "#${order.id.substring(0,10)}..."), // ID um pouco maior
                     Row( // Linha para Status com Chip
                       children: [
                         Icon(Icons.moped_outlined, color: Theme.of(context).iconTheme.color?.withOpacity(0.6), size: 18),
                         const SizedBox(width: 12),
                         const Text("Status:", style: TextStyle(fontWeight: FontWeight.w500)),
                         const Spacer(), // Empurra o chip para a direita
                         Chip(
                            avatar: Icon(statusInfo['icon'], color: Colors.white, size: 14),
                            label: Text(statusInfo['text'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                            backgroundColor: statusInfo['color'],
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            labelPadding: const EdgeInsets.only(left: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                         ),
                       ],
                     ),
                     // TODO: Adicionar informações de Endereço e Pagamento se estiverem no modelo Order
                     // _buildDetailRow(context, Icons.location_on_outlined, "Entrega:", order.deliveryAddress),
                     // _buildDetailRow(context, Icons.credit_card_outlined, "Pagamento:", order.paymentMethodInfo),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Itens do Pedido ---
            Text("Itens", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true, // Essencial dentro de SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Desabilita scroll interno
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  // Poderia adicionar imagem do prato aqui se buscar pelo dishId
                  // leading: ClipRRect(...),
                  title: Text("${item.quantity}x ${item.dishName}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    currencyFormat.format(item.quantity * item.pricePerItem/100), // Calcula total do item
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  // Subtitle pode mostrar preço unitário
                  // subtitle: Text(currencyFormat.format(item.pricePerItem) + " /unid."),
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.3),
            ),
            const Divider(height: 24, thickness: 1),

            // --- Resumo Financeiro ---
             Text("Resumo do Pagamento", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             _buildTotalRow("Subtotal dos Itens:", currencyFormat.format(order.subtotal/100)),
             _buildTotalRow("Taxa de Entrega:", currencyFormat.format(order.deliveryFee)),
             // Adicionar linha de Juros se aplicável e se estiver no modelo Order
             // if (order.interest > 0) _buildTotalRow("Juros:", currencyFormat.format(order.interest)),
             const Divider(height: 16, thickness: 0.5),
             _buildTotalRow("Valor Total:", currencyFormat.format(order.totalAmount/100), isTotal: true),

             const SizedBox(height: 32),
             // TODO: Adicionar botões de ação se relevante (ex: Repetir Pedido, Ajuda com Pedido)
             // ElevatedButton(onPressed: (){}, child: Text("Repetir Pedido")),
          ],
        ),
      ),
    );
  }

  // Helper para linhas de detalhe com ícone
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).iconTheme.color?.withOpacity(0.6), size: 18),
          const SizedBox(width: 12),
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded( // Permite que o valor quebre linha se necessário
             child: Text(value, style: TextStyle(color: Colors.grey[300]), textAlign: TextAlign.right)
          ),
        ],
      ),
    );
  }

   // Helper para linhas do resumo financeiro (similar ao do Checkout)
  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
     return Padding(
       padding: EdgeInsets.symmetric(vertical: isTotal ? 5.0 : 2.0),
       child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text( label, style: TextStyle( fontSize: isTotal ? 16 : 14, color: isTotal ? null : Colors.grey[400], fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, ), ),
            Text( value, style: TextStyle( fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, ), ),
          ],
       ),
     );
  }
}