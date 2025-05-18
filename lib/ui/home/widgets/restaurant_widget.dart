import 'package:flutter/material.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/ui/_core/favorites_provider.dart'; // Importar
import 'package:myapp/ui/restaurant/restaurant_screen.dart';
import 'package:provider/provider.dart'; // Importar Provider

class RestaurantWidget extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantWidget({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    // Ouve o FavoritesProvider para saber o estado do botão e reconstruir se mudar
    final favoritesProvider = context.watch<FavoritesProvider>();
    final bool isFavorite = favoritesProvider.isRestaurantFavorite(
      restaurant.id,
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              // Passa o objeto restaurante completo para a próxima tela
              return RestaurantScreen(restaurant: restaurant);
            },
          ),
        );
      },
      child: Padding(
        // Adicionar padding externo se necessário
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Alinha itens no topo
          children: [
            ClipRRect(
              // Para ter bordas arredondadas na imagem
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                'assets/${restaurant.imagePath}', // Certifique-se que o caminho está correto
                width: 72,
                height: 72, // Manter altura consistente
                fit: BoxFit.cover, // Garante que a imagem preencha o espaço
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      // Fallback se imagem não carregar
                      width: 72,
                      height: 72,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12.0), // Espaçamento entre imagem e texto
            Expanded(
              // Para que a coluna de texto ocupe o espaço restante
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0), // Pequeno espaço
                  Row(
                    children: [
                      // Gera as estrelas dinamicamente
                      ...List.generate(restaurant.stars.floor(), (index) {
                        return Image.asset(
                          'assets/others/star.png',
                          width: 16.0,
                        );
                      }),
                      // Adiciona meia estrela se necessário (ex: 4.5 estrelas)
                      if (restaurant.stars % 1 >= 0.5)
                        Image.asset(
                          'assets/others/star.png',
                          width: 16.0,
                        ), // Precisa ter essa imagem
                      // Adiciona estrelas vazias para completar 5 (opcional)
                      ...List.generate(5 - restaurant.stars.ceil(), (index) {
                        return Image.asset(
                          'assets/others/star.png',
                          width: 16.0,
                        ); // Precisa ter essa imagem
                      }),
                      const SizedBox(width: 4.0),
                      Text(
                        restaurant.stars.toStringAsFixed(
                          1,
                        ), // Mostra a nota exata
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    "${restaurant.distance} km", // Adicionar unidade de medida é bom
                    style: TextStyle(fontSize: 13.0, color: Colors.grey[700]),
                  ),
                  // Adicionar tipo de culinária ou preço médio se tiver
                  // Text(restaurant.categories.join(', '), style: TextStyle(fontSize: 12.0, color: Colors.blueGrey)),
                ],
              ),
            ),
            // Botão de Favoritar alinhado à direita
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color:
                    isFavorite
                        ? Colors.redAccent
                        : Colors.grey[400], // Cores do botão
                size: 24, // Tamanho do ícone
              ),
              tooltip:
                  isFavorite
                      ? 'Remover dos Favoritos'
                      : 'Adicionar aos Favoritos',
              // Usa context.read dentro de callbacks para executar a ação sem ouvir mudanças
              onPressed: () {
                context.read<FavoritesProvider>().toggleRestaurantFavorite(
                  restaurant.id,
                );
                // Opcional: Mostrar um SnackBar rápido
                // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //   content: Text(isFavorite ? '${restaurant.name} removido dos favoritos.' : '${restaurant.name} adicionado aos favoritos.'),
                //   duration: Duration(seconds: 1),
                // ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
