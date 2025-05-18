import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar moeda e data
import 'package:myapp/model/address.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/model/installment_option.dart'; // Modelo para opções de parcela
import 'package:myapp/model/order.dart' as my_order_model;
import 'package:myapp/ui/_core/address_provider.dart';
import 'package:myapp/ui/_core/app_colors.dart';
import 'package:myapp/ui/_core/auth_provider.dart'; // Para pegar userId
import 'package:myapp/ui/_core/bag_provider.dart';
import 'package:myapp/ui/_core/order_provider.dart'; // Para registrar o pedido
import 'package:myapp/ui/_core/payment_provider.dart'; // Para pegar cartão e tipo
import 'package:myapp/ui/checkout/address_selection_screen.dart'; // Para navegar
import 'package:myapp/ui/checkout/payment_selection_screen.dart'; // Para navegar
import 'package:myapp/ui/_core/widgets/brand_icon.dart'; // Para ícone da bandeira
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Para gerar ID único do pedido

// --- Definição do StatefulWidget ---
class CheckoutScreen extends StatefulWidget {
  // Recebe o ID do restaurante cujos itens estão na sacola
  final String restaurantId;

  const CheckoutScreen({
    super.key,
    required this.restaurantId, // ID é obrigatório
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

// --- Definição da Classe State ---
class _CheckoutScreenState extends State<CheckoutScreen> {
  InstallmentOption? _selectedInstallmentOption;
  List<InstallmentOption> _installmentOptions = [];
  int _currentSubtotalCents = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recalculateValues(); // Renomeado para maior clareza
  }

  // Calcula opções de parcelamento (recebe valor base em CENTAVOS)
  List<InstallmentOption> _calculateInstallmentOptions(
    int baseAmountCents, { // <<< RECEBE CENTAVOS (int)
    int maxInstallments = 12,
    int installmentsFreeOfInterest = 3,
    double interestRate = 0.05, // 5%
  }) {
    List<InstallmentOption> options = [];
    if (baseAmountCents <= 0) return options;

    // Converte para reais para cálculo de juros (se a taxa for sobre reais)
    double baseAmountReais = baseAmountCents / 100.0;

    for (int i = 1; i <= maxInstallments; i++) {
      bool hasInterest = i > installmentsFreeOfInterest;
      double currentInterestRate = hasInterest ? interestRate : 0.0;
      // Juros simples (exemplo, use lógica do seu gateway)
      double totalAmountReaisWithInterest = baseAmountReais * (1 + (currentInterestRate * (i > 1 ? i : 0)));
      double installmentValueReais = totalAmountReaisWithInterest / i;

      options.add(
        InstallmentOption( // InstallmentOption armazena valores em REAIS para exibição
          numberOfInstallments: i,
          installmentValue: installmentValueReais,
          totalAmount: totalAmountReaisWithInterest,
          hasInterest: hasInterest,
        ),
      );
      if (installmentValueReais < 5.0 && i > 1) break; // Parcela mínima de R$5,00
    }
    return options;
  }

  // Recalcula subtotal e opções de parcelamento
  void _recalculateValues() {
    final bagProvider = Provider.of<BagProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    final selectedPayment = paymentProvider.selectedCard;

    // Calcula subtotal em CENTAVOS
    // dish.price já está em centavos (int)
    _currentSubtotalCents = bagProvider.dishesOnBag.fold(0, (sum, item) => sum + item.price);

    List<InstallmentOption> newOptions = [];
    InstallmentOption? newSelectedOption;

    if (selectedPayment?.cardType == CardType.credit && _currentSubtotalCents > 0) {
      // Passa subtotal em CENTAVOS para calcular parcelas
      newOptions = _calculateInstallmentOptions(_currentSubtotalCents);

      if (_selectedInstallmentOption != null &&
          newOptions.any((opt) => opt.numberOfInstallments == _selectedInstallmentOption!.numberOfInstallments)) {
        newSelectedOption = newOptions.firstWhere((opt) => opt.numberOfInstallments == _selectedInstallmentOption!.numberOfInstallments);
      } else if (newOptions.isNotEmpty) {
        newSelectedOption = newOptions[0]; // Padrão 1x
      }
    }
    
    if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
                setState(() {
                    _installmentOptions = newOptions;
                    _selectedInstallmentOption = newSelectedOption;
                });
            }
        });
    } else {
        _installmentOptions = newOptions;
        _selectedInstallmentOption = newSelectedOption;
    }
  }

  Future<void> _confirmAndPlaceOrder() async {
    final bagProvider = context.read<BagProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final addressProvider = context.read<AddressProvider>();
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    final selectedPayment = paymentProvider.selectedCard;
    final Address? selectedAddress = addressProvider.selectedAddress; // Pode ser nulo
    final String? userId = authProvider.currentUser?.id;

    if (bagProvider.dishesOnBag.isEmpty || selectedPayment == null || selectedAddress == null || userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Informações do pedido incompletas.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // --- VALORES EM CENTAVOS PARA O OBJETO Order ---
    int subtotalForOrderCents = _currentSubtotalCents;
    int deliveryFeeForOrderCents = 600; // Exemplo: R$ 6,00 = 600 centavos

    int totalAmountForOrderCents;
    if (_selectedInstallmentOption != null) {
      // O totalAmount da InstallmentOption está em REAIS, converte para centavos
      totalAmountForOrderCents = (_selectedInstallmentOption!.totalAmount * 100).round();
    } else {
      // Soma direta dos centavos
      totalAmountForOrderCents = subtotalForOrderCents + deliveryFeeForOrderCents;
    }
    // --- FIM VALORES EM CENTAVOS ---

    List<my_order_model.OrderItem> orderItems = bagProvider.getMapByAmount().entries.map((entry) {
      Dish dish = entry.key;
      int quantity = entry.value;
      return my_order_model.OrderItem(
        dishId: dish.id,
        dishName: dish.name,
        quantity: quantity,
        pricePerItem: dish.price, // dish.price JÁ ESTÁ EM CENTAVOS (int)
      );
    }).toList();

    // Prepara dados do endereço e pagamento para o pedido
    Map<String, dynamic>? deliveryAddressMap = selectedAddress.toJson()..remove('id');
    Map<String, dynamic>? paymentMethodMap = selectedPayment.toJson()..remove('id');


    final newOrder = my_order_model.Order( // <<< USA PREFIXO
      id: const Uuid().v4(),
      restaurantId: widget.restaurantId,
      userId: userId,
      date: DateTime.now(),
      items: orderItems,
      deliveryFee: deliveryFeeForOrderCents,    // <<< CENTAVOS
      subtotal: subtotalForOrderCents,       // <<< CENTAVOS
      totalAmount: totalAmountForOrderCents, // <<< CENTAVOS
      status: my_order_model.OrderStatus.pending, // <<< USA PREFIXO
      deliveryAddress: deliveryAddressMap,
      paymentMethodInfo: paymentMethodMap,
    );

    debugPrint("CheckoutScreen: Simulando processamento de pagamento...");
    await Future.delayed(const Duration(seconds: 1));
    bool paymentSuccess = true;

    if (paymentSuccess) {
      try {
        await orderProvider.placeOrder(newOrder); // placeOrder agora é async
        debugPrint("CheckoutScreen: Pedido ${newOrder.id} enviado para OrderProvider.");

        bagProvider.clearBag();
        paymentProvider.selectCard(null);
        addressProvider.selectAddress(null);

        if (mounted) {
          setState(() {
            _selectedInstallmentOption = null;
            _installmentOptions = [];
            _currentSubtotalCents = 0; // Reseta subtotal em centavos
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido realizado com sucesso!'), backgroundColor: Colors.green),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao registrar pedido: ${e.toString()}'), backgroundColor: Colors.red),
            );
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bagProvider = context.watch<BagProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final theme = Theme.of(context);

    // Recalcula se a sacola mudou (o subtotal em _currentSubtotalCents é atualizado em _recalculateValues)
    final newSubtotalFromBagCents = bagProvider.dishesOnBag.fold(0, (sum, item) => sum + item.price);
    if (newSubtotalFromBagCents != _currentSubtotalCents) {
      // Adia a chamada para após o frame atual para evitar erro de setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recalculateValues();
      });
    }

    final selectedPayment = paymentProvider.selectedCard;
    final selectedAddress = addressProvider.selectedAddress;

    // --- VALORES PARA EXIBIÇÃO (EM REAIS) ---
    double subtotalReais = _currentSubtotalCents / 100.0;
    double deliveryFeeReais = 6.00; // Exemplo: R$ 6,00

    double finalTotalReais;
    if (_selectedInstallmentOption != null) {
      // totalAmount da InstallmentOption JÁ ESTÁ EM REAIS
      finalTotalReais = _selectedInstallmentOption!.totalAmount;
    } else {
      finalTotalReais = subtotalReais + deliveryFeeReais;
    }

    // Formatador de moeda
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sacola"),
        elevation: 1.0,
        actions: [
          TextButton(
            onPressed: (bagProvider.dishesOnBag.isEmpty && selectedPayment == null && selectedAddress == null)
                ? null
                : () {
                    bagProvider.clearBag();
                    paymentProvider.selectCard(null);
                    addressProvider.selectAddress(null);
                  },
            child: const Text("Limpar Tudo"),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Pedido", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (bagProvider.dishesOnBag.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 40.0,
                  ), // Mais espaço vertical
                  child: Center(
                    child: Column(
                      // Adiciona ícone
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Sua sacola está vazia.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              // Lista de Itens na Sacola
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: bagProvider.getMapByAmount().keys.length,
                  itemBuilder: (context, index) {
                    Dish dish =
                        bagProvider.getMapByAmount().keys.toList()[index];
                    int amount = bagProvider.getMapByAmount()[dish] ?? 0;
                    // ListTile para cada item
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                      ), // Padding vertical
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          dish.imagePath.isNotEmpty
                              ? 'assets/${dish.imagePath}'
                              : 'assets/dishes/default.png',
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover, // Imagem maior
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 30,
                                ),
                              ),
                        ),
                      ),
                      title: Text(
                        dish.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        currencyFormat.format(dish.price / 100),
                      ), // Preço formatado
                      trailing: Row(
                        // Botões +/-
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 22,
                            ),
                            tooltip: 'Remover um',
                            onPressed: () => bagProvider.removeDishes(dish),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Text(
                              amount.toString(),
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              size: 22,
                              color: AppColors.mainColor,
                            ),
                            tooltip: 'Adicionar mais um',
                            onPressed:
                                () => bagProvider.addAllDishes([
                                  dish,
                                ], widget.restaurantId),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder:
                      (context, index) =>
                          const Divider(height: 1, thickness: 0.5), // Divisor
                ),
              const Divider(height: 32, thickness: 1), // Divisor mais grosso
              // --- Seção Pagamento ---
              const Text(
                "Pagamento",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading:
                    selectedPayment != null
                        ? BrandIcon(brand: selectedPayment.brand, size: 30)
                        : const Icon(
                          Icons.credit_card_outlined,
                          size: 30,
                          color: Colors.grey,
                        ),
                title: Text(
                  selectedPayment?.name ?? "Selecione a forma de pagamento",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle:
                    selectedPayment != null
                        ? Text(
                          "${selectedPayment.cardType == CardType.credit ? 'Crédito' : 'Débito'} • Final ${selectedPayment.last4Digits}",
                        )
                        : const Text("Nenhuma forma selecionada"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  String? previousCardId = paymentProvider.selectedCard?.id;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentSelectionScreen(),
                    ),
                  );
                  if (previousCardId != paymentProvider.selectedCard?.id ||
                      (previousCardId == null &&
                          paymentProvider.selectedCard != null)) {
                    _recalculateValues(); // Recalcula se o cartão mudou
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

              // --- Seletor de Parcelas ---
              if (selectedPayment?.cardType == CardType.credit &&
                  _installmentOptions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 12.0,
                    left: 4,
                    right: 4,
                  ), // Padding em volta
                  child: DropdownButtonFormField<InstallmentOption>(
                    value: _selectedInstallmentOption,
                    items:
                        _installmentOptions.map((option) {
                          return DropdownMenuItem<InstallmentOption>(
                            value: option,
                            child: Text(
                              option.description,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    option.hasInterest
                                        ? Colors.orangeAccent[100]
                                        : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                    onChanged: (InstallmentOption? newValue) {
                      setState(() {
                        _selectedInstallmentOption = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Parcelamento',
                      filled: true, // Adiciona fundo
                      fillColor:
                          Colors
                              .grey[800], // Cor de fundo escura (ajuste se necessário)
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ), // Sem borda visível
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      isDense: true,
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 24),
                  ),
                ),

              const Divider(height: 32, thickness: 1),

              // --- Seção Endereço ---
              const Text(
                "Entregar no endereço",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  size: 30,
                  color: Colors.grey,
                ),
                title: Text(
                  selectedAddress?.formattedAddress ?? "Selecione o endereço",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle:
                    selectedAddress != null
                        ? Text(selectedAddress.cityState)
                        : const Text("Nenhum endereço selecionado"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressSelectionScreen(),
                    ),
                  );
                  // O Provider notifica, setState não é necessário aqui
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const Divider(height: 32, thickness: 1),

              // --- Seção Confirmar (Resumo) ---
              const Text(
                "Resumo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTotalRow(
                "Subtotal:",
                currencyFormat.format(subtotalReais),
              ),
              _buildTotalRow("Entrega:", currencyFormat.format(deliveryFeeReais)),
              // Mostra valor da parcela se aplicável
              if (_selectedInstallmentOption != null &&
                  _selectedInstallmentOption!.numberOfInstallments > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: _buildTotalRow(
                    "${_selectedInstallmentOption!.numberOfInstallments}x:",
                    currencyFormat.format(
                      _selectedInstallmentOption!.installmentValue,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _buildTotalRow(
                // Linha do Total Final
                "Total:",
                currencyFormat.format(
                  finalTotalReais
                ), // Usa o total final calculado
                isTotal: true,
              ),
              const SizedBox(height: 64), // Espaço antes do botão final
            ],
          ),
        ),
      ),
      // --- Botão Finalizar Pedido ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          // Adiciona sombra sutil acima do botão
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          // Habilita SÓ se tiver itens E pagamento E endereço selecionados
          onPressed:
              (bagProvider.dishesOnBag.isEmpty ||
                      selectedPayment == null ||
                      selectedAddress == null)
                  ? null // Botão desabilitado
                  : _confirmAndPlaceOrder, // Chama a função que cria e envia o pedido
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            // Cor de fundo pode ser a principal do app
            // backgroundColor: AppColors.mainColor,
            // foregroundColor: Colors.white,
          ),
          child: Text(
            "Confirmar Pedido (${currencyFormat.format(finalTotalReais)})",
          ), // Total no botão
        ),
      ),
    );
  }

  // --- Helper Widget para Linhas do Total ---
  Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 6.0 : 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14, // Total um pouco maior
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? null : Colors.grey[400],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} // Fim da classe _CheckoutScreenState
