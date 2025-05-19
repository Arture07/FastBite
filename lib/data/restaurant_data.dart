// lib/data/restaurant_data.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/review.dart'; // IMPORTAR O MODELO REVIEW

class RestaurantData extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Restaurant> _listRestaurant = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  String? _activeSearchQuery;
  String? _activeCategoryFilter;
  List<Restaurant> _filteredRestaurantsResult = [];
  List<MapEntry<String, Dish>> _filteredDishesResult = [];
  bool _isFilterActive = false;

  List<Restaurant> get listRestaurant => List.unmodifiable(_listRestaurant);
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  List<Restaurant> get filteredRestaurantsResult => List.unmodifiable(_filteredRestaurantsResult);
  List<MapEntry<String, Dish>> get filteredDishesResult => List.unmodifiable(_filteredDishesResult);
  String? get activeCategoryFilter => _activeCategoryFilter;
  bool get isFilterActive => _isFilterActive;
  String? get activeSearchQuery => _activeSearchQuery;

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

  Future<void> loadRestaurants() async {
    if (_isLoaded && _listRestaurant.isNotEmpty) {
      _applyFiltersInternal();
      return;
    }
    debugPrint("RestaurantData (Firestore): Iniciando carregamento do Firestore...");
    _isLoading = true;
    if (!_isLoaded) notifyListeners();

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
    } catch (e, s) {
      _isLoaded = true;
      debugPrint("RestaurantData (Firestore): Erro CRÍTICO ao carregar: $e\n$s");
      _listRestaurant = [];
    } finally {
      _isLoading = false;
      _applyFiltersInternal();
    }
  }

  void applyFilters({String? category, String? query}) {
     final String normalizedQuery = query?.trim().toLowerCase() ?? '';
     bool filtersChanged = (_activeCategoryFilter != category) || (_activeSearchQuery != normalizedQuery);
     _activeCategoryFilter = category;
     _activeSearchQuery = normalizedQuery;
     if (filtersChanged || !_isLoaded) {
        _applyFiltersInternal();
     }
  }

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
    notifyListeners();
  }

  Future<void> addRestaurant(Restaurant newRestaurant) async { /* ... */ }
  Future<void> addDishToRestaurant(String restaurantId, Dish newDish) async { /* ... */ }
  Future<void> updateRestaurantProfile(Restaurant updatedRestaurant) async { /* ... */ }
  Future<void> updateDishInRestaurant(String restaurantId, Dish updatedDish) async { /* ... */ }
  Future<void> removeDishFromRestaurant(String restaurantId, String dishId) async { /* ... */ }

  // --- AVALIAÇÃO E COMENTÁRIO DE RESTAURANTE ---
  Future<void> submitRestaurantReview({
    required String restaurantId,
    required String userId,
    required String userName,
    String? userImagePath, // <<< PARÂMETRO ADICIONADO
    required double rating,
    String? comment,
  }) async {
    if (rating < 0.5 || rating > 5) throw ArgumentError("Avaliação deve ser entre 0.5 e 5.");

    final DocumentReference restaurantDocRef = _firestore.collection('restaurants').doc(restaurantId);
    final DocumentReference reviewDocRef = restaurantDocRef.collection('restaurant_reviews').doc(userId);

    final newReview = Review(
      id: userId,
      userId: userId,
      userName: userName,
      userImagePath: userImagePath, // <<< USADO AQUI
      rating: rating,
      comment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot restaurantSnapshot = await transaction.get(restaurantDocRef);
        DocumentSnapshot? oldReviewSnapshot;
        try { oldReviewSnapshot = await transaction.get(reviewDocRef); } catch (e) {/*Ignora*/}

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

        transaction.set(reviewDocRef, newReview.toJson());
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
    } catch (e, s) {
      debugPrint("Erro ao submeter review de restaurante: $e\n$s");
      throw Exception("Não foi possível enviar sua avaliação para o restaurante.");
    }
  }

  // --- AVALIAÇÃO E COMENTÁRIO DE PRATO ---
  Future<void> submitDishReview({
    required String restaurantId,
    required String dishId,
    required String userId,
    required String userName,
    String? userImagePath, // <<< PARÂMETRO ADICIONADO
    required double rating,
    String? comment,
  }) async {
    if (rating < 0.5 || rating > 5) throw ArgumentError("Avaliação do prato deve ser entre 0.5 e 5.");

    final DocumentReference dishDocRef = _firestore.collection('restaurants').doc(restaurantId).collection('dishes').doc(dishId);
    final DocumentReference reviewDocRef = dishDocRef.collection('dish_reviews').doc(userId);

    final newReview = Review(
      id: userId,
      userId: userId,
      userName: userName,
      userImagePath: userImagePath, // <<< USADO AQUI
      rating: rating,
      comment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot dishSnapshot = await transaction.get(dishDocRef);
        DocumentSnapshot? oldReviewSnapshot;
        try { oldReviewSnapshot = await transaction.get(reviewDocRef); } catch (e) {/*Ignora*/}

        if (!dishSnapshot.exists) throw Exception("Prato não encontrado!");
        
        Map<String, dynamic> dishDataMap = dishSnapshot.data() as Map<String, dynamic>;
        int currentRatingCount = (dishDataMap['ratingCount'] ?? 0).toInt();
        double currentAverageRating = (dishDataMap['averageRating'] ?? 0.0).toDouble();
        double currentRatingSum = currentAverageRating * currentRatingCount;
        
        double oldUserRating = 0.0;
        if (oldReviewSnapshot != null && oldReviewSnapshot.exists) {
          oldUserRating = (oldReviewSnapshot.data() as Map<String, dynamic>)['rating']?.toDouble() ?? 0.0;
          currentRatingSum = currentRatingSum - oldUserRating + rating;
        } else {
          currentRatingSum += rating;
          currentRatingCount++;
        }
        
        double newAverageRating = (currentRatingCount > 0) ? (currentRatingSum / currentRatingCount) : 0.0;
        newAverageRating = double.parse(newAverageRating.toStringAsFixed(1));

        transaction.set(reviewDocRef, newReview.toJson());
        transaction.update(dishDocRef, {
          'averageRating': newAverageRating,
          'ratingCount': currentRatingCount,
        });

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
      notifyListeners();
    } catch (e, s) {
      debugPrint("Erro ao submeter review de prato: $e\n$s");
      throw Exception("Não foi possível enviar sua avaliação para o prato.");
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
      debugPrint("Erro ao buscar reviews do prato $dishId: $e");
      return [];
    }
  }
}