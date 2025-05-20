// lib/ui/checkout/add_new_card_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter
import 'package:myapp/services/error_handler.dart';
import 'package:myapp/services/input_formatters.dart';
import 'package:myapp/ui/_core/payment_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddNewCardScreen extends StatefulWidget {
  final PaymentCard? cardToEdit;
  const AddNewCardScreen({super.key, this.cardToEdit});

  @override
  State<AddNewCardScreen> createState() => _AddNewCardScreenState();
}

class _AddNewCardScreenState extends State<AddNewCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  late CardType _selectedCardType;
  late String _appBarTitle;
  late String _buttonText;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.cardToEdit != null;
    if (_isEditing) {
      _appBarTitle = "Editar Cartão";
      _buttonText = "Salvar Alterações";
      final card = widget.cardToEdit!;
      _selectedCardType = card.cardType;
      _nameController.text = card.name;
      // Para edição, não mostramos o número completo, apenas os últimos 4 dígitos
      _cardNumberController.text = "**** **** **** ${card.last4Digits}";
      // Validade e CVV não são geralmente editáveis ou são revalidados
      // _expiryDateController.text = card.expiryDate; // Se você armazenar a data completa
      // _cvvController.text = card.cvv; // CVV nunca deve ser armazenado
    } else {
      _appBarTitle = "Adicionar Novo Cartão";
      _buttonText = "Salvar Cartão";
      _selectedCardType = CardType.credit; // Padrão
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveCard() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);

    final paymentProvider = context.read<PaymentProvider>();
    final navigator = Navigator.of(context); // Captura antes do async
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Simulação: Pegar os últimos 4 dígitos do número do cartão
    String last4Digits = "0000";
    String rawCardNumber = _cardNumberController.text.replaceAll(' ', '');
    if (rawCardNumber.length >= 4) {
      last4Digits = rawCardNumber.substring(rawCardNumber.length - 4);
    }
    
    // Validação simples da data de validade (MM/AA)
    String expiryDate = _expiryDateController.text;
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(expiryDate)) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Data de validade inválida. Use MM/AA.'), backgroundColor: Colors.orange));
        setState(() => _isLoading = false);
        return;
    }
    // Poderia adicionar validação se a data já expirou

    final cardData = PaymentCard(
      id: widget.cardToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      last4Digits: last4Digits, // Salva apenas os últimos 4 dígitos
      cardType: _selectedCardType,
      brand: _getCardBrand(rawCardNumber), // Detecta a bandeira (simulado)
      // Não salvamos número completo, CVV ou data de validade completa por segurança
      // expiryDate: _expiryDateController.text, // Se decidir salvar
    );

    // Simula um delay de salvamento
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return; 

      try {
        if (_isEditing) {
          paymentProvider.updateCard(cardData);
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Cartão atualizado!'), backgroundColor: Colors.green,));
        } else {
          paymentProvider.addCard(cardData);
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Cartão adicionado!'), backgroundColor: Colors.green,));
        }
        if (navigator.canPop()) navigator.pop();
      } catch (e) {
         if (mounted) ErrorHandler.handleGenericError(context, e, operation: "salvar cartão");
      } finally {
         if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  // Função simulada para detectar bandeira (apenas para exibição)
  CardBrand _getCardBrand(String cardNumber) {
    if (cardNumber.startsWith('4')) return CardBrand.visa;
    if (cardNumber.startsWith('5')) return CardBrand.mastercard; // Simplificado
    // Adicionar mais lógicas se necessário
    return CardBrand.other;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... (Aviso sobre não coletar dados reais) ...
              Text(
                "ATENÇÃO: Em aplicativos reais, NUNCA colete ou armazene dados completos de cartão diretamente. Use SDKs seguros de gateways de pagamento (Stripe, Mercado Pago, etc.) para tokenização e conformidade PCI.",
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Seletor de Tipo de Cartão
              Text("Tipo de Cartão:", style: theme.textTheme.titleMedium),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<CardType>(
                      title: const Text('Crédito'),
                      value: CardType.credit,
                      groupValue: _selectedCardType,
                      onChanged: (CardType? value) {
                        if (value != null) setState(() => _selectedCardType = value);
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<CardType>(
                      title: const Text('Débito'),
                      value: CardType.debit,
                      groupValue: _selectedCardType,
                      onChanged: (CardType? value) {
                        if (value != null) setState(() => _selectedCardType = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Número do Cartão
              TextFormField(
                controller: _cardNumberController,
                enabled: !_isEditing && !_isLoading, // Desabilita em modo edição ou loading
                decoration: const InputDecoration(
                  labelText: "Número do Cartão (Simulado)",
                  hintText: "0000 0000 0000 0000",
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16), // Limita a 16 dígitos
                  CardNumberInputFormatter(), // Formata com espaços
                ],
                validator: (value) {
                  if (_isEditing) return null; // Não valida em modo edição
                  if (value == null || value.replaceAll(' ', '').length < 13) { // Mínimo comum
                    return 'Número do cartão inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Validade e CVV
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: "Validade (MM/AA)",
                        hintText: "MM/AA",
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4), // MMAA
                        CardExpiryDateInputFormatter(), // Formata com /
                      ],
                      validator: (value) {
                        if (value == null || !RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
                          return 'MM/AA inválido';
                        }
                        // Opcional: Validar se a data não expirou
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: "CVV",
                        hintText: "000",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4), // CVV pode ter 3 ou 4 dígitos
                      ],
                      validator: (value) {
                        if (value == null || value.length < 3) {
                          return 'CVV inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nome no Cartão / Apelido
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: "Nome no Cartão / Apelido do Cartão",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome/Apelido é obrigatório';
                  }
                  if (value.trim().length > 50) return 'Máximo 50 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveCard,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isLoading 
                    ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
