// lib/model/order.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Para o tipo Timestamp

// Enum para definir os possíveis status de um pedido
enum OrderStatus {
  pending,    // Pedido recebido, aguardando confirmação/preparo
  processing, // Pedido confirmado e em preparo
  onTheWay,   // <<< NOVO STATUS: Pedido a caminho da entrega
  delivered,  // Pedido entregue ao cliente
  cancelled   // Pedido cancelado (pelo cliente ou restaurante)
}

// Representa um item individual dentro de um pedido
class OrderItem {
  final String dishId;
  final String dishName;
  final int quantity;
  final int pricePerItem; // Em centavos (int)

  OrderItem({
    required this.dishId,
    required this.dishName,
    required this.quantity,
    required this.pricePerItem, // Espera um valor inteiro em centavos
  });

  Map<String, dynamic> toJson() => {
    'dishId': dishId,
    'dishName': dishName,
    'quantity': quantity,
    'pricePerItem': pricePerItem, // Salva como int (centavos)
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
     num priceNum = json['pricePerItem'] ?? 0;
     int priceInCents = 0;
     if (priceNum is int) {
        priceInCents = priceNum;
     } else if (priceNum is double) {
        priceInCents = (priceNum * 100).round();
     } else if (json['pricePerItem'] is String) {
        double? parsedDouble = double.tryParse((json['pricePerItem'] as String).replaceAll(',', '.'));
        if (parsedDouble != null) {
          priceInCents = (parsedDouble * 100).round();
        }
     }
     return OrderItem(
        dishId: json['dishId']?.toString() ?? '',
        dishName: json['dishName']?.toString() ?? 'Item Desconhecido',
        quantity: (json['quantity'] ?? 0).toInt(),
        pricePerItem: priceInCents,
     );
  }
   int get totalItemPrice => quantity * pricePerItem; // Retorna em centavos
}

// Representa um pedido completo
class Order {
  final String id;
  final String restaurantId;
  final String userId;
  final DateTime date;
  final List<OrderItem> items;
  final int deliveryFee;     // Em centavos (int)
  final int subtotal;        // Em centavos (int)
  final int totalAmount;     // Em centavos (int)
  final OrderStatus status;
  final Map<String, dynamic>? deliveryAddress;
  final Map<String, dynamic>? paymentMethodInfo;

  Order({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.date,
    required this.items,
    required this.deliveryFee,
    required this.subtotal,
    required this.totalAmount,
    required this.status,
    this.deliveryAddress,
    this.paymentMethodInfo,
  });

  Map<String, dynamic> toJson() => {
    'restaurantId': restaurantId,
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'items': items.map((item) => item.toJson()).toList(),
    'deliveryFee': deliveryFee,
    'subtotal': subtotal,
    'totalAmount': totalAmount,
    'status': status.name, // Salva o nome do enum
    'deliveryAddress': deliveryAddress,
    'paymentMethodInfo': paymentMethodInfo,
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsFromJson = json['items'] as List<dynamic>? ?? [];
    List<OrderItem> itemList = itemsFromJson.map((itemJson) {
      try {
        return OrderItem.fromJson(Map<String, dynamic>.from(itemJson as Map));
      } catch (e) {
        debugPrint("Erro ao decodificar OrderItem do Firestore: $e. Item: $itemJson");
        return null;
      }
    }).whereType<OrderItem>().toList();

    OrderStatus statusFromJson = OrderStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => OrderStatus.pending,
    );

    DateTime dateFromJson = DateTime.now();
    if (json['date'] is Timestamp) {
      dateFromJson = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is String) {
      dateFromJson = DateTime.tryParse(json['date']) ?? DateTime.now();
    }

    return Order(
      id: json['id'] ?? const Uuid().v4(),
      restaurantId: json['restaurantId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      date: dateFromJson,
      items: itemList,
      deliveryFee: (json['deliveryFee'] ?? 0).toInt(),
      subtotal: (json['subtotal'] ?? 0).toInt(),
      totalAmount: (json['totalAmount'] ?? 0).toInt(),
      status: statusFromJson,
      deliveryAddress: json['deliveryAddress'] is Map ? Map<String, dynamic>.from(json['deliveryAddress'] as Map) : null,
      paymentMethodInfo: json['paymentMethodInfo'] is Map ? Map<String, dynamic>.from(json['paymentMethodInfo'] as Map) : null,
    );
  }

  Order copyWith({
    String? id,
    String? restaurantId,
    String? userId,
    DateTime? date,
    List<OrderItem>? items,
    int? deliveryFee,
    int? subtotal,
    int? totalAmount,
    OrderStatus? status,
    Map<String, dynamic>? deliveryAddress,
    Map<String, dynamic>? paymentMethodInfo,
  }) {
    return Order(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      items: items ?? List.from(this.items),
      deliveryFee: deliveryFee ?? this.deliveryFee,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? (this.deliveryAddress != null ? Map.from(this.deliveryAddress!) : null),
      paymentMethodInfo: paymentMethodInfo ?? (this.paymentMethodInfo != null ? Map.from(this.paymentMethodInfo!) : null),
    );
  }

  @override
  bool operator ==(Object other) => other is Order && id == other.id;
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() {
    return 'Order(id: $id, userId: $userId, restaurantId: $restaurantId, status: $status, total: $totalAmount)';
  }
}
