// lib/ui/_core/widgets/appbar.dart
import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/bag_provider.dart';
import 'package:myapp/ui/checkout/checkout_screen.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

// Função que constrói um AppBar padrão com ícone de sacola funcional
AppBar getAppBar({
  required BuildContext context,
  String? title,
  List<Widget>? customActions,
  PreferredSizeWidget? bottom, // <<< NOVO PARÂMETRO ADICIONADO
}) {
  final bagProvider = context.watch<BagProvider>();
  final String? currentRestaurantId = bagProvider.currentRestaurantId;
  final theme = Theme.of(context); // Para usar cores do tema

  List<Widget> actions = [];
  if (customActions != null) {
    actions.addAll(customActions);
  }

  actions.add(
    Padding(
      padding: const EdgeInsets.only(right: 8.0, left: 4.0),
      child: badges.Badge(
        showBadge: bagProvider.dishesOnBag.isNotEmpty,
        position: badges.BadgePosition.topEnd(top: 0, end: 0),
        badgeContent: Text(
          bagProvider.dishesOnBag.length.toString(),
          style: TextStyle(fontSize: 10, color: theme.colorScheme.onPrimary), // Cor do tema
        ),
        badgeStyle: badges.BadgeStyle(
          badgeColor: theme.colorScheme.primary, // Cor do tema
        ),
        child: IconButton(
          tooltip: 'Ver Sacola',
          onPressed: () {
            if (bagProvider.dishesOnBag.isNotEmpty && currentRestaurantId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutScreen(restaurantId: currentRestaurantId),
                ),
              );
            } else if (bagProvider.dishesOnBag.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sua sacola está vazia.'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro ao identificar o restaurante da sacola.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          // Usa cor do tema para o ícone da sacola
          icon: Icon(Icons.shopping_basket_outlined, color: theme.appBarTheme.iconTheme?.color ?? theme.colorScheme.onPrimary),
        ),
      ),
    ),
  );

  return AppBar(
    title: title != null ? Text(title) : null,
    centerTitle: true,
    actions: actions,
    elevation: 1.0,
    // backgroundColor: theme.appBarTheme.backgroundColor, // Já definido pelo tema
    // foregroundColor: theme.appBarTheme.foregroundColor, // Já definido pelo tema
    bottom: bottom, // <<< USA O NOVO PARÂMETRO AQUI
  );
}
