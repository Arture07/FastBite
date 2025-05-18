// lib/ui/home/widgets/popular_dish_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/ui/_core/app_colors.dart';
import 'package:myapp/ui/_core/bag_provider.dart';
import 'package:myapp/ui/_core/favorites_provider.dart';
import 'package:myapp/ui/dish/dish_detail_screen.dart';
import 'package:provider/provider.dart';

// Card para exibir pratos populares/destaque na HomeScreen
class PopularDishCard extends StatelessWidget {
  final Dish dish;
  final String
  restaurantId; // Necessário para adicionar à sacola e ir aos detalhes

  const PopularDishCard({
    super.key,
    required this.dish,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFavorite = favoritesProvider.isDishFavorite(dish.id);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    // Definir dimensões do card
    final double cardWidth =
        MediaQuery.of(context).size.width * 0.7; // Card maior
    final double cardHeight = 320.0; // Altura total
    final double imageHeight = cardHeight * 0.40; // Imagem ocupa boa parte

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Card(
        color: AppColors.lightBackgroundColor, // Cor de fundo
        clipBehavior: Clip.antiAlias, // Corta imagem
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 3.0,
        child: InkWell(
          // Card clicável para ir aos detalhes
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DishDetailScreen(
                      dish: dish,
                      restaurantId: restaurantId,
                    ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Imagem e Botão Favoritar ---
              Stack(
                children: [
                  // Imagem
                  Image.asset(
                    dish.imagePath.isNotEmpty
                        ? 'assets/${dish.imagePath}'
                        : 'assets/dishes/default.png',
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: imageHeight,
                          color: Colors.grey[800],
                          child: Center(
                            child: Icon(
                              Icons.restaurant_menu,
                              color: Colors.grey[600],
                              size: 40,
                            ),
                          ),
                        ),
                  ),
                  // Botão Favoritar
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withOpacity(0.4),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 1.0,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ],
                        ),
                        iconSize: 18,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        tooltip:
                            isFavorite
                                ? 'Remover dos Favoritos'
                                : 'Adicionar aos Favoritos',
                        onPressed: () {
                          context.read<FavoritesProvider>().toggleDishFavorite(
                            dish.id,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // --- Informações e Botão Adicionar ---
              Expanded(
                // Ocupa o espaço restante
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween, // Espaça nome/descrição e preço/botão
                    children: [
                      // Nome e Descrição Curta
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dish.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dish.description,
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Colors.grey[400],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Preço e Botão Adicionar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currencyFormat.format(dish.price/100),
                            style: const TextStyle(
                              fontSize: 15.0,
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              context.read<BagProvider>().addAllDishes([
                                dish,
                              ], restaurantId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${dish.name} adicionado à sacola!',
                                  ) /*...*/,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(8),
                              backgroundColor: AppColors.mainColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(33, 33),
                            ), // Botão um pouco maior
                            child: const Icon(Icons.add, size: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
