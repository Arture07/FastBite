import 'package:flutter/material.dart';
import 'package:myapp/model/address.dart';
import 'package:myapp/ui/_core/address_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Certifique-se que a dependência uuid está no pubspec.yaml

// Classe StatefulWidget (sem alterações)
class AddNewAddressScreen extends StatefulWidget {
  final Address? addressToEdit;
  const AddNewAddressScreen({super.key, this.addressToEdit});

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

// Classe State (com as correções no build)
class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  // final _zipController = TextEditingController(); // Descomente se usar CEP

  late String _appBarTitle;
  late String _buttonText;

  @override
  void initState() {
    super.initState();
    // Define estado inicial baseado no addressToEdit (sem alterações aqui)
    if (widget.addressToEdit != null) {
      _appBarTitle = "Editar Endereço";
      _buttonText = "Salvar Alterações";
      _streetController.text = widget.addressToEdit!.street;
      _numberController.text = widget.addressToEdit!.number;
      _complementController.text = widget.addressToEdit!.complement;
      _neighborhoodController.text = widget.addressToEdit!.neighborhood;
      _cityController.text = widget.addressToEdit!.city;
      _stateController.text = widget.addressToEdit!.state;
      // _zipController.text = widget.addressToEdit!.zipCode;
    } else {
      _appBarTitle = "Adicionar Endereço";
      _buttonText = "Salvar Endereço";
    }
  }

  @override
  void dispose() {
    // Dispose dos controllers (sem alterações aqui)
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    // _zipController.dispose();
    super.dispose();
  }

  // Função _saveAddress (sem alterações aqui, ela contém a lógica correta)
  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      var uuid = const Uuid();

      if (widget.addressToEdit == null) {
        // --- MODO ADIÇÃO ---
        final newAddress = Address(
          id: uuid.v4(),
          street: _streetController.text,
          number: _numberController.text,
          complement: _complementController.text,
          neighborhood: _neighborhoodController.text,
          city: _cityController.text,
          state: _stateController.text,
          // zipCode: _zipController.text,
        );
        addressProvider.addAddress(newAddress);
        // Usar mounted check antes de chamar ScaffoldMessenger/Navigator em async gaps
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço adicionado!')));
      } else {
        // --- MODO EDIÇÃO ---
        final updatedAddress = widget.addressToEdit!.copyWith(
          street: _streetController.text,
          number: _numberController.text,
          complement: _complementController.text,
          neighborhood: _neighborhoodController.text,
          city: _cityController.text,
          state: _stateController.text,
          // zipCode: _zipController.text,
        );
        addressProvider.updateAddress(updatedAddress);
         // Usar mounted check
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço atualizado!')));
      }
       // Usar mounted check
      if (!mounted) return;
      Navigator.pop(context); // Volta para a tela anterior
    }
  }

  // --- Método Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usa _appBarTitle corretamente
      appBar: AppBar(title: Text(_appBarTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Campos TextFormField (sem alterações) ---
              TextFormField( controller: _streetController, decoration: InputDecoration(labelText: "Rua / Logradouro"), validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null ),
              const SizedBox(height: 16),
              Row( children: [ Expanded( flex: 2, child: TextFormField( controller: _numberController, decoration: InputDecoration(labelText: "Número"), keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null)), const SizedBox(width: 16), Expanded( flex: 3, child: TextFormField( controller: _complementController, decoration: InputDecoration(labelText: "Complemento (Opcional)")))]),
              const SizedBox(height: 16),
              TextFormField( controller: _neighborhoodController, decoration: InputDecoration(labelText: "Bairro"), validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null),
              const SizedBox(height: 16),
              Row( children: [ Expanded( flex: 3, child: TextFormField( controller: _cityController, decoration: InputDecoration(labelText: "Cidade"), validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null)), const SizedBox(width: 16), Expanded( flex: 1, child: TextFormField( controller: _stateController, decoration: InputDecoration(labelText: "UF"), validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null))]),
              // TextFormField( controller: _zipController, decoration: InputDecoration(labelText: "CEP"), /* ... */ ),
              const SizedBox(height: 32),

              // --- ElevatedButton CORRIGIDO ---
              ElevatedButton(
                // <<< CORRIGIDO: Chama a função _saveAddress >>>
                onPressed: _saveAddress,
                // <<< CORRIGIDO: Usa a variável _buttonText >>>
                 style: ElevatedButton.styleFrom( // Adiciona um estilo para o botão
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                 ),
                child: Text(_buttonText),
              ),
              // --- Fim do ElevatedButton ---
            ],
          ),
        ),
      ),
    );
  }
} // Fim da classe _AddNewAddressScreenState