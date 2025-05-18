import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/ui/_core/app_colors.dart';
import 'package:myapp/ui/_core/bag_provider.dart';
import 'package:myapp/ui/_core/favorites_provider.dart'; // Importar
import 'package:myapp/ui/dish/dish_detail_screen.dart';
import 'package:provider/provider.dart';

class DishCardWidget extends StatelessWidget {
  final Dish dish;
  final String restaurantId;
  const DishCardWidget({
    super.key,
    required this.dish,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final bool isFavorite = favoritesProvider.isDishFavorite(dish.id);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final double cardWidth =
        MediaQuery.of(context).size.width * 0.45; // Largura relativa
    final double cardHeight = 250.0;
    final double imageHeight = cardHeight * 0.55;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Card(
        // Use a cor de fundo clara do seu tema ou outra cor de card
        color: AppColors.lightBackgroundColor,
        clipBehavior:
            Clip.antiAlias, // Garante que a imagem seja cortada pelas bordas arredondadas
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 3.0, // Sombra sutil
        child: InkWell(
          onTap: () {
            // Navega para a tela de detalhes do prato ao clicar no card
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
              // Stack para posicionar o botão de favorito sobre a imagem
              Stack(
                children: [
                  Image.asset(
                    // Usa a imagem específica do prato ou a padrão
                    dish.imagePath.isNotEmpty
                        ? 'assets/${dish.imagePath}'
                        : 'assets/dishes/default.png',
                    height: imageHeight,
                    width: double.infinity, // Ocupa toda a largura do card
                    fit: BoxFit.cover, // Cobre o espaço da imagem
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: imageHeight,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.fastfood_outlined,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                  ),
                  // Botão Favoritar no Canto Superior Direito
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      // Adiciona um fundo semi-transparente para melhor contraste
                      color: Colors.black.withOpacity(0.3),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                          shadows: [
                            // Sombra para melhor visibilidade do ícone branco
                            Shadow(
                              blurRadius: 1.0,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ],
                        ),
                        iconSize: 20, // Tamanho do ícone
                        padding: const EdgeInsets.all(
                          4,
                        ), // Padding interno pequeno
                        constraints:
                            const BoxConstraints(), // Remove constraints padrão para diminuir o touch area
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
              // Informações do prato abaixo da imagem
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  top: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                      maxLines: 2, // Permite até duas linhas para o nome
                      overflow:
                          TextOverflow
                              .ellipsis, // Adiciona '...' se nome for maior
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(dish.price / 100), // <<< DIVIDE POR 100
                      style: const TextStyle(
                      fontSize: 13.0, // Ou o tamanho que você estava usando
                      color: AppColors.mainColor, // Ou Theme.of(context).colorScheme.primary
                      fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  top: 4.0,
                ),
                child: Text(
                  currencyFormat.format(dish.price/100),
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: AppColors.mainColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Spacer para empurrar o botão de adicionar para baixo se houver espaço
              const Spacer(),
              // Botão de adicionar à sacola
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  8.0,
                  0,
                  8.0,
                  8.0,
                ), // Padding só nas laterais e baixo
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.mainColor,
                    ),
                    iconSize: 28,
                    tooltip: 'Adicionar à Sacola',
                    onPressed: () {
                      context.read<BagProvider>().addAllDishes([
                        dish,
                      ], restaurantId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${dish.name} adicionado à sacola!'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppColors.mainColor,
                        ),
                      );
                    },
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
