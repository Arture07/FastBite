import 'package:flutter/services.dart';

/// Formata o número do cartão com espaços a cada 4 dígitos.
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); // Permite apenas dígitos
    
    if (text.length > 16) { // Limita a 16 dígitos (comum para Visa/Mastercard)
      text = text.substring(0, 16);
    }

    var newText = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        newText.write(' '); // Adiciona espaço a cada 4 dígitos
      }
      newText.write(text[i]);
    }

    return newValue.copyWith(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// Formata a data de validade como MM/AA.
class CardExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), ''); // Permite apenas dígitos
    var newText = StringBuffer();

    if (text.length > 4) { // Limita a 4 dígitos (MMAA)
      text = text.substring(0, 4);
    }

    for (int i = 0; i < text.length; i++) {
      newText.write(text[i]);
      if (i == 1 && text.length > 2) { // Adiciona '/' após MM se AA for digitado
        newText.write('/');
      }
    }
    
    return newValue.copyWith(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
