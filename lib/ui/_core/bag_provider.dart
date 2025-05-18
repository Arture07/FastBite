// lib/ui/_core/bag_provider.dart
import 'dart:convert'; // Para jsonEncode/Decode
import 'package:flutter/foundation.dart';
import 'package:myapp/model/dish.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importa SharedPreferences

/// Gerencia o estado da sacola de compras, persistindo localmente
/// usando SharedPreferences para que não se perca ao fechar o app.
class BagProvider extends ChangeNotifier {
  // Chaves para identificar os dados no SharedPreferences
  static const _storageKeyDishes = 'bagDishesJsonList';
  static const _storageKeyRestaurantId = 'bagRestaurantId';

  List<Dish> _dishesOnBag = []; // Lista em memória dos pratos na sacola
  String? _currentRestaurantId; // ID do restaurante dos itens na sacola
  bool _isLoaded = false; // Flag para controlar o carregamento inicial

  // Construtor: Inicia o carregamento da sacola salva ao criar o provider
  BagProvider() {
    debugPrint("BagProvider (SharedPreferences): Inicializando e carregando sacola salva...");
    _loadBagFromPrefs();
  }

  // Getters públicos para a UI acessar os dados de forma segura
  List<Dish> get dishesOnBag => List.unmodifiable(_dishesOnBag);
  String? get currentRestaurantId => _currentRestaurantId;
  bool get isLoaded => _isLoaded; // Permite à UI saber se o carregamento inicial terminou

  // --- Persistência com SharedPreferences ---

  /// Salva o estado atual da sacola (lista de pratos e ID do restaurante)
  /// no SharedPreferences. É chamado após cada modificação na sacola.
  Future<void> _saveBagToPrefs() async {
    // Garante que o carregamento inicial terminou antes de tentar salvar
    if (!_isLoaded) return; 
    try {
      final prefs = await SharedPreferences.getInstance();
      // 1. Converte a lista de objetos Dish para uma lista de Strings JSON
      List<String> dishesJsonList = _dishesOnBag.map((dish) => jsonEncode(dish.toJson())).toList();
      await prefs.setStringList(_storageKeyDishes, dishesJsonList);

      // 2. Salva o ID do restaurante (ou remove a chave se for nulo/sacola vazia)
      if (_currentRestaurantId != null && _dishesOnBag.isNotEmpty) {
        await prefs.setString(_storageKeyRestaurantId, _currentRestaurantId!);
      } else {
        // Garante que o ID é removido se a sacola estiver vazia
        await prefs.remove(_storageKeyRestaurantId);
         // Também garante que o ID interno seja nulo se a sacola estiver vazia
         if (_dishesOnBag.isEmpty) _currentRestaurantId = null;
      }
      debugPrint("BagProvider: Sacola salva no SharedPreferences (Rest: $_currentRestaurantId, Itens: ${_dishesOnBag.length}).");
    } catch (e) {
      debugPrint("BagProvider: Erro ao salvar sacola no SharedPreferences: $e");
      // Considerar logar o erro de forma mais robusta em produção
    }
  }

  /// Carrega o estado da sacola do SharedPreferences.
  /// Chamado uma vez quando o provider é inicializado.
  Future<void> _loadBagFromPrefs() async {
    // Evita recarregar se já foi carregado
    if (_isLoaded) return; 
    try {
      final prefs = await SharedPreferences.getInstance();
      // Carrega a lista de JSONs dos pratos
      final List<String>? dishesJsonList = prefs.getStringList(_storageKeyDishes);
      // Carrega o ID do restaurante
      final String? savedRestaurantId = prefs.getString(_storageKeyRestaurantId);

      // Só restaura a sacola se AMBOS os dados existirem e a lista não for vazia
      if (dishesJsonList != null && dishesJsonList.isNotEmpty && savedRestaurantId != null) {
        // Converte a lista de JSONs de volta para uma lista de objetos Dish
        _dishesOnBag = dishesJsonList.map((dishJson) {
           try {
              // Usa o Dish.fromJson para recriar o objeto Dish
              return Dish.fromJson(jsonDecode(dishJson));
           } catch (e) {
              // Se um item específico falhar na decodificação, loga e pula
              debugPrint("BagProvider: Erro ao decodificar Dish do SharedPreferences: $e. Item ignorado.");
              return null;
           }
        }).whereType<Dish>().toList(); // Filtra quaisquer resultados nulos

        // Define o ID do restaurante carregado
        _currentRestaurantId = savedRestaurantId;

        // Verificação de segurança: se a decodificação falhou para todos os itens, limpa tudo
        if (_dishesOnBag.isEmpty) {
           _currentRestaurantId = null;
           await prefs.remove(_storageKeyDishes);
           await prefs.remove(_storageKeyRestaurantId);
           debugPrint("BagProvider: Lista de pratos ficou vazia após decodificação. Limpando prefs.");
        }

        debugPrint("BagProvider: Sacola carregada do SharedPreferences (Rest: $_currentRestaurantId, Itens: ${_dishesOnBag.length}).");
      } else {
         // Se não havia nada salvo ou faltava o ID, garante que a sacola começa vazia
         _dishesOnBag = [];
         _currentRestaurantId = null;
         debugPrint("BagProvider: Nenhuma sacola válida encontrada no SharedPreferences.");
         // Garante que as chaves sejam removidas se uma delas estiver faltando
         if (dishesJsonList == null) await prefs.remove(_storageKeyDishes);
         if (savedRestaurantId == null) await prefs.remove(_storageKeyRestaurantId);
      }

    } catch (e) {
      debugPrint("BagProvider: Erro CRÍTICO ao carregar sacola do SharedPreferences: $e");
      _dishesOnBag = []; // Garante estado limpo em caso de erro grave
      _currentRestaurantId = null;
    } finally {
       _isLoaded = true; // Marca como carregado (mesmo que vazio ou com erro)
       notifyListeners(); // Notifica a UI que o estado inicial está pronto
    }
  }

