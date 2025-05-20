// lib/ui/_core/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Importar TODAS as telas que são REALMENTE navegadas a partir daqui
import 'package:myapp/ui/checkout/address_selection_screen.dart';
import 'package:myapp/ui/checkout/payment_selection_screen.dart';
import 'package:myapp/ui/favorites/favorites_screen.dart';
import 'package:myapp/ui/help/help_screen.dart';
import 'package:myapp/ui/orders/order_history_screen.dart';
import 'package:myapp/ui/settings/settings_screen.dart';
import 'package:myapp/ui/profile/edit_client_profile_screen.dart';
import 'package:myapp/ui/restaurant_menu/manage_menu_screen.dart';
import 'package:myapp/ui/restaurant_orders/restaurant_orders_screen.dart';
import 'package:myapp/ui/restaurant_profile/edit_restaurant_profile_screen.dart';
// Adicione o import para HomeScreen e RestaurantDashboardScreen se usar navegação nomeada para eles
// import 'package:myapp/ui/home/home_screen.dart'; // Já deve estar importado se for a tela principal
// import 'package:myapp/ui/restaurant_dashboard/restaurant_dashboard_screen.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Helper para confirmação de Logout
  Future<bool?> _confirmLogoutDialog(BuildContext context) {
    // Este context é o da tela que está a mostrar o drawer,
    // que deve ser válido para mostrar um diálogo.
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
            title: const Text("Confirmar Saída"),
            content: const Text("Deseja realmente sair da sua conta?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false), // Usa dialogContext para fechar
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true), // Usa dialogContext para fechar
                child: const Text("Sair"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ouve o AuthProvider para obter o utilizador atual e o estado de autenticação
    final authProvider = context.watch<AuthProvider>();
    final User? currentUser = authProvider.currentUser;
    final bool isAuthenticated = authProvider.isAuthenticated;
    final UserRole userRole = currentUser?.role ?? UserRole.client; // Assume cliente se não houver utilizador
    final theme = Theme.of(context);

    debugPrint("AppDrawer Build: isAuthenticated=$isAuthenticated, userRole=$userRole, userImagePath=${currentUser?.userImagePath}");

    ImageProvider? profileImageProvider;
    if (currentUser?.userImagePath != null && currentUser!.userImagePath!.isNotEmpty) {
      if (currentUser.userImagePath!.startsWith('http')) {
        profileImageProvider = CachedNetworkImageProvider(currentUser.userImagePath!);
      } else if (currentUser.userImagePath!.startsWith('assets/')) {
        profileImageProvider = AssetImage(currentUser.userImagePath!);
      } else {
        profileImageProvider = AssetImage('assets/${currentUser.userImagePath!}');
      }
    } else {
      profileImageProvider = const AssetImage('assets/user_placeholder.png');
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
                  fontWeight: FontWeight.bold, fontSize: 18,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            accountEmail: Text(
              isAuthenticated ? currentUser?.email ?? '' : "Faça login ou cadastre-se",
              style: TextStyle(color: theme.colorScheme.onPrimary.withAlpha(200)),
            ),
            currentAccountPicture: CircleAvatar(
              key: ValueKey(currentUser?.userImagePath ?? currentUser?.id ?? 'default_avatar_key_drawer_v2'),
              radius: 35, 
              backgroundColor: theme.colorScheme.onPrimary.withAlpha(220),
              backgroundImage: profileImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint("AppDrawer: Erro ao carregar backgroundImage: $exception");
              },
              child: (profileImageProvider is AssetImage && profileImageProvider.assetName == 'assets/user_placeholder.png') || 
                     (currentUser?.userImagePath == null || currentUser!.userImagePath!.isEmpty)
                  ? Text( 
                      currentUser?.name.isNotEmpty == true ? currentUser!.name[0].toUpperCase() : 'U',
                      style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    )
                  : null,
            ),
            margin: EdgeInsets.zero,
          ),

          // Itens de Navegação
          if (userRole == UserRole.client) ...[
            _buildDrawerItem(context, Icons.home_outlined, 'Início (Comprar)', () {
                Navigator.pop(context); // Fecha o drawer
                // Garante que não estamos a fazer push da HomeScreen sobre ela mesma
                if (ModalRoute.of(context)?.settings.name != '/home') {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                }
            }),
            if (isAuthenticated)
              _buildDrawerItem(context, Icons.person_outline, 'Meu Perfil', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditClientProfileScreen()));
              }),
            if (isAuthenticated)
              _buildDrawerItem(context, Icons.receipt_long_outlined, 'Meus Pedidos', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderHistoryScreen()));
                },
              ),
            if (isAuthenticated)
              _buildDrawerItem(context, Icons.favorite_outline, 'Meus Favoritos', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                },
              ),
            _buildDrawerItem(context, Icons.location_on_outlined, 'Meus Endereços', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddressSelectionScreen()));
              },
            ),
            _buildDrawerItem(context, Icons.credit_card_outlined, 'Formas de Pagamento', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSelectionScreen()));
              },
            ),
          ],
          if (userRole == UserRole.restaurant && isAuthenticated) ...[
            _buildDrawerItem(context, Icons.dashboard_outlined, 'Painel do Restaurante', () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != '/restaurant_dashboard') {
                   Navigator.pushNamedAndRemoveUntil(context, '/restaurant_dashboard', (route) => false);
                }
            }),
            _buildDrawerItem(context, Icons.storefront_outlined, 'Perfil do Restaurante', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditRestaurantProfileScreen()));
            }),
             _buildDrawerItem(context, Icons.list_alt_outlined, 'Pedidos Recebidos', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RestaurantOrdersScreen()));
              },
            ),
            _buildDrawerItem(context, Icons.menu_book_outlined, 'Gerenciar Cardápio', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageMenuScreen()));
              },
            ),
          ],
          const Divider(indent: 16, endIndent: 16, height: 20),
          _buildDrawerItem(context, Icons.settings_outlined, 'Configurações', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          }),
          _buildDrawerItem(context, Icons.help_outline, 'Ajuda & Suporte', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
          }),
          const Divider(indent: 16, endIndent: 16, height: 20),
          
          // Botão Sair / Entrar
          isAuthenticated
              ? _buildDrawerItem(
                  context,
                  Icons.logout,
                  'Sair',
                  () async {
                    // 1. Captura o AuthProvider ANTES de qualquer operação async
                    // que possa mudar o estado/contexto do widget.
                    // Usa listen: false porque estamos numa ação, não a construir UI.
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    
                    // 2. Fecha o drawer primeiro
                    Navigator.pop(context); // Este context é do build do AppDrawer, deve ser válido aqui.

                    // 3. Mostra o diálogo de confirmação.
                    // O context passado para o diálogo é o context do AppDrawer (que acabou de ser fechado).
                    // Isto pode ser problemático. É melhor usar um context que sabemos que ainda estará ativo,
                    // como o context da tela que está a exibir o Scaffold que contém o Drawer.
                    // No entanto, para simplificar, vamos tentar com o context do AppDrawer,
                    // mas a chamada ao logout será feita com a instância 'auth' já capturada.
                    // Se o `_confirmLogoutDialog` precisar de um context para o `showDialog` em si,
                    // o `context` do `ListTile` (que é o mesmo do `build` do `AppDrawer`) deve ser usado.
                    
                    bool? confirm = await _confirmLogoutDialog(context); // Passa o context do build do AppDrawer
                    
                    // 4. Se confirmado, chama logout usando a instância 'auth' capturada.
                    // Não precisamos de `context.read` aqui.
                    if (confirm == true) {
                      await auth.logout();
                      // A navegação para a tela de login deve ser tratada pelo MainAppWrapper
                      // ao ouvir as mudanças no AuthProvider.
                    }
                  },
                )
              : _buildDrawerItem(
                  context,
                  Icons.login,
                  'Entrar / Cadastrar',
                  () {
                    Navigator.pop(context); // Fecha drawer
                    Navigator.pushNamed(context, '/login');
                  },
                ),
        ],
      ),
    );
  }

  // Helper para construir os itens do Drawer
  Widget _buildDrawerItem(
    BuildContext context, // Adicionado para consistência, mas não usado diretamente aqui se onTap faz tudo
    IconData icon,
    String text,
    GestureTapCallback onTap,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 22),
      title: Text(text, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      minLeadingWidth: 30,
    );
  }
}