// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/ui/favorites/favorites_screen.dart';
import 'package:myapp/ui/settings/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // <<< IMPORTAR PARA INICIALIZAÇÃO

// Importar TODOS os seus providers
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/ui/_core/theme_provider.dart';
import 'package:myapp/ui/_core/address_provider.dart';
import 'package:myapp/ui/_core/bag_provider.dart';
import 'package:myapp/ui/_core/favorites_provider.dart';
import 'package:myapp/ui/_core/order_provider.dart';
import 'package:myapp/ui/_core/payment_provider.dart';

// Importar seu AppTheme e MainAppWrapper/MyApp
import 'package:myapp/ui/_core/app_theme.dart';
import 'package:myapp/ui/main_app_wrapper.dart'; 

// <<< IMPORTAR AS TELAS DE LOGIN E REGISTRO >>>
import 'package:myapp/ui/auth/login_screen.dart';
import 'package:myapp/ui/auth/register_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Criar instâncias dos providers
  final authProvider = AuthProvider();
  final restaurantData = RestaurantData();
  final themeProvider = ThemeProvider();
  final bagProvider = BagProvider(); // BagProvider pode precisar carregar do prefs

  // Carregar dados essenciais ANTES de runApp
  await restaurantData.loadRestaurants();
  // ThemeProvider carrega no construtor
  // BagProvider carrega no construtor (se usar SharedPreferences)

  runApp(
    MultiProvider(
      providers: [
        // Providers independentes
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: restaurantData),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: bagProvider),

        // Providers dependentes do AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, AddressProvider>(
          create: (context) => AddressProvider(authProvider),
          update: (context, auth, previousProvider) =>
              previousProvider ?? AddressProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (context) => PaymentProvider(authProvider),
          update: (context, auth, previousProvider) =>
              previousProvider ?? PaymentProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) => FavoritesProvider(authProvider),
          update: (context, auth, previousProvider) =>
              previousProvider ?? FavoritesProvider(auth),
        ),
         ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) => OrderProvider(authProvider),
          update: (context, auth, previousProvider) =>
              previousProvider ?? OrderProvider(auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// Widget Raiz do App (MaterialApp)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Tech Taste',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      // Define a tela inicial baseada no estado de autenticação
      home: const MainAppWrapper(),
      // <<< ADICIONA O MAPA DE ROTAS NOMEADAS AQUI >>>
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/settings': (context) => SettingsScreen(),
        '/favorites': (context) => FavoritesScreen(),
      },
    );
  }
}