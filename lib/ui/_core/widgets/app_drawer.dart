// lib/ui/_core/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Importar

// Importar TODAS as telas que são REALMENTE navegadas a partir daqui
import 'package:myapp/ui/checkout/address_selection_screen.dart';
import 'package:myapp/ui/checkout/payment_selection_screen.dart';
import 'package:myapp/ui/favorites/favorites_screen.dart';
import 'package:myapp/ui/help/help_screen.dart';
import 'package:myapp/ui/orders/order_history_screen.dart';
import 'package:myapp/ui/settings/settings_screen.dart';
import 'package:myapp/ui/profile/edit_client_profile_screen.dart'; // Para perfil do cliente
import 'package:myapp/ui/restaurant_menu/manage_menu_screen.dart';
import 'package:myapp/ui/restaurant_orders/restaurant_orders_screen.dart';
import 'package:myapp/ui/restaurant_profile/edit_restaurant_profile_screen.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
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
    final theme = Theme.of(context);

    debugPrint("AppDrawer Build: isAuthenticated=$isAuthenticated, userRole=$userRole, userImagePath=${currentUser?.userImagePath}");

    ImageProvider? profileImageProvider;
    if (currentUser?.userImagePath != null && currentUser!.userImagePath!.isNotEmpty) {
      if (currentUser.userImagePath!.startsWith('http')) {
        profileImageProvider = CachedNetworkImageProvider(currentUser.userImagePath!);
      } else if (currentUser.userImagePath!.startsWith('assets/')) {
        // Se for um caminho de asset completo
        profileImageProvider = AssetImage(currentUser.userImagePath!);
      } else {
        // Se for apenas o nome do arquivo dentro de uma pasta de assets padrão
        profileImageProvider = AssetImage('assets/${currentUser.userImagePath!}');
      }
    } else {
      profileImageProvider = const AssetImage('assets/user_placeholder.png'); // Fallback
    }


    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            accountName: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                isAuthenticated ? currentUser?.name ?? 'Utilizador' : 'Bem-vindo!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onPrimary,
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
              key: ValueKey(currentUser?.userImagePath ?? currentUser?.id ?? 'default_avatar_key'), // Chave para forçar rebuild
              radius: 35, 
              backgroundColor: theme.colorScheme.onPrimary.withAlpha(200),
              backgroundImage: profileImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                // Fallback se CachedNetworkImageProvider ou AssetImage falhar
                debugPrint("Erro ao carregar imagem de perfil no Drawer: $exception");
                // Não precisa de setState aqui, o child será mostrado
              },
              child: (profileImageProvider == null || (profileImageProvider is AssetImage && profileImageProvider.assetName == 'assets/user_placeholder.png'))
                  ? Text( // Mostra inicial apenas se for placeholder ou erro
                      currentUser?.name.isNotEmpty == true ? currentUser!.name[0].toUpperCase() : 'U',
                      style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    )
                  : null,
            ),
            margin: EdgeInsets.zero,
          ),

          // Itens para CLIENTES
          if (userRole == UserRole.client) ...[
            _buildDrawerItem(
              context: context,
              icon: Icons.home_outlined,
              text: 'Início (Comprar)',
              onTap: () {
                Navigator.pop(context); 
                // Decide se a HomeScreen já está na pilha ou precisa de pushReplacementNamed
                if (ModalRoute.of(context)?.settings.name != '/home') {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                }
              },
            ),
            if (isAuthenticated)
              _buildDrawerItem(
                context: context,
                icon: Icons.person_outline, // Ícone para perfil
                text: 'Meu Perfil',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditClientProfileScreen()));
                },
              ),
            if (isAuthenticated)
              _buildDrawerItem(
                context: context,
                icon: Icons.receipt_long_outlined,
                text: 'Meus Pedidos',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                },
              ),
            if (isAuthenticated)
              _buildDrawerItem(
                context: context,
                icon: Icons.favorite_outline,
                text: 'Meus Favoritos',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                },
              ),
            _buildDrawerItem(
              context: context,
              icon: Icons.location_on_outlined,
              text: 'Meus Endereços',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSelectionScreen()));
              },
            ),
            _buildDrawerItem(
              context: context,
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
              context: context,
              icon: Icons.dashboard_outlined,
              text: 'Painel do Restaurante',
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != '/restaurant_dashboard') {
                   Navigator.pushNamedAndRemoveUntil(context, '/restaurant_dashboard', (route) => false);
                }
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.storefront_outlined, // Ícone para perfil do restaurante
              text: 'Perfil do Restaurante',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditRestaurantProfileScreen()));
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.list_alt_outlined,
              text: 'Pedidos Recebidos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RestaurantOrdersScreen()));
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.menu_book_outlined,
              text: 'Gerenciar Cardápio',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageMenuScreen()));
              },
            ),
          ],

          // Itens Comuns
          const Divider(indent: 16, endIndent: 16, height: 20),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings_outlined,
            text: 'Configurações',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
          _buildDrawerItem(
            context: context,
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
                  context: context,
                  icon: Icons.logout,
                  text: 'Sair',
                  onTap: () async {
                    // Captura o Navigator ANTES do await para o diálogo
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) { // Fecha o drawer
                       navigator.pop();
                    }
                    
                    bool? confirm = await _confirmLogout(context); 
                    
                    if (confirm == true) {
                      // Não precisa de 'mounted' check para context.read
                      // O AuthProvider.logout() chamará notifyListeners, e o MainAppWrapper cuidará da navegação.
                      await context.read<AuthProvider>().logout();
                    }
                  },
                )
              : _buildDrawerItem(
                  context: context,
                  icon: Icons.login,
                  text: 'Entrar / Cadastrar',
                  onTap: () {
                    Navigator.pop(context); 
                    Navigator.pushNamed(context, '/login');
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    final theme = Theme.of(context);
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
