// lib/ui/checkout/add_new_address_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter
import 'package:myapp/model/address.dart';
import 'package:myapp/ui/_core/address_provider.dart';
import 'package:myapp/services/cep_service.dart'; // Importar CepService
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddNewAddressScreen extends StatefulWidget {
  final Address? addressToEdit;
  const AddNewAddressScreen({super.key, this.addressToEdit});

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _zipController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  late String _appBarTitle;
  late String _buttonText;
  bool _isCepLoading = false; // Para o loading da busca de CEP
  bool _isFormSaving = false; // <<< NOVO: Para o loading do botão Salvar

  final CepService _cepService = CepService();

  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      _appBarTitle = "Editar Endereço";
      _buttonText = "Salvar Alterações";
      _zipController.text = widget.addressToEdit!.zipCode;
      _streetController.text = widget.addressToEdit!.street;
      _numberController.text = widget.addressToEdit!.number;
      _complementController.text = widget.addressToEdit!.complement;
      _neighborhoodController.text = widget.addressToEdit!.neighborhood;
      _cityController.text = widget.addressToEdit!.city;
      _stateController.text = widget.addressToEdit!.state;
    } else {
      _appBarTitle = "Adicionar Endereço";
      _buttonText = "Salvar Endereço";
    }

    _zipController.addListener(() {
      final String cep = _zipController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (cep.length == 8 && !_isCepLoading) {
        _fetchAddressByCep(cep);
      }
    });
  }

  @override
  void dispose() {
    _zipController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddressByCep(String cep) async {
    if (!mounted) return;
    setState(() => _isCepLoading = true);

    final Address? fetchedAddress = await _cepService.fetchAddressFromCep(cep);

    if (!mounted) return; 

    if (fetchedAddress != null) {
      _streetController.text = fetchedAddress.street;
      _neighborhoodController.text = fetchedAddress.neighborhood;
      _cityController.text = fetchedAddress.city;
      _stateController.text = fetchedAddress.state;
      _complementController.text = fetchedAddress.complement;
      // Foca no campo número após preencher
      // É uma boa prática dar um pequeno delay para o foco funcionar consistentemente após setState
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusNode()); // Tira o foco do CEP
          // Se quiser focar no campo número:
          // FocusScope.of(context).requestFocus(_numberFocusNode); // Crie um FocusNode para o número
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP não encontrado ou inválido.'), backgroundColor: Colors.orange),
      );
    }
    setState(() => _isCepLoading = false);
  }

  Future<void> _saveAddress() async { // <<< Adicionado async
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() => _isFormSaving = true); // <<< ATIVA LOADING DO FORMULÁRIO

      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      var uuid = const Uuid();

      final addressData = Address(
        id: widget.addressToEdit?.id ?? uuid.v4(),
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        complement: _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
        zipCode: _zipController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      try {
        if (widget.addressToEdit == null) {
          await addressProvider.addAddress(addressData); // <<< await
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço adicionado!')));
        } else {
          await addressProvider.updateAddress(addressData); // <<< await
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endereço atualizado!')));
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar endereço: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isFormSaving = false); // <<< DESATIVA LOADING DO FORMULÁRIO
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _zipController,
                decoration: InputDecoration(
                  labelText: "CEP",
                  hintText: "00000-000",
                  // <<< ÍCONE CORRIGIDO E InputDecorator é const >>>
                  prefixIcon: const Icon(Icons.location_on_outlined), 
                  suffixIcon: _isCepLoading 
                              ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) 
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  tooltip: "Buscar Endereço",
                                  onPressed: () {
                                    final String cep = _zipController.text.replaceAll(RegExp(r'[^0-9]'), '');
                                    if (cep.length == 8) {
                                      _fetchAddressByCep(cep);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digite um CEP válido com 8 dígitos.')));
                                    }
                                  },
                                )
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'CEP é obrigatório';
                  if (v.replaceAll(RegExp(r'[^0-9]'), '').length != 8) return 'CEP deve ter 8 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _streetController, decoration: const InputDecoration(labelText: "Rua / Logradouro"), validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(flex: 2, child: TextFormField(controller: _numberController, decoration: const InputDecoration(labelText: "Número"), keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null)),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: TextFormField(controller: _complementController, decoration: const InputDecoration(labelText: "Complemento (Opcional)"))),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _neighborhoodController, decoration: const InputDecoration(labelText: "Bairro"), validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(flex: 3, child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: "Cidade"), validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null)),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: "UF"), validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null, inputFormatters: [LengthLimitingTextInputFormatter(2)], textCapitalization: TextCapitalization.characters,)),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                // <<< USA _isFormSaving ou _isCepLoading para desabilitar >>>
                onPressed: _isCepLoading || _isFormSaving ? null : _saveAddress, 
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // <<< USA _isFormSaving para mostrar o CircularProgressIndicator >>>
                child: _isFormSaving ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
