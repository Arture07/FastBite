// lib/ui/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/data/categories_data.dart';
import 'package:myapp/data/restaurant_data.dart'; // Provider com a lógica de filtro
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/ui/_core/widgets/appbar.dart';
import 'package:myapp/ui/_core/widgets/app_drawer.dart';
// import 'package:myapp/ui/_core/app_colors.dart'; // Usar cores do tema
import 'package:myapp/ui/home/widgets/category_widgets.dart';
import 'package:myapp/ui/home/widgets/restaurant_widget.dart';
import 'package:myapp/ui/home/widgets/popular_dish_card.dart';
import 'package:myapp/ui/home/widgets/vertical_dish_list_item.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controlador para o campo de busca
  final TextEditingController _searchController = TextEditingController();
  // Variável LOCAL apenas para o ESTADO VISUAL do botão de categoria selecionado
  String? _uiSelectedCategory;

  @override
  void initState() {
    super.initState();
    // Adiciona listener para chamar o filtro do provider quando a busca mudar
    _searchController.addListener(_onSearchChanged);

    // Garante que o provider de dados seja inicializado se ainda não foi.
    // O ideal é carregar no main.dart, mas isso serve como fallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantDataProvider = context.read<RestaurantData>();
      // Chama loadRestaurants apenas se ainda não foi carregado
      if (!restaurantDataProvider.isLoaded) {
        restaurantDataProvider.loadRestaurants().then((_) {
          // Opcional: Aplicar filtro inicial se searchController ou _uiSelectedCategory já tiverem valor
          if (_searchController.text.isNotEmpty || _uiSelectedCategory != null) {
            restaurantDataProvider.applyFilters(
              category: _uiSelectedCategory,
              query: _searchController.text,
            );
          }
        }).catchError((error) {
           debugPrint("Erro no carregamento inicial em HomeScreen: $error");
           // Mostrar um erro para o usuário se necessário
        });
      } else {
        // Se já carregado, garante que o filtro inicial reflete o estado atual dos controllers
         restaurantDataProvider.applyFilters(
              category: _uiSelectedCategory,
              query: _searchController.text,
            );
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Chamado quando o texto de busca muda
  void _onSearchChanged() {
    // Informa o provider sobre a nova busca e a categoria atualmente selecionada no UI
    context.read<RestaurantData>().applyFilters(
          category: _uiSelectedCategory, // Usa o estado local do UI para a categoria
          query: _searchController.text,
        );
  }

  // Chamado quando um botão de categoria é clicado
  void _onCategoryTap(String category) {
    debugPrint("--- _onCategoryTap CALLED with category: $category ---"); // Log de clique
    final newSelectedCategory = (_uiSelectedCategory == category) ? null : category;

    // 1. ATUALIZA ESTADO LOCAL (para o visual do botão de categoria)
    if (mounted && _uiSelectedCategory != newSelectedCategory) {
      setState(() {
        _uiSelectedCategory = newSelectedCategory;
      });
    }

    // 2. INFORMA O PROVIDER sobre a mudança no filtro de categoria
    context.read<RestaurantData>().applyFilters(
          category: newSelectedCategory, // Passa a NOVA categoria selecionada/deselecionada
          query: _searchController.text, // Passa a busca atual também
        );
  }

  // Helper para construir os títulos das seções
  Widget _buildSectionTitle(BuildContext context, String title) { // Passa context
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface, // Usa cor do tema
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ouve o provider para obter os resultados e o estado do filtro
    final restaurantData = context.watch<RestaurantData>();
    final theme = Theme.of(context); // Pega o tema atual
    final colorScheme = theme.colorScheme; // Pega o esquema de cores

    // Pega os dados filtrados e o estado do filtro diretamente do provider
    final List<Restaurant> restaurantsToShow = restaurantData.filteredRestaurantsResult;
    final List<MapEntry<String, Dish>> dishesToShow = restaurantData.filteredDishesResult;
    final String? activeCategoryFilterFromProvider = restaurantData.activeCategoryFilter;
    final bool isAnyFilterActiveFromProvider = restaurantData.isFilterActive;
    final String currentSearchQuery = restaurantData.activeSearchQuery ?? "";

    final List<MapEntry<String, Dish>> discoverDishes = restaurantData.allDishesForDiscovery;
        // Opcional: Limitar o número de pratos a serem exibidos nesta seção
        final List<MapEntry<String, Dish>> limitedDiscoverDishes = discoverDishes.take(6).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // --- AppBar ---
          SliverAppBar(
            title: Image.asset('assets/logo.png', height: 120),
            centerTitle: true,
            floating: true,
            snap: true,
            elevation: 1.0,
            actions: [...?getAppBar(context: context).actions],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // --- Seção Boas Vindas e Busca ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Boas vindas!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.8), // Cor do tema
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: colorScheme.onSurface), // Cor do tema
                    decoration: InputDecoration(
                      hintText: 'Buscar restaurante ou prato...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)), // Cor do tema
                      prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)), // Cor do tema
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: colorScheme.onSurface.withOpacity(0.6)), // Cor do tema
                              tooltip: "Limpar busca",
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      // Cor de fundo baseada no tema
                      fillColor: theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Seção Categorias ---
          SliverToBoxAdapter(child: _buildSectionTitle(context, "Escolha por categoria")), // Passa context
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110, // Altura da lista horizontal
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                scrollDirection: Axis.horizontal,
                itemCount: CategoriesData.listCategories.length,
                itemBuilder: (context, index) {
                  final category = CategoriesData.listCategories[index];
                  return CategoryWidgets(
                    category: category,
                    isSelected: _uiSelectedCategory == category, // Usa estado LOCAL para o visual
                    onTap: () => _onCategoryTap(category), // Chama método LOCAL
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 12),
              ),
            ),
          ),

          // --- Banner Promocional ---
          if (activeCategoryFilterFromProvider == null) // Usa estado do PROVIDER
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              sliver: SliverToBoxAdapter(
                child: InkWell(
                  onTap: () { /* Navegação do banner */ },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.asset("assets/banners/banner_promo.png", fit: BoxFit.cover),
                  ),
                ),
              ),
            ),

          if (!isAnyFilterActiveFromProvider && limitedDiscoverDishes.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildSectionTitle(context, "Descubra Novos Sabores")),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 colunas
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 0.55, // Ajuste para o tamanho do seu card
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = limitedDiscoverDishes[index];
                        final restaurantId = entry.key;
                        final dish = entry.value;
                        // Pode usar PopularDishCard ou um card específico para grid
                        return PopularDishCard(dish: dish, restaurantId: restaurantId);
                      },
                      childCount: limitedDiscoverDishes.length,
                    ),
                  ),
                ),
              ],

          // --- Título Dinâmico da Seção de Resultados ---
          SliverToBoxAdapter(
            child: _buildSectionTitle(context, // Passa context
              activeCategoryFilterFromProvider != null
                  ? 'Pratos de "$activeCategoryFilterFromProvider"${currentSearchQuery.isNotEmpty ? ' contendo "$currentSearchQuery"' : ''}'
                  : (isAnyFilterActiveFromProvider
                      ? "Resultados da busca por \"$currentSearchQuery\""
                      : "Restaurantes Próximos"),
            ),
          ),

          // --- Lista de Resultados (Pratos OU Restaurantes) ---
          // A lógica aqui usa os dados corretos do provider
          if (activeCategoryFilterFromProvider != null) ...[ // MODO PRATOS
            if (dishesToShow.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                    child: Text(
                      "Nenhum prato encontrado para \"$activeCategoryFilterFromProvider\"${currentSearchQuery.isNotEmpty ? ' na busca \"$currentSearchQuery\"' : ''}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 16), // Cor do tema
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 64.0), // Padding inferior maior
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = dishesToShow[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0), // Espaçamento entre itens
                        child: VerticalDishListItem(dish: entry.value, restaurantId: entry.key),
                      );
                    },
                    childCount: dishesToShow.length,
                  ),
                ),
              ),
          ] else ...[ // MODO RESTAURANTES
            if (isAnyFilterActiveFromProvider && restaurantsToShow.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                    child: Text(
                      "Nenhum restaurante ou prato encontrado para \"$currentSearchQuery\"",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 16), // Cor do tema
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 64.0), // Padding inferior maior
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final restaurant = restaurantsToShow[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0), // Espaçamento entre itens
                        child: RestaurantWidget(restaurant: restaurant),
                      );
                    },
                    childCount: restaurantsToShow.length,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
