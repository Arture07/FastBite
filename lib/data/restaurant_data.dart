// lib/data/restaurant_data.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/review.dart'; // IMPORTAR O MODELO REVIEW

class RestaurantData extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Restaurant> _listRestaurant = []; // Lista principal de todos os restaurantes carregados
  bool _isLoaded = false; // Indica se o carregamento inicial do Firestore foi feito
  bool _isLoading = false; // Indica se uma operação de carregamento está em progresso

  // Filtros atuais
  String? _activeSearchQuery;
  String? _activeCategoryFilter;

  // Resultados dos filtros
  List<Restaurant> _filteredRestaurantsResult = [];
  List<MapEntry<String, Dish>> _filteredDishesResult = [];
  bool _isFilterActive = false;

  // Getters públicos para a UI
  List<Restaurant> get listRestaurant => List.unmodifiable(_listRestaurant);
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  List<Restaurant> get filteredRestaurantsResult => List.unmodifiable(_filteredRestaurantsResult);
  List<MapEntry<String, Dish>> get filteredDishesResult => List.unmodifiable(_filteredDishesResult);
  String? get activeCategoryFilter => _activeCategoryFilter;
  bool get isFilterActive => _isFilterActive;
  String? get activeSearchQuery => _activeSearchQuery;

  /// Getter para a seção "Descubra Novos Sabores" na HomeScreen.
  /// Retorna uma lista de pares (RestaurantId, Dish) de todos os restaurantes.
  List<MapEntry<String, Dish>> get allDishesForDiscovery {
    if (!_isLoaded) return []; 
    final List<MapEntry<String, Dish>> allDishes = [];
    for (var restaurant in _listRestaurant) {
      for (var dish in restaurant.dishes) {
        allDishes.add(MapEntry(restaurant.id, dish));
      }
    }
    return List.unmodifiable(allDishes);
  }

  /// Carrega todos os restaurantes e seus respectivos pratos do Firestore.
  Future<void> loadRestaurants() async {
    if (_isLoading) return; // Evita múltiplas chamadas se já estiver carregando
    
    if (_isLoaded && _listRestaurant.isNotEmpty) {
      debugPrint("RestaurantData (Firestore): Dados já carregados. Aplicando filtros...");
      _applyFiltersInternal(); 
      return;
    }
    debugPrint("RestaurantData (Firestore): Iniciando carregamento de restaurantes e pratos do Firestore...");
    _isLoading = true;
    if (!_isLoaded) { 
      notifyListeners(); // Notifica UI para mostrar loading apenas na primeira carga
    }

    try {
      QuerySnapshot restaurantSnapshot = await _firestore.collection('restaurants').get();
      List<Restaurant> tempList = [];

      for (var restaurantDoc in restaurantSnapshot.docs) {
        Map<String, dynamic> restaurantDataMap = restaurantDoc.data() as Map<String, dynamic>;
        restaurantDataMap['id'] = restaurantDoc.id; 
        Restaurant restaurant = Restaurant.fromJson(restaurantDataMap);

        QuerySnapshot dishesSnapshot = await restaurantDoc.reference.collection('dishes').get();
        List<Dish> dishesList = dishesSnapshot.docs.map((dishDoc) {
          Map<String, dynamic> dishDataMap = dishDoc.data() as Map<String, dynamic>;
          dishDataMap['id'] = dishDoc.id; 
          return Dish.fromJson(dishDataMap);
        }).toList();
        
        restaurant.dishes = dishesList; 
        tempList.add(restaurant);
      }
      _listRestaurant = tempList;
      _isLoaded = true; 
      debugPrint("RestaurantData (Firestore): Restaurantes e pratos carregados (${_listRestaurant.length} restaurantes).");
    } catch (e, s) {
      _isLoaded = true; 
      debugPrint("RestaurantData (Firestore): Erro CRÍTICO ao carregar restaurantes/pratos: $e\n$s");
      _listRestaurant = []; 
    } finally {
      _isLoading = false;
      _applyFiltersInternal(); // Aplica filtros e notifica
    }
  }

  /// Aplica os filtros de categoria e busca textual à lista de restaurantes.
  void applyFilters({String? category, String? query}) {
     final String normalizedQuery = query?.trim().toLowerCase() ?? '';
     bool filtersChanged = (_activeCategoryFilter != category) || (_activeSearchQuery != normalizedQuery);
     
     _activeCategoryFilter = category;
     _activeSearchQuery = normalizedQuery;

     if (filtersChanged || !_isLoaded || (_filteredRestaurantsResult.isEmpty && _filteredDishesResult.isEmpty && !_isFilterActive)) {
        _applyFiltersInternal();
     }
  }

  /// Lógica interna para filtrar restaurantes e pratos.
  void _applyFiltersInternal() {
    final String query = _activeSearchQuery ?? '';
    final String? categoryFilter = _activeCategoryFilter;
    _isFilterActive = (query.isNotEmpty || categoryFilter != null);

    List<Restaurant> tempFilteredRestaurants = [];
    List<MapEntry<String, Dish>> tempFilteredDishes = [];

    if (categoryFilter != null) {
      final String normalizedCategory = categoryFilter.trim().toLowerCase();
      for (final restaurant in _listRestaurant) {
        for (final dish in restaurant.dishes) {
          bool categoryMatch = dish.categories.any(
            (dishCat) => dishCat.trim().toLowerCase() == normalizedCategory,
          );
          if (categoryMatch) {
            bool searchMatch = query.isEmpty ||
                dish.name.toLowerCase().contains(query) ||
                dish.description.toLowerCase().contains(query) ||
                restaurant.name.toLowerCase().contains(query);
            if (searchMatch) {
              tempFilteredDishes.add(MapEntry(restaurant.id, dish));
            }
          }
        }
      }
      _filteredRestaurantsResult = []; 
      _filteredDishesResult = tempFilteredDishes;
    } else {
      if (query.isNotEmpty) {
        tempFilteredRestaurants = _listRestaurant.where((restaurant) {
          bool nameMatch = restaurant.name.toLowerCase().contains(query);
          bool dishMatchInRestaurant = restaurant.dishes.any((dish) =>
              dish.name.toLowerCase().contains(query) ||
              dish.description.toLowerCase().contains(query));
          return nameMatch || dishMatchInRestaurant;
        }).toList();
      } else {
        tempFilteredRestaurants = List.from(_listRestaurant);
      }
      _filteredRestaurantsResult = tempFilteredRestaurants;
      _filteredDishesResult = [];
    }
    
    debugPrint("RestaurantData: Filtros aplicados. Categoria: '$categoryFilter', Busca: '$query'. Resultados: ${_filteredRestaurantsResult.length} restaurantes, ${_filteredDishesResult.length} pratos.");
    notifyListeners();
  }

  // --- MÉTODOS CRUD PARA RESTAURANTES E PRATOS ---

  /// Adiciona um novo restaurante ao Firestore e à lista local.
  Future<void> addRestaurant(Restaurant newRestaurant) async { 
    if (!_isLoaded) await loadRestaurants();
    try {
      await _firestore.collection('restaurants').doc(newRestaurant.id).set(newRestaurant.toJson());
      _listRestaurant.add(newRestaurant);
      _applyFiltersInternal();
      debugPrint("RestaurantData (Firestore): Restaurante ${newRestaurant.name} adicionado.");
    } catch (e, s) {
      debugPrint("RestaurantData (Firestore): Erro ao adicionar restaurante: $e\n$s");
      throw Exception("Falha ao adicionar restaurante.");
    }
  }

  /// Adiciona um novo prato a um restaurante específico no Firestore e na lista local.
  Future<void> addDishToRestaurant(String restaurantId, Dish newDish) async { 
    if (!_isLoaded) await loadRestaurants();
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dishes')
          .doc(newDish.id) 
          .set(newDish.toJson());

      final restaurantIndex = _listRestaurant.indexWhere((r) => r.id == restaurantId);
      if (restaurantIndex != -1) {
        List<Dish> updatedDishes = List.from(_listRestaurant[restaurantIndex].dishes)..add(newDish);
        _listRestaurant[restaurantIndex] = _listRestaurant[restaurantIndex].copyWith(dishes: updatedDishes);
      }
      _applyFiltersInternal();
      debugPrint("RestaurantData (Firestore): Prato ${newDish.name} adicionado ao restaurante $restaurantId.");
    } catch (e, s) {
      debugPrint("RestaurantData (Firestore): Erro ao adicionar prato ao restaurante $restaurantId: $e\n$s");
      throw Exception("Falha ao adicionar prato.");
    }
  }

  /// Atualiza o perfil de um restaurante no Firestore e na lista local.
  Future<void> updateRestaurantProfile(Restaurant updatedRestaurant) async {
    if (!_isLoaded) await loadRestaurants();
    try {
      Map<String, dynamic> dataToUpdate = updatedRestaurant.toJson();
      dataToUpdate.remove('dishes'); 

      await _firestore.collection('restaurants').doc(updatedRestaurant.id).update(dataToUpdate);

      final index = _listRestaurant.indexWhere((r) => r.id == updatedRestaurant.id);
      if (index != -1) {
        _listRestaurant[index] = updatedRestaurant.copyWith(dishes: _listRestaurant[index].dishes);
      }
      _applyFiltersInternal();
      debugPrint("RestaurantData (Firestore): Perfil do restaurante ${updatedRestaurant.name} atualizado.");
    } catch (e, s) {
      debugPrint("RestaurantData (Firestore): Erro ao atualizar perfil do restaurante: $e\n$s");
      throw Exception("Falha ao atualizar perfil do restaurante.");
    }
  }

  /// Atualiza um prato existente de um restaurante no Firestore e na lista local.
  Future<void> updateDishInRestaurant(String restaurantId, Dish updatedDish) async {
    if (!_isLoaded) {
      debugPrint("RestaurantData: Tentativa de atualizar prato com dados não carregados. Carregando primeiro...");
      await loadRestaurants(); 
    }

    final restaurantIndex = _listRestaurant.indexWhere((r) => r.id == restaurantId);
    if (restaurantIndex == -1) {
      debugPrint("RestaurantData: Erro ao atualizar prato - Restaurante ID $restaurantId não encontrado na lista local.");
      throw Exception("Restaurante não encontrado para atualizar o prato.");
    }

    final originalRestaurant = _listRestaurant[restaurantIndex];
    final dishIndex = originalRestaurant.dishes.indexWhere((d) => d.id == updatedDish.id);
    if (dishIndex == -1) {
      debugPrint("RestaurantData: Erro ao atualizar prato - Prato ID ${updatedDish.id} não encontrado no restaurante $restaurantId.");
      throw Exception("Prato não encontrado para atualização no restaurante especificado.");
    }

    try {
      debugPrint("RestaurantData: Atualizando prato no Firestore: ${updatedDish.toJson()} para o caminho restaurants/$restaurantId/dishes/${updatedDish.id}");
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dishes')
          .doc(updatedDish.id)
          .update(updatedDish.toJson());

      List<Dish> newDishesList = List.from(originalRestaurant.dishes);
      newDishesList[dishIndex] = updatedDish; 
      _listRestaurant[restaurantIndex] = originalRestaurant.copyWith(dishes: newDishesList);
      
      _applyFiltersInternal(); 
      debugPrint("RestaurantData (Firestore): Prato ${updatedDish.name} atualizado com sucesso no restaurante $restaurantId.");
    } catch (e, s) {
      debugPrint("RestaurantData (Firestore): ERRO ao atualizar prato $restaurantId/${updatedDish.id}: $e\n$s");
      throw Exception("Falha ao atualizar o prato no banco de dados.");
    }
  }

  /// Remove um prato de um restaurante no Firestore e da lista local.
  Future<void> removeDishFromRestaurant(String restaurantId, String dishId) async {
    if (!_isLoaded) await loadRestaurants();
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dishes')
          .doc(dishId)
          .delete();

      final restaurantIndex = _listRestaurant.indexWhere((r) => r.id == restaurantId);
      if (restaurantIndex != -1) {
        List<Dish> updatedDishes = List.from(_listRestaurant[restaurantIndex].dishes)
          ..removeWhere((d) => d.id == dishId);
        _listRestaurant[restaurantIndex] = _listRestaurant[restaurantIndex].copyWith(dishes: updatedDishes);
      }
      _applyFiltersInternal();
      debugPrint("RestaurantData (Firestore): Prato $dishId removido do restaurante $restaurantId.");
    } catch (e, s) {
      debugPrint("RestaurantData (Firestore): Erro ao remover prato $dishId do restaurante $restaurantId: $e\n$s");
      throw Exception("Falha ao remover o prato.");
    }
  }

  // --- AVALIAÇÃO E COMENTÁRIO DE RESTAURANTE ---
  Future<void> submitRestaurantReview({
    required String restaurantId,
    required String userId,
    required String userName,
    String? userImagePath,
    required double rating,
    String? comment,
  }) async {
    if (rating < 0.5 || rating > 5) throw ArgumentError("Avaliação deve ser entre 0.5 e 5.");

    final DocumentReference restaurantDocRef = _firestore.collection('restaurants').doc(restaurantId);
    final DocumentReference reviewDocRef = restaurantDocRef.collection('restaurant_reviews').doc(userId);

    final Map<String, dynamic> reviewDataForFirestore = {
      'userId': userId,
      'userName': userName,
      'userImagePath': userImagePath,
      'rating': rating,
      'comment': comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot restaurantSnapshot = await transaction.get(restaurantDocRef);
        DocumentSnapshot? oldReviewSnapshot;
        try { oldReviewSnapshot = await transaction.get(reviewDocRef); } catch (e) {/*Ignora se não existir*/}

        if (!restaurantSnapshot.exists) throw Exception("Restaurante não encontrado!");
        
        Map<String, dynamic> restaurantDataMap = restaurantSnapshot.data() as Map<String, dynamic>;
        int currentRatingCount = (restaurantDataMap['ratingCount'] ?? 0).toInt();
        double currentRatingSum = (restaurantDataMap['ratingSum'] ?? 0.0).toDouble();
        
        if (oldReviewSnapshot != null && oldReviewSnapshot.exists) {
          final oldRating = (oldReviewSnapshot.data() as Map<String, dynamic>)['rating']?.toDouble() ?? 0.0;
          currentRatingSum = currentRatingSum - oldRating + rating;
        } else {
          currentRatingSum += rating;
          currentRatingCount++;
        }
        
        double newAverageStars = (currentRatingCount > 0) ? (currentRatingSum / currentRatingCount) : 0.0;
        newAverageStars = double.parse(newAverageStars.toStringAsFixed(1));

        transaction.set(reviewDocRef, reviewDataForFirestore);
        transaction.update(restaurantDocRef, {
          'stars': newAverageStars,
          'ratingCount': currentRatingCount,
          'ratingSum': currentRatingSum,
        });

        final index = _listRestaurant.indexWhere((r) => r.id == restaurantId);
        if (index != -1) {
          _listRestaurant[index] = _listRestaurant[index].copyWith(
            stars: newAverageStars,
            ratingCount: currentRatingCount,
            ratingSum: currentRatingSum,
          );
        }
      });
      notifyListeners();
      debugPrint("RestaurantData: Review de restaurante processada e UI notificada.");
    } catch (e, s) {
      debugPrint("RestaurantData: Erro ao submeter review de restaurante: $e\n$s");
      throw Exception("Não foi possível enviar sua avaliação para o restaurante.");
    }
  }

  // --- AVALIAÇÃO E COMENTÁRIO DE PRATO ---
  Future<void> submitDishReview({
    required String restaurantId,
    required String dishId,
    required String userId,
    required String userName,
    String? userImagePath,
    required double rating,
    String? comment,
  }) async {
    if (rating < 0.5 || rating > 5) throw ArgumentError("Avaliação do prato deve ser entre 0.5 e 5.");

    final DocumentReference dishDocRef = _firestore.collection('restaurants').doc(restaurantId).collection('dishes').doc(dishId);
    final DocumentReference reviewDocRef = dishDocRef.collection('dish_reviews').doc(userId);

    final Map<String, dynamic> reviewDataForFirestore = {
      'userId': userId,
      'userName': userName,
      'userImagePath': userImagePath,
      'rating': rating,
      'comment': comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot dishSnapshot = await transaction.get(dishDocRef);
        DocumentSnapshot? oldReviewSnapshot;
        try { oldReviewSnapshot = await transaction.get(reviewDocRef); } catch (e) {/*Ignora*/}

        if (!dishSnapshot.exists) throw Exception("Prato não encontrado!");
        
        Map<String, dynamic> dishDataMap = dishSnapshot.data() as Map<String, dynamic>;
        int currentRatingCount = (dishDataMap['ratingCount'] ?? 0).toInt();
        double currentAverageRating = (dishDataMap['averageRating'] ?? 0.0).toDouble();
        // Recalcula a soma das notas anteriores para precisão
        // Se for uma nova review, currentRatingCount (antes do incremento) é o número de reviews anteriores.
        // Se for uma atualização, currentRatingCount já inclui a review atual (que será subtraída e depois somada).
        double currentRatingSum = currentAverageRating * (oldReviewSnapshot != null && oldReviewSnapshot.exists ? currentRatingCount : (currentRatingCount > 0 ? currentRatingCount : 0) ) ;
         // Correção: Se for uma nova review, a soma deve ser baseada em currentRatingCount (que ainda não foi incrementado)
        if (oldReviewSnapshot == null || !oldReviewSnapshot.exists) {
            currentRatingSum = currentAverageRating * currentRatingCount;
        }


        double oldUserRating = 0.0;
        if (oldReviewSnapshot != null && oldReviewSnapshot.exists) {
          oldUserRating = (oldReviewSnapshot.data() as Map<String, dynamic>)['rating']?.toDouble() ?? 0.0;
          currentRatingSum = currentRatingSum - oldUserRating + rating; // Ajusta a soma
        } else {
          currentRatingSum += rating; // Adiciona nova nota à soma
          currentRatingCount++; // Incrementa contagem apenas para novas reviews
        }
        
        double newAverageRating = (currentRatingCount > 0) ? (currentRatingSum / currentRatingCount) : 0.0;
        newAverageRating = double.parse(newAverageRating.toStringAsFixed(1));

        transaction.set(reviewDocRef, reviewDataForFirestore); // Salva/atualiza a review individual
        transaction.update(dishDocRef, { // Atualiza os dados agregados no prato
          'averageRating': newAverageRating,
          'ratingCount': currentRatingCount,
        });

        // Atualiza a lista local
        final restIndex = _listRestaurant.indexWhere((r) => r.id == restaurantId);
        if (restIndex != -1) {
          final dishIndex = _listRestaurant[restIndex].dishes.indexWhere((d) => d.id == dishId);
          if (dishIndex != -1) {
            _listRestaurant[restIndex].dishes[dishIndex] = _listRestaurant[restIndex].dishes[dishIndex].copyWith(
              averageRating: newAverageRating,
              ratingCount: currentRatingCount,
            );
          }
        }
      });
      notifyListeners(); // Notifica para atualizar a UI (ex: DishDetailScreen)
      debugPrint("RestaurantData: Review de prato processada e UI notificada.");
    } catch (e, s) {
      debugPrint("RestaurantData (Firestore): ERRO ao submeter review de prato $restaurantId/$dishId: $e\n$s");
      throw Exception("Falha ao enviar sua avaliação para o prato.");
    }
  }

  // --- BUSCAR REVIEWS ---
  Future<List<Review>> getRestaurantReviews(String restaurantId, {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants').doc(restaurantId).collection('restaurant_reviews')
          .orderBy('timestamp', descending: true).limit(limit).get();
      return snapshot.docs.map((doc) => Review.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Erro ao buscar reviews do restaurante $restaurantId: $e");
      return [];
    }
  }

  Future<List<Review>> getDishReviews(String restaurantId, String dishId, {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants').doc(restaurantId).collection('dishes').doc(dishId).collection('dish_reviews')
          .orderBy('timestamp', descending: true).limit(limit).get();
      return snapshot.docs.map((doc) => Review.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Erro ao buscar reviews do prato $dishId ($restaurantId): $e");
      return [];
    }
  }
}