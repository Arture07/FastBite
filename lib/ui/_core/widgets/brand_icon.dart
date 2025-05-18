import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/payment_provider.dart'; // Importar enum CardBrand

class BrandIcon extends StatelessWidget {
  final CardBrand brand;
  final double size;

  const BrandIcon({super.key, required this.brand, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    // Mapeia o enum para um ícone ou imagem
    // Substitua por Image.asset se tiver logos das bandeiras em assets/brands/
    IconData iconData;
    Color? iconColor; // Cor específica da bandeira?

    switch (brand) {
      case CardBrand.visa:
        // iconData = Icons.credit_card; // Ícone genérico
        // Use FontAwesome ou imagens para logos reais
        // Exemplo com ícone genérico e cor:
         iconData = Icons.credit_card; // Placeholder
         iconColor = Colors.blue[800]; // Cor associada ao Visa
        break;
      case CardBrand.mastercard:
         iconData = Icons.credit_card; // Placeholder
         iconColor = Colors.red[700]; // Cor associada ao Mastercard
        break;
      case CardBrand.elo:
         iconData = Icons.credit_card; // Placeholder
         iconColor = Colors.amber[700]; // Cor associada ao Elo
        break;
       case CardBrand.amex:
         iconData = Icons.credit_card; // Placeholder
         iconColor = Colors.indigo[700]; // Cor associada ao Amex
        break;
      // Adicione outras bandeiras...
      default:
        iconData = Icons.credit_card; // Ícone padrão
        iconColor = Colors.grey[600];
    }

    return Icon(iconData, size: size, color: iconColor);

    // Exemplo com Imagens (se tiver os logos em assets/brands/visa.png, etc.)
    // String imagePath;
    // switch (brand) {
    //    case CardBrand.visa: imagePath = 'assets/brands/visa.png'; break;
    //    case CardBrand.mastercard: imagePath = 'assets/brands/mastercard.png'; break;
    //    // ...
    //    default: imagePath = 'assets/brands/default.png'; break;
    // }
    // return Image.asset(imagePath, height: size, width: size * 1.6); // Ajuste width/height
  }
}