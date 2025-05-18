import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/payment_provider.dart';
import 'package:myapp/ui/checkout/add_new_card_screen.dart'; // Importar tela Add/Edit
import 'package:provider/provider.dart';
import 'package:myapp/ui/_core/widgets/brand_icon.dart'; // Importar ícone de bandeira

class PaymentSelectionScreen extends StatelessWidget {
  const PaymentSelectionScreen({super.key});

  // Helper para mostrar confirmação antes de deletar
  Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    PaymentCard card,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: Text(
            'Tem certeza que deseja remover o cartão "${card.name}" final ${card.last4Digits}?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false); // Retorna false (não deletar)
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remover'),
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna true (deletar)
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ouve as mudanças no PaymentProvider
    final paymentProvider =
        context.watch<PaymentProvider>(); // watch para reconstruir a lista

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciar Pagamentos"),
      ), // Título mais apropriado
      body: Column(
        children: [
          Expanded(
            // Exibe mensagem se não houver cartões
            child:
                paymentProvider.savedCards.isEmpty
                    ? const Center(
                      child: Text(
                        "Nenhum cartão salvo.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      itemCount: paymentProvider.savedCards.length,
                      itemBuilder: (context, index) {
                        final card = paymentProvider.savedCards[index];
                        final bool isSelected =
                            card.id == paymentProvider.selectedCard?.id;

                        // Widget Dismissible para arrastar e deletar
                        return Dismissible(
                          key: ValueKey(card.id), // Chave única para o widget
                          direction:
                              DismissDirection
                                  .endToStart, // Arrastar da direita para esquerda
                          // Confirmação antes de remover
                          confirmDismiss: (direction) async {
                            return await _showDeleteConfirmationDialog(
                              context,
                              card,
                            );
                          },
                          // Ação ao confirmar a remoção
                          onDismissed: (direction) {
                            context.read<PaymentProvider>().removeCard(
                              card.id,
                            ); // Chama o método do provider
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cartão "${card.name}" removido.',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          // Visual de fundo ao arrastar
                          background: Container(
                            color: Colors.redAccent[700],
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerRight,
                            child: const Icon(
                              Icons.delete_sweep_outlined,
                              color: Colors.white,
                            ),
                          ),
                          // Conteúdo principal do item da lista
                          child: ListTile(
                            leading: BrandIcon(
                              brand: card.brand,
                              size: 32,
                            ), // Ícone da bandeira
                            title: Text(card.name),
                            subtitle: Text(
                              "${card.cardType == CardType.credit ? 'Crédito' : 'Débito'} • Final ${card.last4Digits}",
                            ),
                            // Mostra um check se for o cartão selecionado para pagamento
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                // Botão Editar
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                  tooltip: 'Editar Cartão',
                                  onPressed: () {
                                    // Navega para a tela AddNewCardScreen passando o cartão para edição
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AddNewCardScreen(
                                              cardToEdit: card,
                                            ), // Passa o cartão
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // Seleciona o cartão para pagamento e volta para Checkout
                              paymentProvider.selectCard(card.id);
                              Navigator.pop(
                                context,
                              ); // Volta para a tela anterior (CheckoutScreen)
                            },
                            selected:
                                isSelected, // Pode aplicar um estilo diferente se selecionado
                            selectedTileColor: Colors.grey.withOpacity(0.1),
                          ),
                        );
                      },
                    ),
          ),
          // Botão para adicionar novo cartão
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Adicionar Novo Cartão"),
              onPressed: () {
                // Navega para AddNewCardScreen sem passar cartão (modo adição)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewCardScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