  // --- Métodos de Modificação da Sacola (Agora chamam _saveBagToPrefs) ---

  /// Adiciona uma lista de pratos à sacola.
  /// Se a sacola estiver vazia ou os pratos forem do mesmo restaurante, adiciona.
  /// Se forem de um restaurante diferente, limpa a sacola antiga e adiciona os novos.
  void addAllDishes(List<Dish> dishes, String restaurantId) {
    if (dishes.isEmpty) return; // Não faz nada se a lista estiver vazia

    bool bagChanged = false; // Flag para saber se precisa salvar e notificar

    // Cenário 1: Sacola vazia OU adicionando do mesmo restaurante
    if (_dishesOnBag.isEmpty || _currentRestaurantId == restaurantId) {
      _dishesOnBag.addAll(dishes);
      // Define o ID do restaurante se a sacola estava vazia
      if (_currentRestaurantId == null) {
         _currentRestaurantId = restaurantId;
      }
      bagChanged = true;
      debugPrint("BagProvider: Itens adicionados do restaurante $restaurantId.");
    }
    // Cenário 2: Adicionando de um restaurante DIFERENTE
    else {
      debugPrint("BagProvider: Itens de restaurante diferente ($restaurantId vs $_currentRestaurantId). Limpando sacola antiga.");
      _dishesOnBag.clear();       // Limpa a lista em memória
      _dishesOnBag.addAll(dishes); // Adiciona os novos itens
      _currentRestaurantId = restaurantId; // Define o novo ID do restaurante
      bagChanged = true;
      // TODO: Considerar mostrar um SnackBar/Dialog para informar o utilizador que a sacola foi limpa.
    }

    // Se a sacola mudou, notifica a UI e salva o novo estado
    if (bagChanged) {
      notifyListeners();
      _saveBagToPrefs();
    }
  }

  /// Remove UMA ocorrência de um prato específico da sacola.
  void removeDishes(Dish dish) {
    // O método remove() do List retorna true se um elemento foi removido.
    bool removed = _dishesOnBag.remove(dish);

    // Se um item foi realmente removido:
    if (removed) {
      // Se a sacola ficou vazia após a remoção, limpa o ID do restaurante
      if (_dishesOnBag.isEmpty) {
        _currentRestaurantId = null;
        debugPrint("BagProvider: Sacola esvaziada após remover último item.");
      }
      notifyListeners(); // Notifica a UI sobre a mudança
      _saveBagToPrefs(); // Salva o novo estado
      debugPrint("BagProvider: Item ${dish.name} removido.");
    } else {
       debugPrint("BagProvider: Tentativa de remover ${dish.name}, mas não encontrado na sacola.");
    }
  }

  /// Limpa completamente a sacola (remove todos os itens e o ID do restaurante).
  void clearBag() {
    // Só executa a limpeza e notificação se a sacola não estiver já vazia
    if (_dishesOnBag.isNotEmpty) {
       _dishesOnBag.clear();
       _currentRestaurantId = null; // Limpa o ID
       debugPrint("BagProvider: Sacola limpa.");
       notifyListeners(); // Notifica a UI
       _saveBagToPrefs(); // Salva o estado vazio
    } else {
       debugPrint("BagProvider: clearBag chamado, mas a sacola já estava vazia.");
    }
  }

  // --- Métodos Auxiliares (Inalterados) ---

  /// Retorna um mapa onde as chaves são os objetos Dish únicos
  /// e os valores são a quantidade de cada um na sacola.
  Map<Dish, int> getMapByAmount() {
    Map<Dish, int> mapResult = {};
    for (Dish dish in _dishesOnBag) {
      // Usa o próprio objeto Dish como chave (requer que Dish implemente == e hashCode corretamente)
      mapResult[dish] = (mapResult[dish] ?? 0) + 1;
    }
    return mapResult;
  }
}