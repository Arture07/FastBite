import 'package:myapp/model/dish.dart'; // Garanta que Dish tem toJson/fromJson
import 'package:uuid/uuid.dart';

class Restaurant {
  String id;
  String imagePath;
  String name;
  String description;
  double stars; // Continuará a ser a média
  int distance;
  List<String> categories;
  List<Dish> dishes;

  // <<< NOVOS CAMPOS PARA GERENCIAR AVALIAÇÕES >>>
  int ratingCount; // Número total de avaliações
  double ratingSum;  // Soma de todas as notas de avaliação

  Restaurant({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.description,
    required this.stars,
    required this.distance,
    required this.categories,
    List<Dish>? dishes,
    this.ratingCount = 0, // Valor padrão inicial
    this.ratingSum = 0.0,   // Valor padrão inicial
  }) : dishes = dishes ?? [];

  // Converte para JSON para salvar no Firestore
  Map<String, dynamic> toJson() => {
    // 'id' não é salvo aqui, pois será o ID do documento
    'imagePath': imagePath,
    'name': name,
    'description': description,
    'stars': stars, // A média calculada
    'distance': distance,
    'categories': categories,
    // Os pratos são uma subcoleção, então não incluímos aqui
    // 'dishes': dishes.map((dish) => dish.toJson()).toList(),
    'ratingCount': ratingCount, // Salva o contador
    'ratingSum': ratingSum,     // Salva a soma
  };

  // Cria a partir do JSON lido do Firestore
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // A lista de pratos será carregada separadamente da subcoleção
    // List<Dish> dishList = []; // Inicialmente vazia

    // Trata 'stars', 'ratingCount', 'ratingSum' como números, convertendo se necessário
    num starsNum = json['stars'] ?? 0.0;
    num ratingCountNum = json['ratingCount'] ?? 0;
    num ratingSumNum = json['ratingSum'] ?? 0.0;

    return Restaurant(
      id: json['id'] ?? const Uuid().v4(), // Usa o ID do documento se não estiver no mapa
      imagePath: json['imagePath'] ?? 'restaurants/default.png',
      name: json['name'] ?? 'Restaurante Desconhecido',
      description: json['description'] ?? '',
      stars: starsNum.toDouble(),
      distance: (json['distance'] ?? 0).toInt(),
      categories: List<String>.from(json['categories'] ?? []),
      dishes: [], // Pratos serão carregados separadamente
      ratingCount: ratingCountNum.toInt(),
      ratingSum: ratingSumNum.toDouble(),
    );
  }

  // --- Métodos CRUD para Pratos ---
  void addDish(Dish newDish) {
    // <<< MÉTODO NECESSÁRIO
    if (!dishes.any((d) => d.id == newDish.id)) {
      dishes.add(newDish);
    }
  }

  bool updateDish(Dish updatedDish) {
    // <<< MÉTODO NECESSÁRIO
    int index = dishes.indexWhere((d) => d.id == updatedDish.id);
    if (index != -1) {
      dishes[index] = updatedDish;
      return true;
    }
    return false;
  }

  bool removeDish(String dishId) {
    // <<< MÉTODO NECESSÁRIO
    int initialLength = dishes.length;
    dishes.removeWhere((d) => d.id == dishId);
    return dishes.length < initialLength;
  }
  // --- Fim CRUD Pratos ---

  Restaurant copyWith({
    String? id,
    String? imagePath,
    String? name,
    String? description,
    double? stars,
    int? distance,
    List<String>? categories,
    List<Dish>? dishes,
    int? ratingCount,
    double? ratingSum,
  }) {
    return Restaurant(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      name: name ?? this.name,
      description: description ?? this.description,
      stars: stars ?? this.stars,
      distance: distance ?? this.distance,
      categories: categories ?? List.from(this.categories),
      dishes: dishes ?? List.from(this.dishes),
      ratingCount: ratingCount ?? this.ratingCount,
      ratingSum: ratingSum ?? this.ratingSum,
    );
  }

  @override
  bool operator ==(Object other) => other is Restaurant && id == other.id;
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => 'Restaurant{id: $id, name: $name, stars: $stars, ratings: $ratingCount}';
}