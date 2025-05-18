// lib/ui/favorites/favorites_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/ui/_core/favorites_provider.dart';
import 'package:myapp/ui/_core/widgets/appbar.dart'; // Usa o AppBar global
import 'package:myapp/ui/home/widgets/restaurant_widget.dart';
import 'package:myapp/ui/home/widgets/vertical_dish_list_item.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final restaurantData = context.watch<RestaurantData>();
    final theme = Theme.of(context); // Pega o tema

    final List<Restaurant> favRestaurants = favoritesProvider.getFavoriteRestaurants(restaurantData.listRestaurant);
    final List<MapEntry<String, Dish>> flatFavDishes = favoritesProvider
        .getFavoriteDishes(restaurantData.listRestaurant)
        .map((dish) {
          String restaurantId = 'unknown_restaurant';
          try {
            final restaurantOwner = restaurantData.listRestaurant.firstWhere(
              (r) => r.dishes.any((d) => d.id == dish.id)
            );
            restaurantId = restaurantOwner.id;
          } catch (e) {
            debugPrint("FavoritesScreen: Não foi possível encontrar o restaurante para o prato favorito ${dish.name}");
          }
          return MapEntry(restaurantId, dish);
        }).toList();

    return DefaultTabController(
      length: 2, // Duas abas
      child: Scaffold(
        appBar: getAppBar(
          context: context,
          title: "Meus Favoritos",
          // <<< CORRIGIDO: Usa o parâmetro 'bottom' do AppBar >>>
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3.0, // Deixa o indicador um pouco mais grosso
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront_outlined, size: 20),
                    SizedBox(width: 8),
                    Text("Restaurantes"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fastfood_outlined, size: 20),
                    SizedBox(width: 8),
                    Text("Pratos"),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Aba Restaurantes
            _buildRestaurantList(context, favRestaurants),
            // Aba Pratos
            _buildDishList(context, flatFavDishes),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantList(BuildContext context, List<Restaurant> favRestaurants) {
    if (favRestaurants.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text("Nenhum restaurante favorito ainda.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text("Explore e toque no ♡ para salvar.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: favRestaurants.length,
      itemBuilder: (context, index) {
        return RestaurantWidget(restaurant: favRestaurants[index]);
      },
      separatorBuilder: (context, index) => const Divider(height: 16, thickness: 0.5, indent: 16, endIndent: 16),
    );
  }

  Widget _buildDishList(BuildContext context, List<MapEntry<String, Dish>> favDishesWithId) {
    if (favDishesWithId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ramen_dining_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text("Nenhum prato favorito ainda.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text("Explore os cardápios e toque no ♡.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: favDishesWithId.length,
      itemBuilder: (context, index) {
        final entry = favDishesWithId[index];
        return VerticalDishListItem(dish: entry.value, restaurantId: entry.key);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16),
    );
  }
}
