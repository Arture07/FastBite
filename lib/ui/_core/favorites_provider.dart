// lib/ui/_core/favorites_provider.dart
import 'package:flutter/foundation.dart';
import 'package:myapp/model/dish.dart'; // Necessário para getFavoriteDishes
import 'package:myapp/model/restaurant.dart'; // Necessário para getFavoriteRestaurants
import 'package:cloud_firestore/cloud_firestore.dart'; // Importar Firestore
import 'package:myapp/ui/_core/auth_provider.dart'; // Importar AuthProvider

/// Gerencia os IDs dos restaurantes e pratos favoritos do utilizador,
/// persistindo os dados em um documento específico no Firestore.
class FavoritesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthProvider _authProvider; // Recebe AuthProvider

  // Usar Set para performance e evitar duplicados
  final Set<String> _favoriteRestaurantIds = {};
  final Set<String> _favoriteDishIds = {};
  bool _isLoaded = false; // Controle de carregamento
  String? _currentUserId;
  DocumentReference? _userFavoritesDocRef; // Referência ao documento /users/{userId}/favorites/doc

  // Construtor
  FavoritesProvider(this._authProvider) {
    debugPrint("FavoritesProvider (Firestore): Inicializando...");
    _authProvider.addListener(_handleAuthChange);
    _handleAuthChange(); // Carrega dados iniciais
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChange);
    debugPrint("FavoritesProvider (Firestore): Disposed.");
    super.dispose();
  }

  // Reage a mudanças no login/logout
  void _handleAuthChange() {
    final newUserId = _authProvider.currentUser?.id;
    if (_currentUserId != newUserId) {
      debugPrint("FavoritesProvider (Firestore): Auth state changed. Old User: $_currentUserId, New User: $newUserId");
      _currentUserId = newUserId;
      _favoriteRestaurantIds.clear(); // Limpa sets
      _favoriteDishIds.clear();
      _userFavoritesDocRef = null; // Limpa referência
      _isLoaded = false; // Marca como não carregado
      notifyListeners(); // Notifica UI sobre limpeza

      if (_currentUserId != null) {
        // Define a referência para o documento único de favoritos do utilizador
        // Usamos um ID fixo como 'doc' para simplificar, pois só teremos um doc por utilizador.
        _userFavoritesDocRef = _firestore.collection('users').doc(_currentUserId!).collection('favorites').doc('doc');
        loadFavoritesFromFirestore(); // Carrega favoritos do novo utilizador
      }
    }
  }

  // Getters públicos
  Set<String> get favoriteRestaurantIds => Set.unmodifiable(_favoriteRestaurantIds);
  Set<String> get favoriteDishIds => Set.unmodifiable(_favoriteDishIds);
  bool get isLoaded => _isLoaded;

  // --- PERSISTÊNCIA COM FIRESTORE ---

  /// Carrega os IDs favoritos do documento único no Firestore.
  Future<void> loadFavoritesFromFirestore() async {
    if (_userFavoritesDocRef == null || _isLoaded) return; // Precisa de referência e não carregado
    debugPrint("FavoritesProvider (Firestore): Carregando favoritos para utilizador $_currentUserId...");
    _isLoaded = true; // Assume carregado
    // notifyListeners(); // Opcional

    try {
      DocumentSnapshot doc = await _userFavoritesDocRef!.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _favoriteRestaurantIds.clear();
        _favoriteDishIds.clear();
        // Carrega IDs dos arrays no Firestore (garante que são listas de strings)
        _favoriteRestaurantIds.addAll(List<String>.from(data['restaurantIds'] ?? []));
        _favoriteDishIds.addAll(List<String>.from(data['dishIds'] ?? []));
        debugPrint("FavoritesProvider (Firestore): Favoritos carregados (${_favoriteRestaurantIds.length} rests, ${_favoriteDishIds.length} dishes).");
      } else {
         debugPrint("FavoritesProvider (Firestore): Documento de favoritos não encontrado para utilizador $_currentUserId. Será criado ao favoritar.");
         // Não precisa limpar os sets, já estão vazios
      }
    } catch (e, s) {
       debugPrint("FavoritesProvider (Firestore): Erro ao carregar favoritos: $e");
       debugPrint("Stacktrace: $s");
       _favoriteRestaurantIds.clear();
       _favoriteDishIds.clear();
    } finally {
       notifyListeners(); // Notifica que o carregamento terminou
    }
  }

  /// Salva/Atualiza o documento de favoritos no Firestore com os IDs atuais.
  Future<void> _updateFavoritesInFirestore() async {
    if (_userFavoritesDocRef == null) {
       debugPrint("FavoritesProvider (Firestore): Tentativa de salvar favoritos sem utilizador logado.");
       return; // Precisa de utilizador
    }
    try {
      // Usa set com merge:true para criar o documento se não existir,
      // ou atualizar/sobrescrever os campos existentes.
      await _userFavoritesDocRef!.set({
        'restaurantIds': _favoriteRestaurantIds.toList(), // Converte Set para Lista para salvar
        'dishIds': _favoriteDishIds.toList(),          // Converte Set para Lista para salvar
      }, SetOptions(merge: true)); // Merge garante que outros campos (se houver) não sejam apagados
       debugPrint("FavoritesProvider (Firestore): Favoritos salvos no Firestore.");
    } catch (e) {
       debugPrint("FavoritesProvider (Firestore): Erro ao salvar favoritos: $e");
       // Considerar relançar exceção ou tratar erro
    }
  }


  // --- Métodos de Checagem (Inalterados) ---
  bool isRestaurantFavorite(String restaurantId) {
    return _favoriteRestaurantIds.contains(restaurantId);
  }
  bool isDishFavorite(String dishId) {
    return _favoriteDishIds.contains(dishId);
  }

  // --- Métodos de Modificação (Atualizados para chamar _updateFavoritesInFirestore) ---
  Future<void> toggleRestaurantFavorite(String restaurantId) async {
    if (_userFavoritesDocRef == null) return; // Precisa estar logado

    bool changed = false;
    if (_favoriteRestaurantIds.contains(restaurantId)) {
      changed = _favoriteRestaurantIds.remove(restaurantId);
    } else {
      changed = _favoriteRestaurantIds.add(restaurantId);
    }

    if (changed) {
       notifyListeners(); // Notifica UI imediatamente sobre a mudança visual
       await _updateFavoritesInFirestore(); // Salva no Firestore em background
    }
  }

  Future<void> toggleDishFavorite(String dishId) async {
     if (_userFavoritesDocRef == null) return; // Precisa estar logado

     bool changed = false;
     if (_favoriteDishIds.contains(dishId)) {
       changed = _favoriteDishIds.remove(dishId);
     } else {
       changed = _favoriteDishIds.add(dishId);
     }

     if(changed) {
        notifyListeners(); // Notifica UI imediatamente
        await _updateFavoritesInFirestore(); // Salva no Firestore em background
     }
  }

  // --- Métodos Helper (Inalterados na lógica) ---
  // Retorna a lista de objetos Restaurant favoritos com base nos IDs e na lista completa
  List<Restaurant> getFavoriteRestaurants(List<Restaurant> allRestaurants) {
    if (_favoriteRestaurantIds.isEmpty || allRestaurants.isEmpty) {
      return [];
    }
    // Filtra a lista completa de restaurantes mantendo apenas aqueles cujo ID está no Set de favoritos
    return allRestaurants
        .where((restaurant) => _favoriteRestaurantIds.contains(restaurant.id))
        .toList();
  }

  // Retorna a lista de objetos Dish favoritos
  List<Dish> getFavoriteDishes(List<Restaurant> allRestaurants) {
    if (_favoriteDishIds.isEmpty || allRestaurants.isEmpty) {
      return [];
    }
    List<Dish> favoriteDishes = [];
    // Itera por todos os restaurantes para encontrar os pratos favoritos
    for (var restaurant in allRestaurants) {
      favoriteDishes.addAll(
        restaurant.dishes.where((dish) => _favoriteDishIds.contains(dish.id)),
      );
    }
    return favoriteDishes;
  }
}