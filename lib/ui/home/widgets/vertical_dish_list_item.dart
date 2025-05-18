import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/ui/_core/app_colors.dart';
import 'package:myapp/ui/_core/bag_provider.dart';
import 'package:myapp/ui/_core/favorites_provider.dart';
import 'package:myapp/ui/dish/dish_detail_screen.dart';
import 'package:provider/provider.dart';

class VerticalDishListItem extends StatelessWidget {
  final Dish dish;
  final String restaurantId;
  const VerticalDishListItem({
    super.key,
    required this.dish,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final bool isFavorite = favoritesProvider.isDishFavorite(dish.id);
    final double cardHeight = 150.0; // Altura do card vertical
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return InkWell(
      onTap: () {
        // Navega para detalhes ao clicar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DishDetailScreen(dish: dish, restaurantId: restaurantId),
          ),
        );
      },
      child: SizedBox(
        // Controla a altura do item
        height: cardHeight,
        child: Card(
          clipBehavior: Clip.antiAlias, // Corta os filhos pelas bordas
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2.0,
          color: AppColors.lightBackgroundColor, // Cor de fundo do card
          child: Row(
            // Layout principal: Imagem à esquerda, texto/botões à direita
            children: [
              // --- Imagem ---
              Stack(
                children: [
                  Image.asset(
                    dish.imagePath.isNotEmpty
                        ? 'assets/${dish.imagePath}'
                        : 'assets/dishes/default.png',
                    width:
                        cardHeight, // Largura igual à altura para ser quadrado
                    height: cardHeight,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: cardHeight,
                          height: cardHeight,
                          color: Colors.grey[800],
                          child: Center(
                            child: Icon(
                              Icons.restaurant_menu,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          ),
                        ),
                  ),
                  // Botão Favoritar sobre a imagem
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withOpacity(0.4),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                        ),
                        iconSize: 16,
                        padding: const EdgeInsets.all(3),
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
              // --- Textos e Botão Adicionar ---
              Expanded(
                // Ocupa o espaço restante
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Distribui espaço: nome/descrição em cima, preço/botão embaixo
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Nome e Descrição
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize:
                            MainAxisSize
                                .min, // Para não ocupar espaço extra verticalmente
                        children: [
                          Text(
                            dish.name,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            dish.description,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.grey[400],
                            ),
                            maxLines: 3, // Limita descrição a 2 linhas
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Preço e Botão Adicionar
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween, // Preço na esquerda, botão na direita
                        crossAxisAlignment:
                            CrossAxisAlignment.end, // Alinha na base
                        children: [
                          Text(
                            currencyFormat.format(dish.price / 100), // <<< DIVIDE POR 100
                            style: const TextStyle(
                            fontSize: 13.0, // Ou o tamanho que você estava usando
                            color: AppColors.mainColor, // Ou Theme.of(context).colorScheme.primary
                            fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Botão Adicionar (+)
                          ElevatedButton(
                            onPressed: () {
                              context.read<BagProvider>().addAllDishes([
                                dish,
                              ], restaurantId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${dish.name} adicionado à sacola!',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: AppColors.mainColor,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(6), // Padding menor
                              backgroundColor: AppColors.mainColor,
                              foregroundColor: Colors.white,
                              minimumSize: Size(
                                32,
                                32,
                              ), // Tamanho mínimo do botão
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                            ), // Ícone menor
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
