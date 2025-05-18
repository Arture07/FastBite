import 'package:flutter/material.dart';
import 'package:myapp/model/user.dart'; // Precisa do enum UserRole
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/ui/auth/login_screen.dart'; // <<< IMPORTAR LoginScreen
import 'package:myapp/ui/home/home_screen.dart'; // Tela do Cliente
import 'package:myapp/ui/restaurant_dashboard/restaurant_dashboard_screen.dart'; // Tela do Restaurante
import 'package:provider/provider.dart';

// Este widget decide qual tela principal mostrar (Login, Cliente ou Restaurante)
// baseado no estado de autenticação e no papel do utilizador.
class MainAppWrapper extends StatelessWidget {
  const MainAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Ouve o AuthProvider para reagir a mudanças no estado de autenticação e nos dados do utilizador
    final authProvider = context.watch<AuthProvider>();

    // 1. Mostra um indicador de loading enquanto o AuthProvider está a carregar o estado inicial
    if (authProvider.isLoading) {
      debugPrint("MainAppWrapper: AuthProvider está a carregar. Mostrando CircularProgressIndicator.");
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Se o utilizador NÃO estiver autenticado, mostra a LoginScreen
    if (!authProvider.isAuthenticated || authProvider.currentUser == null) {
      debugPrint("MainAppWrapper: Utilizador não autenticado. Mostrando LoginScreen.");
      return const LoginScreen(); // <<< DIRECIONA PARA LOGIN QUANDO DESLOGADO
    }

    // 3. Se o utilizador ESTIVER autenticado, verifica o papel
    final UserRole userRole = authProvider.currentUser!.role; // Agora sabemos que currentUser não é nulo
    debugPrint("MainAppWrapper: Utilizador autenticado. Construindo UI para role = $userRole");

    if (userRole == UserRole.restaurant) {
      // Se o utilizador logado tem o papel de restaurante
      return const RestaurantDashboardScreen();
    } else {
      // Se for cliente ou se o papel for nulo/desconhecido (trata como cliente por padrão)
      return const HomeScreen();
    }
  }
}
