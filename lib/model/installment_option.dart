import 'package:intl/intl.dart';

class InstallmentOption {
  final int numberOfInstallments; // Ex: 1, 2, 3...
  final double installmentValue;   // Valor de cada parcela
  final double totalAmount;        // Valor total (pode incluir juros)
  final bool hasInterest;          // Indica se tem juros

  InstallmentOption({
    required this.numberOfInstallments,
    required this.installmentValue,
    required this.totalAmount,
    required this.hasInterest,
  });

  // Formata a descrição para exibir no Dropdown
  String get description {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final installmentValueFormatted = currencyFormat.format(installmentValue);
    final totalAmountFormatted = currencyFormat.format(totalAmount);

    if (numberOfInstallments == 1) {
      return '1x de $installmentValueFormatted (Total $totalAmountFormatted)';
    } else if (hasInterest) {
      return '${numberOfInstallments}x de $installmentValueFormatted (Total $totalAmountFormatted com juros)';
    } else {
      return '${numberOfInstallments}x de $installmentValueFormatted sem juros (Total $totalAmountFormatted)';
    }
  }

  // Sobrescrever == e hashCode é importante para usar em DropdownButton
   @override
   bool operator ==(Object other) =>
       identical(this, other) ||
       other is InstallmentOption &&
           runtimeType == other.runtimeType &&
           numberOfInstallments == other.numberOfInstallments;

   @override
   int get hashCode => numberOfInstallments.hashCode;
}