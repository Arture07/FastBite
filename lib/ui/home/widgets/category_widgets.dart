// lib/ui/home/widgets/category_widgets.dart
import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/app_colors.dart';

class CategoryWidgets extends StatelessWidget {
  final String category;
  final bool isSelected; // <<< NOVO: Indica se esta categoria está selecionada
  final VoidCallback onTap; // <<< NOVO: Função a ser chamada ao clicar

  const CategoryWidgets({
    super.key,
    required this.category,
    required this.isSelected, // <<< Obrigatório
    required this.onTap, // <<< Obrigatório
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData currentTheme = Theme.of(context);
    final Color bgColor = isSelected
        ? AppColors.mainColor
        // <<< USA COR DE SUPERFÍCIE DO TEMA PARA ESTADO NÃO SELECIONADO >>>
        : currentTheme.colorScheme.surface; // ou currentTheme.cardColor
    final Color textColor = isSelected
        ? (currentTheme.brightness == Brightness.dark ? Colors.black : Colors.white) // Contraste para mainColor
        // <<< USA COR DE TEXTO DO TEMA PARA ESTADO NÃO SELECIONADO >>>
        : currentTheme.colorScheme.onSurface;

    return InkWell(
      // Permite clique
      onTap: onTap, // Chama a função passada
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor, // <<< Cor de fundo dinâmica
          borderRadius: BorderRadius.circular(12.0),
          // Adiciona uma borda sutil se selecionado para destaque extra
          border:
              isSelected
                  ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
                  : null,
          boxShadow:
              isSelected
                  ? [
                    // Adiciona sombra se selecionado
                    BoxShadow(
                      color: AppColors.mainColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [], // Sem sombra se não selecionado
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/categories/${category.toLowerCase()}.png',
              height: 48,
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                  "Erro ao carregar imagem: assets/categories/${category.toLowerCase()}.png",
                );
                return Icon(
                  Icons.error_outline,
                  color: isSelected ? Colors.white70 : Colors.redAccent[100],
                  size: 48,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight:
                    isSelected
                        ? FontWeight.bold
                        : FontWeight.w500, // Negrito se selecionado
                color: textColor, // <<< Cor do texto dinâmica
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
