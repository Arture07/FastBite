import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/app_colors.dart'; // Importar suas cores

class AppTheme {
  // --- Tema Claro ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.mainColor, // Sua cor principal
    colorScheme: ColorScheme.light(
      primary: AppColors.mainColor,
      secondary: AppColors.mainColor.withAlpha((255 * 0.7).round()),
      background: Colors.grey[100]!, // Fundo claro
      surface: Colors.white, // Superfície de cards, etc.
      onPrimary: Colors.white, // Cor do texto sobre cor primária
      onSecondary: Colors.black,
      onSurface: Colors.black87,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      elevation: 1.0,
      backgroundColor:
          AppColors
              .lightBackgroundColor, // AppBar escuro mesmo no tema claro? Ou use surface
      foregroundColor: Colors.white, // Cor do título e ícones no AppBar
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      color: Colors.white, // Fundo da barra inferior
      elevation: 2.0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.mainColor),
    ),
    // Defina outros estilos: textTheme, iconTheme, etc.
  );

  // --- Tema Escuro ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.mainColor, // Laranja como cor primária
    colorScheme: ColorScheme.dark(
      primary: AppColors.mainColor, // Laranja
      secondary: AppColors.mainColor.withAlpha((255 * 0.8).round()), // Laranja mais suave
      background: AppColors.backgroundColor, // Fundo escuro principal
      surface: AppColors.lightBackgroundColor, // Fundo de cards/diálogos
      onPrimary: Colors.black, // Texto sobre laranja
      onSecondary: Colors.black,
      onSurface: Colors.white, // Texto sobre cards
      error: Colors.redAccent[100]!,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: AppColors.backgroundColor,
    appBarTheme: AppBarTheme(
      elevation: 1.0,
      backgroundColor:
          AppColors
              .lightBackgroundColor, // AppBar um pouco mais claro que o fundo
      foregroundColor: Colors.white, // Título e ícones brancos
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomAppBarTheme: BottomAppBarTheme(
      color: AppColors.lightBackgroundColor, // Fundo da barra inferior
      elevation: 2.0,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      color: AppColors.lightBackgroundColor, // Cor do card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800], // Fundo do input
      hintStyle: TextStyle(color: Colors.grey[500]),
      prefixIconColor: Colors.grey[400],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.black, // Texto preto no botão laranja
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mainColor, // Cor do link/botão de texto
      ),
    ),
    // Defina outros estilos para o tema escuro
    textTheme: ThemeData.dark().textTheme.apply(
      // Baseia-se no tema escuro padrão
      bodyColor: Colors.white.withAlpha((255 * 0.9).round()),
      displayColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    dividerTheme: DividerThemeData(color: Colors.grey[800], thickness: 0.5),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[700],
      labelStyle: TextStyle(color: Colors.white),
      secondaryLabelStyle: TextStyle(color: Colors.white),
      selectedColor: AppColors.mainColor,
      disabledColor: Colors.grey[850],
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: StadiumBorder(),
    ),
  );

  // Variável estática usada no MaterialApp (se não usar os temas acima diretamente)
  // static final ThemeData appTheme = darkTheme; // Define o tema padrão inicial aqui (ou use themeMode)
}
