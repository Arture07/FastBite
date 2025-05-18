// lib/ui/checkout/add_new_card_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/payment_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Para gerar IDs únicos - adicione `uuid: ^4.3.3` no pubspec.yaml

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

  @override
  void initState() {
    super.initState();
    // Define estado inicial baseado no cardToEdit
    if (widget.cardToEdit != null) {
      // Modo Edição: preenche campos
      _appBarTitle = "Editar Cartão";
      _buttonText = "Salvar Alterações";
      _selectedCardType = widget.cardToEdit!.cardType;
      _nameController.text = widget.cardToEdit!.name;
      _cardNumberController.text =
          "**** **** **** ${widget.cardToEdit!.last4Digits}"; // Mostra só o final
      // Não preencher validade/CVV por segurança/simplicidade na edição simulada
    } else {
      // Modo Adição
      _appBarTitle = "Adicionar Cartão";
      _buttonText = "Salvar Cartão";
      _selectedCardType = CardType.credit; // Padrão Crédito ao adicionar
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
    if (_formKey.currentState!.validate()) {
      final paymentProvider = Provider.of<PaymentProvider>(
        context,
        listen: false,
      );
      var uuid = const Uuid();

      // Lógica para obter dados do formulário (exemplo simplificado)
      // Em modo edição, só pegamos nome e tipo, mantemos ID e last4.
      // Em modo adição, pegamos tudo (com simulação de last4).
      String last4 = "****";
      if (widget.cardToEdit == null && _cardNumberController.text.length >= 4) {
        last4 = _cardNumberController.text.substring(
          _cardNumberController.text.length - 4,
        );
      } else if (widget.cardToEdit != null) {
        last4 = widget.cardToEdit!.last4Digits;
      }

      if (widget.cardToEdit == null) {
        // --- MODO ADIÇÃO ---
        final newCard = PaymentCard(
          id: uuid.v4(), // Gera novo ID
          name:
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : "Cartão Final $last4",
          last4Digits: last4,
          cardType: _selectedCardType,
          brand: CardBrand.other, // Usar placeholder ou detectar bandeira
        );
        paymentProvider.addCard(newCard);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cartão adicionado! (Simulação)')),
        );
      } else {
        // --- MODO EDIÇÃO ---
        // Cria um cartão atualizado usando copyWith (se implementado no modelo) ou manualmente
        final updatedCard = widget.cardToEdit!.copyWith(
          name: _nameController.text,
          cardType: _selectedCardType,
          // Não alteramos ID, last4, brand nesta edição simulada
        );
        // Ou manualmente:
        // final updatedCard = PaymentCard(
        //    id: widget.cardToEdit!.id, // Mantém o ID original
        //    name: _nameController.text,
        //    last4Digits: widget.cardToEdit!.last4Digits, // Mantém last4
        //    cardType: _selectedCardType,
        //    brand: widget.cardToEdit!.brand, // Mantém brand
        // );
        paymentProvider.updateCard(updatedCard);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cartão atualizado!')));
      }
      Navigator.pop(context); // Volta para a tela anterior
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.cardToEdit != null;
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ALERTA DE SEGURANÇA ---
              if (!isEditing)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  color: Colors.red[900],
                  child: Text(
                    "ATENÇÃO: Em aplicativos reais, NUNCA colete ou armazene dados completos de cartão diretamente. Use SDKs seguros de gateways de pagamento (Stripe, Mercado Pago, etc.) para tokenização e conformidade PCI.",
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!isEditing) const SizedBox(height: 24),

              // --- SELEÇÃO DE TIPO DE CARTÃO ---
              const Text("Tipo de Cartão:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              ToggleButtons(
                isSelected: [
                  // Lista de booleanos para indicar seleção
                  _selectedCardType == CardType.credit,
                  _selectedCardType == CardType.debit,
                ],
                onPressed: (int index) {
                  setState(() {
                    _selectedCardType =
                        (index == 0) ? CardType.credit : CardType.debit;
                  });
                },
                borderRadius: BorderRadius.circular(8.0),
                selectedColor: Colors.white,
                color: Colors.grey[400],
                fillColor: Theme.of(context).primaryColor,
                constraints: BoxConstraints(
                  minHeight: 40.0,
                  minWidth: (MediaQuery.of(context).size.width - 48) / 2,
                ),
                // <<< ADICIONE ESTA PARTE >>>
                children: const <Widget>[
                  // Widget para o botão "Crédito"
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Crédito'),
                  ),
                  // Widget para o botão "Débito"
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Débito'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Campos do Cartão ---
              // Desabilitar campo número se estiver editando (ou mostrar só o final)
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText:
                      isEditing
                          ? "Cartão (Final ${widget.cardToEdit!.last4Digits})"
                          : "Número do Cartão (Simulado)",
                ),
                keyboardType: TextInputType.number,
                enabled: !isEditing, // Desabilita em modo edição
                validator:
                    isEditing
                        ? null
                        : (value) {
                          // Não valida em modo edição
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          return null;
                        },
              ),
              const SizedBox(height: 16),
              // Esconder validade/CVV em modo edição (simulação)
              if (!isEditing)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          labelText: "Validade (MM/AA)",
                        ) /* ... */,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: InputDecoration(labelText: "CVV") /* ... */,
                      ),
                    ),
                  ],
                ),
              if (!isEditing)
                const SizedBox(
                  height: 16,
                ), // Só mostra espaço se os campos acima aparecerem
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nome no Cartão / Apelido",
                ), // Tornar mais claro
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // --- Botão Salvar ---
              ElevatedButton(
                onPressed: _saveCard, // Chama a função separada
                child: Text(_buttonText), // Texto dinâmico
              ),
            ],
          ),
        ),
      ),
    );
  }
}
