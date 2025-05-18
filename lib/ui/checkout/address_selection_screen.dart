// lib/ui/checkout/address_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/model/address.dart';
import 'package:myapp/ui/_core/address_provider.dart'; // Importar Provider e Modelo Address
import 'package:myapp/ui/checkout/add_new_address_screen.dart'; // Tela para adicionar/editar
import 'package:provider/provider.dart';

class AddressSelectionScreen extends StatelessWidget {
  const AddressSelectionScreen({super.key});

  // Helper para confirmação de remoção (igual ao de PaymentSelectionScreen)
  Future<bool?> _showDeleteConfirmationDialog(
    BuildContext context,
    Address address,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Remoção'),
          content: Text(
            'Remover o endereço "${address.formattedAddress}"?',
          ), // Mostra endereço
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remover'),
              onPressed: () => Navigator.of(context).pop(true), // Confirma
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ouve o AddressProvider para obter a lista e o endereço selecionado
    final addressProvider = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecionar/Gerenciar Endereço"),
      ), // Título mais claro
      body: Column(
        // Para ter lista e botão Adicionar
        children: [
          Expanded(
            // Faz a lista ocupar o espaço
            child:
                addressProvider.savedAddresses.isEmpty
                    ? const Center(
                      // Mensagem se não houver endereços
                      child: Text(
                        "Nenhum endereço salvo.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      // Lista os endereços salvos
                      itemCount: addressProvider.savedAddresses.length,
                      itemBuilder: (context, index) {
                        final address = addressProvider.savedAddresses[index];
                        // Verifica se este é o endereço atualmente selecionado no provider
                        final bool isSelected =
                            address.id == addressProvider.selectedAddress?.id;

                        // Usa Dismissible para permitir remover arrastando
                        return Dismissible(
                          key: ValueKey(address.id), // Chave única
                          direction:
                              DismissDirection
                                  .endToStart, // Arrastar da direita p/ esquerda
                          confirmDismiss: (direction) async {
                            // Pede confirmação antes de remover
                            return await _showDeleteConfirmationDialog(
                              context,
                              address,
                            );
                          },
                          onDismissed: (direction) {
                            // Chama o método removeAddress do provider
                            context.read<AddressProvider>().removeAddress(
                              address.id,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Endereço "${address.street}" removido.',
                                ),
                              ),
                            );
                          },
                          background: Container(
                            // Fundo vermelho ao arrastar
                            color: Colors.redAccent[700],
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerRight,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          // O ListTile que exibe o endereço
                          child: ListTile(
                            leading: Icon(
                              // Ícone preenchido se selecionado, contorno se não
                              isSelected
                                  ? Icons.location_on
                                  : Icons.location_on_outlined,
                              color:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[600],
                            ),
                            title: Text(
                              address.formattedAddress,
                            ), // Rua, Num - Comp
                            subtitle: Text(
                              address.cityState,
                            ), // Cidade - Estado
                            trailing: Row(
                              // Ícones de Check (se selecionado) e Editar
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Mostra check se selecionado
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
                                  tooltip: 'Editar Endereço',
                                  onPressed: () {
                                    // Navega para AddNewAddressScreen passando o endereço para edição
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AddNewAddressScreen(
                                              addressToEdit: address,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            // <<< AÇÃO PRINCIPAL: Selecionar o endereço >>>
                            onTap: () {
                              // 1. Chama o método selectAddress no provider para atualizar o estado
                              context.read<AddressProvider>().selectAddress(
                                address.id,
                              );
                              // 2. Fecha esta tela e volta para o CheckoutScreen
                              Navigator.pop(context);
                            },
                            selected:
                                isSelected, // Aplica estilo de selecionado
                            selectedTileColor: Colors.grey.withOpacity(
                              0.1,
                            ), // Cor de fundo suave quando selecionado
                          ),
                        );
                      },
                    ),
          ),
          // Botão para Adicionar Novo Endereço
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text("Adicionar Novo Endereço"),
              onPressed: () {
                // Navega para AddNewAddressScreen sem passar endereço (modo adição)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewAddressScreen(),
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
