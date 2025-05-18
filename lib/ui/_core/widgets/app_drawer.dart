// lib/ui/_core/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart'; // Necessário para UserRole
// import 'package:myapp/ui/_core/app_colors.dart'; // Usaremos cores do tema
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:provider/provider.dart';

// Importar TODAS as telas que são REALMENTE navegadas a partir daqui
import 'package:myapp/ui/checkout/address_selection_screen.dart';
import 'package:myapp/ui/checkout/payment_selection_screen.dart';
import 'package:myapp/ui/favorites/favorites_screen.dart';
import 'package:myapp/ui/help/help_screen.dart'; // Supondo que você tem esta tela
import 'package:myapp/ui/orders/order_history_screen.dart';
import 'package:myapp/ui/settings/settings_screen.dart';
// Importar telas de restaurante
import 'package:myapp/ui/restaurant_menu/manage_menu_screen.dart';
import 'package:myapp/ui/restaurant_orders/restaurant_orders_screen.dart';
import 'package:myapp/ui/restaurant_profile/edit_restaurant_profile_screen.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Helper para confirmação de Logout
  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context, // Usa o context passado para o showDialog
      builder: (dialogContext) => AlertDialog(
            title: const Text("Confirmar Saída"),
            content: const Text("Deseja realmente sair da sua conta?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Sair"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final User? currentUser = authProvider.currentUser;
    final bool isAuthenticated = authProvider.isAuthenticated;
    final UserRole userRole = currentUser?.role ?? UserRole.client;
    final theme = Theme.of(context); // Pega o tema atual

    debugPrint("AppDrawer Build: isAuthenticated=$isAuthenticated, userRole=$userRole");

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary), // Usa cor do tema
            accountName: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                isAuthenticated ? currentUser?.name ?? 'Utilizador' : 'Bem-vindo!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onPrimary, // Cor de texto sobre primária
                  shadows: const [Shadow(blurRadius: 1, color: Colors.black26)],
                ),
              ),
            ),
            accountEmail: Text(
              isAuthenticated ? currentUser?.email ?? '' : "Faça login ou cadastre-se",
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withAlpha((255 * 0.8).round()),
                shadows: const [Shadow(blurRadius: 1, color: Colors.black26)],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              // <<< CORRIGIDO: withOpacity para withAlpha se for cor customizada, ou usar cor do tema >>>
              backgroundColor: theme.colorScheme.onPrimary.withAlpha((255 * 0.9).round()),
              child: isAuthenticated
                  ? Text(
                      currentUser?.name.isNotEmpty == true ? currentUser!.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    )
                  : Icon(Icons.person_outline, size: 50, color: theme.colorScheme.primary),
            ),
            margin: EdgeInsets.zero,
          ),

          // Itens para CLIENTES
          if (userRole == UserRole.client) ...[
            _buildDrawerItem(
              context: context, // <<< CORRIGIDO: Passando context como nomeado
              icon: Icons.home_outlined,
              text: 'Início (Comprar)',
              onTap: () {
                Navigator.pop(context); // Fecha drawer
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
            ),
            if (isAuthenticated)
              _buildDrawerItem(
                context: context, // <<< CORRIGIDO
                icon: Icons.receipt_long_outlined,
                text: 'Meus Pedidos',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                },
              ),
            if (isAuthenticated)
              _buildDrawerItem(
                context: context, // <<< CORRIGIDO
                icon: Icons.favorite_outline,
                text: 'Meus Favoritos',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                },
              ),
            _buildDrawerItem(
              context: context, // <<< CORRIGIDO
              icon: Icons.location_on_outlined,
              text: 'Meus Endereços',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSelectionScreen()));
              },
            ),
            _buildDrawerItem(
              context: context, // <<< CORRIGIDO
              icon: Icons.credit_card_outlined,
              text: 'Formas de Pagamento',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSelectionScreen()));
              },
            ),
          ],

          // Itens para RESTAURANTES
          if (userRole == UserRole.restaurant && isAuthenticated) ...[
            _buildDrawerItem(
              context: context, // <<< CORRIGIDO
              icon: Icons.dashboard_outlined,
              text: 'Painel do Restaurante',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/restaurant_dashboard', (route) => false);
              },
            ),
            _buildDrawerItem(
              context: context, // <<< CORRIGIDO
              icon: Icons.list_alt_outlined,
              text: 'Pedidos Recebidos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RestaurantOrdersScreen()));
              },
            ),
            _buildDrawerItem(
              context: context, // <<< CORRIGIDO
              icon: Icons.menu_book_outlined,
              text: 'Gerenciar Cardápio',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageMenuScreen()));
              },
            ),
            _buildDrawerItem(
              context: context, // <<< CORRIGIDO
              icon: Icons.storefront_outlined,
              text: 'Perfil do Restaurante',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditRestaurantProfileScreen()));
              },
            ),
          ],

          // Itens Comuns
          const Divider(indent: 16, endIndent: 16, height: 20),
          _buildDrawerItem(
            context: context, // <<< CORRIGIDO
            icon: Icons.settings_outlined,
            text: 'Configurações',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          _buildDrawerItem(
            context: context, // <<< CORRIGIDO
            icon: Icons.help_outline,
            text: 'Ajuda & Suporte',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 20),

          // Botão Login/Logout
          isAuthenticated
              ? _buildDrawerItem(
                  context: context, // <<< CORRIGIDO
                  icon: Icons.logout,
                  text: 'Sair',
                  onTap: () async {
                    final navigator = Navigator.of(context); 
                    final auth = context.read<AuthProvider>();

                    if (navigator.canPop()) {
                       navigator.pop(); // Fecha o drawer primeiro
                    }
                    
                    // Usa o context da build do AppDrawer para o diálogo
                    bool? confirm = await _confirmLogout(context); 
                    
                    if (confirm == true) {
                      // Não precisa de 'mounted' check para context.read
                      await auth.logout();
                    }
                  },
                )
              : _buildDrawerItem(
                  context: context, // <<< CORRIGIDO
                  icon: Icons.login,
                  text: 'Entrar / Cadastrar',
                  onTap: () {
                    Navigator.pop(context); // Fecha drawer
                    Navigator.pushNamed(context, '/login');
                  },
                ),
        ],
      ),
    );
  }

  // Helper _buildDrawerItem
  Widget _buildDrawerItem({
    required BuildContext context, // Mantém context como parâmetro nomeado
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    final theme = Theme.of(context); // Pega o tema para cores
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(text, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface) ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      minLeadingWidth: 30,
    );
  }
}
