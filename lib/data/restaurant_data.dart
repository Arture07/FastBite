import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/review.dart'; // <<< IMPORTAR O NOVO MODELO REVIEW

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

  // Getters ...
  List<Restaurant> get listRestaurant => List.unmodifiable(_listRestaurant);
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  List<Restaurant> get filteredRestaurantsResult => List.unmodifiable(_filteredRestaurantsResult);
  List<MapEntry<String, Dish>> get filteredDishesResult => List.unmodifiable(_filteredDishesResult);
  String? get activeCategoryFilter => _activeCategoryFilter;
  bool get isFilterActive => _isFilterActive;
  String? get activeSearchQuery => _activeSearchQuery;

  // --- CARREGAMENTO DE DADOS DO FIRESTORE ---
  Future<void> loadRestaurants() async {
    if (_isLoaded && _listRestaurant.isNotEmpty) {
      debugPrint("RestaurantData (Firestore): Dados já carregados.");
      _applyFiltersInternal();
      return;
    }
    debugPrint("RestaurantData (Firestore): Iniciando carregamento do Firestore...");
    _isLoading = true;
    if (!_isLoaded) notifyListeners(); // Notifica apenas se for o primeiro load

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
      debugPrint("RestaurantData (Firestore): Erro CRÍTICO ao carregar: $e\n$s");
      _listRestaurant = [];
    } finally {
      _isLoading = false;
      _applyFiltersInternal(); // Aplica filtros e notifica
    }
  }
  // --- LÓGICA DE FILTRAGEM (Permanece a mesma que você já tem) ---
  void applyFilters({String? category, String? query}) {
    // ... (seu código exato do applyFilters que chama _applyFiltersInternal)
    // ... (esta função apenas atualiza _activeCategoryFilter e _activeSearchQuery e chama _applyFiltersInternal)
    final String normalizedQuery = query?.trim().toLowerCase() ?? '';
    bool filtersChanged = false;

    if (_activeCategoryFilter != category) {
      _activeCategoryFilter = category;
      filtersChanged = true;
    }
    if (_activeSearchQuery != normalizedQuery) {
      _activeSearchQuery = normalizedQuery;
      filtersChanged = true;
    }

    if (filtersChanged) {
      _applyFiltersInternal();
    }
  }

  /// Lógica interna que realmente executa a filtragem e atualiza os resultados.
  void _applyFiltersInternal() {
    final String query = _activeSearchQuery ?? '';
    final String? categoryFilter = _activeCategoryFilter; // Categoria selecionada no UI

    // Define se algum tipo de filtro está ativo
    _isFilterActive = (query.isNotEmpty || categoryFilter != null);

    List<Restaurant> tempFilteredRestaurants = [];
    List<MapEntry<String, Dish>> tempFilteredDishes = [];

    if (categoryFilter != null) {
      // --- MODO: FILTRANDO POR CATEGORIA (RESULTADO SÃO PRATOS) ---
      debugPrint("RestaurantData: Interno - Filtrando PRATOS. Categoria: '$categoryFilter', Busca: '$query'");
      final String normalizedCategory = categoryFilter.trim().toLowerCase();

      for (final restaurant in _listRestaurant) {
        for (final dish in restaurant.dishes) {
          // 1. Verifica se o PRATO pertence à categoria selecionada
          bool categoryMatch = dish.categories.any(
            (dishCat) => dishCat.trim().toLowerCase() == normalizedCategory,
          );

          if (categoryMatch) {
            // 2. Se pertence à categoria, verifica se corresponde à busca textual (se houver)
            bool searchMatch = query.isEmpty || // Se não há busca, considera match
                dish.name.toLowerCase().contains(query) ||
                dish.description.toLowerCase().contains(query) ||
                restaurant.name.toLowerCase().contains(query); // Inclui nome do restaurante

            if (searchMatch) {
              tempFilteredDishes.add(MapEntry(restaurant.id, dish));
            }
          }
        }
      }
      // Quando se filtra por pratos, a lista de restaurantes filtrados fica vazia
      _filteredRestaurantsResult = []; 
      _filteredDishesResult = tempFilteredDishes;

    } else {
      // --- MODO: SEM FILTRO DE CATEGORIA (RESULTADO SÃO RESTAURANTES) ---
      debugPrint("RestaurantData: Interno - Filtrando RESTAURANTES. Busca: '$query'");
      if (query.isNotEmpty) {
        // Filtra restaurantes pela busca textual
        tempFilteredRestaurants = _listRestaurant.where((restaurant) {
          bool nameMatch = restaurant.name.toLowerCase().contains(query);
          bool dishMatchInRestaurant = restaurant.dishes.any((dish) =>
              dish.name.toLowerCase().contains(query) ||
              dish.description.toLowerCase().contains(query));
          return nameMatch || dishMatchInRestaurant;
        }).toList();
      } else {
        // Sem categoria E sem busca textual -> mostra todos os restaurantes
        tempFilteredRestaurants = List.from(_listRestaurant);
      }
      // Quando se filtra por restaurantes, a lista de pratos filtrados fica vazia
      _filteredRestaurantsResult = tempFilteredRestaurants;
      _filteredDishesResult = [];
    }
    
    debugPrint("RestaurantData: Filtros INTERNOS aplicados. Resultados: ${_filteredRestaurantsResult.length} restaurantes, ${_filteredDishesResult.length} pratos.");
    notifyListeners(); // Notifica a UI sobre a mudança nos resultados
  }

  // --- MÉTODOS CRUD COM FIRESTORE ---

  List<MapEntry<String, Dish>> get allDishesForDiscovery {
        if (!_isLoaded) return []; // Retorna vazio se os dados não foram carregados

        final List<MapEntry<String, Dish>> allDishes = [];
        for (var restaurant in _listRestaurant) {
          for (var dish in restaurant.dishes) {
            allDishes.add(MapEntry(restaurant.id, dish));
          }
        }
        // Opcional: Embaralhar a lista para aleatoriedade
        // allDishes.shuffle();
        return List.unmodifiable(allDishes);
      }

  Future<void> addRestaurant(Restaurant newRestaurant) async {
    if (!_isLoaded) await loadRestaurants();
    try {
      // Adiciona ao Firestore. Use o ID do newRestaurant como ID do documento.
      await _firestore.collection('restaurants').doc(newRestaurant.id).set(newRestaurant.toJson());
      
      // Adiciona à lista local e reaplica filtros
      _listRestaurant.add(newRestaurant);
      _applyFiltersInternal(); // Reaplicar filtros e notificar
      debugPrint("RestaurantData (Firestore): Restaurante ${newRestaurant.name} adicionado.");
    } catch (e) {
      debugPrint("RestaurantData (Firestore): Erro ao adicionar restaurante: $e");
    }
  }

  Future<void> addDishToRestaurant(String restaurantId, Dish newDish) async {
    if (!_isLoaded) await loadRestaurants();
    try {
      // Adiciona o prato à subcoleção 'dishes' do restaurante no Firestore
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dishes')
          .doc(newDish.id) // Usa o ID do prato como ID do documento
          .set(newDish.toJson());

      // Atualiza a lista local
      final restaurant = _listRestaurant.firstWhere((r) => r.id == restaurantId);
      restaurant.addDish(newDish); // Método do modelo Restaurant
      _applyFiltersInternal(); // Reaplicar filtros e notificar
      debugPrint("RestaurantData (Firestore): Prato ${newDish.name} adicionado ao restaurante $restaurantId.");
    } catch (e) {
      debugPrint("RestaurantData (Firestore): Erro ao adicionar prato ao restaurante $restaurantId: $e");
    }
  }

  Future<void> updateRestaurantProfile(Restaurant updatedRestaurant) async {
    if (!_isLoaded) await loadRestaurants();
    try {
      // Atualiza o documento do restaurante no Firestore
      // Cuidado: .set com merge:true ou .update
      // Se updatedRestaurant.toJson() não inclui os pratos, eles podem ser removidos.
      // É mais seguro atualizar campos específicos ou garantir que toJson() está completo.
      // Para perfil, geralmente não se mexe nos pratos.
      Map<String, dynamic> dataToUpdate = updatedRestaurant.toJson();
      dataToUpdate.remove('dishes'); // Não atualiza a subcoleção de pratos aqui

      await _firestore.collection('restaurants').doc(updatedRestaurant.id).update(dataToUpdate);

      // Atualiza a lista local
      final index = _listRestaurant.indexWhere((r) => r.id == updatedRestaurant.id);
      if (index != -1) {
        updatedRestaurant.dishes = _listRestaurant[index].dishes; // Mantém pratos existentes
        _listRestaurant[index] = updatedRestaurant;
        _applyFiltersInternal(); // Reaplicar filtros e notificar
        debugPrint("RestaurantData (Firestore): Perfil do restaurante ${updatedRestaurant.name} atualizado.");
      }
    } catch (e) {
      debugPrint("RestaurantData (Firestore): Erro ao atualizar perfil do restaurante: $e");
      throw Exception("Falha ao atualizar perfil do restaurante.");
    }
  }

  Future<void> updateDishInRestaurant(String restaurantId, Dish updatedDish) async {
    if (!_isLoaded) await loadRestaurants();
    try {
      // Atualiza o documento do prato na subcoleção
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dishes')
          .doc(updatedDish.id)
          .update(updatedDish.toJson());

      // Atualiza a lista local
      final restaurant = _listRestaurant.firstWhere((r) => r.id == restaurantId);
      bool updatedInModel = restaurant.updateDish(updatedDish);
      if (updatedInModel) {
        _applyFiltersInternal(); // Reaplicar filtros e notificar
        debugPrint("RestaurantData (Firestore): Prato ${updatedDish.name} atualizado no restaurante $restaurantId.");
      }
    } catch (e) {
      debugPrint("RestaurantData (Firestore): Erro ao atualizar prato $restaurantId: $e");
    }
  }

  Future<void> removeDishFromRestaurant(String restaurantId, String dishId) async {
    if (!_isLoaded) await loadRestaurants();
    try {
      // Remove o documento do prato da subcoleção
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dishes')
          .doc(dishId)
          .delete();

      // Atualiza a lista local
      final restaurant = _listRestaurant.firstWhere((r) => r.id == restaurantId);
      bool removedFromModel = restaurant.removeDish(dishId);
      if (removedFromModel) {
        _applyFiltersInternal(); // Reaplicar filtros e notificar
        debugPrint("RestaurantData (Firestore): Prato $dishId removido do restaurante $restaurantId.");
      }
    } catch (e) {
      debugPrint("RestaurantData (Firestore): Erro ao remover prato $dishId do restaurante $restaurantId: $e");
    }
  }
  // --- NOVO MÉTODO PARA SUBMETER AVALIAÇÃO ---
  Future<void> submitRestaurantReview({
    required String restaurantId,
    required String userId,
    required String userName,
    required double rating,
    String? comment,
  }) async {
    if (rating < 0.5 || rating > 5) throw ArgumentError("Avaliação deve ser entre 0.5 e 5.");

    final DocumentReference restaurantDocRef = _firestore.collection('restaurants').doc(restaurantId);
    // Usaremos o userId como ID do documento da review para garantir uma review por utilizador
    final DocumentReference reviewDocRef = restaurantDocRef.collection('reviews').doc(userId);

    debugPrint("RestaurantData: Submetendo review para restaurante $restaurantId por $userId (Nota: $rating)");

    final newReview = Review(
      id: userId, // ID da review é o ID do utilizador
      userId: userId,
      userName: userName,
      rating: rating,
      comment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot restaurantSnapshot = await transaction.get(restaurantDocRef);
        DocumentSnapshot? oldReviewSnapshot; // Pode não existir
        try {
          oldReviewSnapshot = await transaction.get(reviewDocRef);
        } catch (e) {
          // Normal se o documento não existir ainda
          debugPrint("RestaurantData: Nenhuma review anterior encontrada para user $userId em $restaurantId.");
        }


        if (!restaurantSnapshot.exists) throw Exception("Restaurante não encontrado!");
        
        Map<String, dynamic> restaurantDataMap = restaurantSnapshot.data() as Map<String, dynamic>;
        int currentRatingCount = (restaurantDataMap['ratingCount'] ?? 0).toInt();
        double currentRatingSum = (restaurantDataMap['ratingSum'] ?? 0.0).toDouble();
        
        if (oldReviewSnapshot != null && oldReviewSnapshot.exists) {
          // Utilizador está a ATUALIZAR a sua review
          final oldRating = (oldReviewSnapshot.data() as Map<String, dynamic>)['rating']?.toDouble() ?? 0.0;
          currentRatingSum = currentRatingSum - oldRating + rating; // Ajusta a soma
          // ratingCount não muda, pois é uma atualização
        } else {
          // Nova review
          currentRatingSum += rating;
          currentRatingCount++;
        }
        
        double newAverageStars = (currentRatingCount > 0) ? (currentRatingSum / currentRatingCount) : 0.0;
        newAverageStars = double.parse(newAverageStars.toStringAsFixed(1));

        // Salva/Atualiza a review individual
        transaction.set(reviewDocRef, newReview.toJson());

        // Atualiza os dados agregados no documento do restaurante
        transaction.update(restaurantDocRef, {
          'stars': newAverageStars,
          'ratingCount': currentRatingCount,
          'ratingSum': currentRatingSum,
        });

        // Atualiza a lista local
        final index = _listRestaurant.indexWhere((r) => r.id == restaurantId);
        if (index != -1) {
          _listRestaurant[index] = _listRestaurant[index].copyWith(
            stars: newAverageStars,
            ratingCount: currentRatingCount,
            ratingSum: currentRatingSum,
          );
        }
      });
      notifyListeners(); // Notifica para atualizar a UI (ex: RestaurantScreen)
      debugPrint("RestaurantData: Review de restaurante processada e UI notificada.");
    } catch (e, s) {
      debugPrint("RestaurantData: Erro ao submeter review de restaurante: $e\n$s");
      throw Exception("Não foi possível enviar sua avaliação. Tente novamente.");
    }
  }

  // --- AVALIAÇÃO E COMENTÁRIO DE PRATO ---
  Future<void> submitDishReview({
    required String restaurantId,
    required String dishId,
    required String userId,
    required String userName,
    required double rating,
    String? comment,
  }) async {
    if (rating < 0.5 || rating > 5) throw ArgumentError("Avaliação do prato deve ser entre 0.5 e 5.");

    final DocumentReference dishDocRef = _firestore.collection('restaurants').doc(restaurantId).collection('dishes').doc(dishId);
    final DocumentReference reviewDocRef = dishDocRef.collection('reviews').doc(userId); // 1 review por utilizador por prato

    debugPrint("RestaurantData: Submetendo review para prato $dishId (Rest: $restaurantId) por $userId (Nota: $rating)");

    final newReview = Review(
      id: userId,
      userId: userId,
      userName: userName,
      rating: rating,
      comment: comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot dishSnapshot = await transaction.get(dishDocRef);
        DocumentSnapshot? oldReviewSnapshot;
        try {
          oldReviewSnapshot = await transaction.get(reviewDocRef);
        } catch (e) {
           debugPrint("RestaurantData: Nenhuma review anterior encontrada para user $userId no prato $dishId.");
        }

        if (!dishSnapshot.exists) throw Exception("Prato não encontrado!");
        
        Map<String, dynamic> dishDataMap = dishSnapshot.data() as Map<String, dynamic>;
        int currentRatingCount = (dishDataMap['ratingCount'] ?? 0).toInt();
        // Para pratos, a média é calculada a partir da soma das notas.
        // Se 'averageRating' já existe, podemos usá-lo para inferir a soma anterior.
        double currentRatingSum = (dishDataMap['averageRating'] != null && currentRatingCount > 0)
            ? (dishDataMap['averageRating'].toDouble() * currentRatingCount)
            : (dishDataMap['ratingSum'] ?? 0.0).toDouble(); // Fallback se 'ratingSum' existir
        
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
          // 'ratingSum': currentRatingSum, // Opcional: pode guardar a soma também
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
      notifyListeners();
      debugPrint("RestaurantData: Review de prato processada e UI notificada.");
    } catch (e, s) {
      debugPrint("RestaurantData: Erro ao submeter review de prato: $e\n$s");
      throw Exception("Não foi possível enviar sua avaliação para o prato.");
    }
  }

  // --- BUSCAR REVIEWS ---
  Future<List<Review>> getRestaurantReviews(String restaurantId, {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => Review.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Erro ao buscar reviews do restaurante $restaurantId: $e");
      return [];
    }
  }

  Future<List<Review>> getDishReviews(String restaurantId, String dishId, {int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('dishes')
          .doc(dishId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => Review.fromJson(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("Erro ao buscar reviews do prato $dishId: $e");
      return [];
    }
  }
}