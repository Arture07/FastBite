import 'package:uuid/uuid.dart';

class Dish {
  final String id;
  final String name;
  final String description;
  final int price; // Armazenado como INT (centavos)
  final String imagePath;
  final List<String> categories;

  // <<< NOVOS CAMPOS PARA AVALIAÇÃO DE PRATOS >>>
  final double averageRating; // Média das notas (0.0 a 5.0)
  final int ratingCount;    // Número de avaliações recebidas

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    this.categories = const [],
    this.averageRating = 0.0, // Padrão inicial
    this.ratingCount = 0,     // Padrão inicial
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'imagePath': imagePath,
    'categories': categories,
    'averageRating': averageRating,
    'ratingCount': ratingCount,
  };

  factory Dish.fromJson(Map<String, dynamic> json) {
    num priceNum = json['price'] ?? 0;
    int priceInCents = 0;
    if (priceNum is int) {
      priceInCents = priceNum;
    } else if (priceNum is double) {
      priceInCents = (priceNum * 100).round();
    } else if (json['price'] is String) {
      double? parsedDouble = double.tryParse((json['price'] as String).replaceAll(',', '.'));
      if (parsedDouble != null) priceInCents = (parsedDouble * 100).round();
    }

    num avgRatingNum = json['averageRating'] ?? 0.0;
    num ratingCountNum = json['ratingCount'] ?? 0;

    return Dish(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name']?.toString() ?? 'Prato Desconhecido',
      description: json['description']?.toString() ?? '',
      price: priceInCents,
      imagePath: json['imagePath']?.toString() ?? 'assets/dishes/default.png',
      categories: List<String>.from(json['categories'] ?? []),
      averageRating: avgRatingNum.toDouble(),
      ratingCount: ratingCountNum.toInt(),
    );
  }

  Dish copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    String? imagePath,
    List<String>? categories,
    double? averageRating,
    int? ratingCount,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      categories: categories ?? List.from(this.categories),
      averageRating: averageRating ?? this.averageRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  @override
  bool operator ==(Object other) => other is Dish && id == other.id;
  @override
  int get hashCode => id.hashCode;
}
