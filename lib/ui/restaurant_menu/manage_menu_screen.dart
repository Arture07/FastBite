// lib/ui/restaurant_menu/manage_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar preço
import 'package:myapp/data/restaurant_data.dart'; // Provider dos dados
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/ui/_core/auth_provider.dart'; // Para ID do restaurante
import 'package:myapp/ui/restaurant_menu/add_edit_dish_screen.dart'; // Tela de Adicionar/Editar
import 'package:provider/provider.dart';
import 'package:myapp/ui/_core/app_colors.dart'; // Para cores

class ManageMenuScreen extends StatelessWidget {
  const ManageMenuScreen({super.key});

  // Helper para confirmação de remoção de prato
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, Dish dish) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: Text(
            'Tem certeza que deseja remover o prato "${dish.name}" do seu cardápio? Esta ação não pode ser desfeita.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remover'),
              onPressed:
                  () => Navigator.of(context).pop(true), // Confirma remoção
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pega o ID do restaurante logado
    final String? currentRestaurantId = context.select(
      (AuthProvider auth) => auth.currentUser?.id,
    );
    final List<Dish> menuItems =
        context
            .watch<RestaurantData>()
            .listRestaurant
            .firstWhere(
              (r) => r.id == currentRestaurantId,
              orElse:
                  () => Restaurant(
                    id: '',
                    imagePath: '',
                    name: '',
                    description: '',
                    stars: 0,
                    distance: 0,
                    categories: [],
                  ), // Retorna restaurante vazio se não achar
            )
            .dishes;

    // Formatador de moeda
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Cardápio"),
        elevation: 1.0,
        actions: [
          // Botão para adicionar novo prato
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Adicionar Novo Prato",
            // Só habilita se o ID do restaurante for conhecido
            onPressed:
                currentRestaurantId == null
                    ? null
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Navega para AddEditDishScreen em modo ADIÇÃO
                          builder:
                              (context) => AddEditDishScreen(
                                restaurantId: currentRestaurantId,
                              ),
                        ),
                      );
                    },
          ),
        ],
      ),
      body:
          (currentRestaurantId == null)
              // Se não conseguiu identificar o restaurante
              ? const Center(
                child: Text(
                  "Erro: Não foi possível identificar seu restaurante.",
                ),
              )
              // Se o cardápio está vazio
              : menuItems.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Seu cardápio está vazio.",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Adicionar Primeiro Prato"),
                        onPressed: () {
                          // Navega para adicionar prato
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AddEditDishScreen(
                                    restaurantId: currentRestaurantId,
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
              // Exibe a lista de pratos
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final dish = menuItems[index];
                  // Widget Dismissible para permitir arrastar e remover
                  return Dismissible(
                    key: ValueKey(dish.id), // Chave única para identificação
                    direction:
                        DismissDirection
                            .endToStart, // Arrastar da direita para esquerda
                    confirmDismiss:
                        (direction) async =>
                            await _showDeleteConfirmationDialog(context, dish),
                    // Ação quando o usuário confirma a remoção
                    onDismissed: (direction) {
                      // Chama o método do provider para remover o prato
                      context.read<RestaurantData>().removeDishFromRestaurant(
                        currentRestaurantId,
                        dish.id,
                      );
                      // Mostra feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Prato "${dish.name}" removido.'),
                        ),
                      );
                    },
                    // Visual que aparece por baixo ao arrastar
                    background: Container(
                      color: Colors.redAccent[700],
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Row(
                        // Ícone e texto
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Remover",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.delete_sweep_outlined,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    // Conteúdo principal do item (ListTile)
                    child: ListTile(
                      // Imagem (ou ícone) à esquerda
                      key: ValueKey('listTile_${dish.id}'),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          dish.imagePath.isNotEmpty &&
                                  !dish.imagePath.contains('default')
                              ? 'assets/${dish.imagePath}'
                              : 'assets/dishes/default.png', // Usa default se necessário
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.fastfood_outlined,
                                  size: 30,
                                ),
                              ),
                        ),
                      ),
                      // Título (Nome do Prato)
                      title: Text(
                        dish.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      // Subtítulo (Descrição e Preço)
                      subtitle: Text(
                        "${dish.description.substring(0, dish.description.length > 50 ? 50 : dish.description.length)}${dish.description.length > 50 ? '...' : ''}\n"
                        "${currencyFormat.format(dish.price/100)}", // Preço formatado
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      // Ícone/Botão para Editar à direita
                      trailing: IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 22,
                          color: AppColors.mainColor,
                        ), // Ícone de editar
                        tooltip: 'Editar Prato',
                        onPressed: () {
                          // Navega para AddEditDishScreen em modo EDIÇÃO, passando o prato
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AddEditDishScreen(
                                    restaurantId: currentRestaurantId,
                                    dishToEdit: dish,
                                  ),
                            ),
                          );
                        },
                      ),
                      isThreeLine:
                          true, // Permite mais espaço vertical para o subtítulo
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 0,
                      ), // Ajusta padding
                    ),
                  );
                },
                // Divisor entre os itens da lista
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                    ),
              ),
    );
  }
}
