// lib/ui/restaurant_dashboard/restaurant_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/ui/_core/widgets/app_drawer.dart';
import 'package:provider/provider.dart';

// <<< Importar as novas telas >>>
import 'package:myapp/ui/restaurant_orders/restaurant_orders_screen.dart';
import 'package:myapp/ui/restaurant_menu/manage_menu_screen.dart';
import 'package:myapp/ui/restaurant_profile/edit_restaurant_profile_screen.dart';

class RestaurantDashboardScreen extends StatelessWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final restaurantName = authProvider.currentUser?.name ?? "Restaurante";

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text("Painel - $restaurantName"),
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              // Confirmação de Logout
              bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text("Confirmar Saída"),
                      content: const Text(
                        "Deseja realmente sair da sua conta?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text("Sair"),
                        ),
                      ],
                    ),
              );
              if (confirmLogout == true && context.mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 100,
                color: Colors.grey[500],
              ),
              const SizedBox(height: 24),
              Text(
                "Bem-vindo, $restaurantName!",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Gerencie seus pedidos e cardápio usando o menu lateral ou os atalhos abaixo.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Botões com Navegação
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text("Ver Pedidos"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      // <<< NAVEGAÇÃO: Ver Pedidos >>>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RestaurantOrdersScreen(),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book),
                    label: const Text("Gerenciar Cardápio"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      // <<< NAVEGAÇÃO: Gerenciar Cardápio >>>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageMenuScreen(),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text("Editar Perfil"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      // <<< NAVEGAÇÃO: Editar Perfil >>>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const EditRestaurantProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}