// lib/ui/restaurant_menu/add_edit_dish_screen.dart
import 'dart:io'; // Para usar File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // <<< IMPORTAR IMAGE_PICKER
import 'package:myapp/data/categories_data.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/services/image_upload_service.dart'; // <<< IMPORTAR SERVIÇO DE UPLOAD
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddEditDishScreen extends StatefulWidget {
  final String restaurantId;
  final Dish? dishToEdit;

  const AddEditDishScreen({
    super.key,
    required this.restaurantId,
    this.dishToEdit,
  });

  @override
  State<AddEditDishScreen> createState() => _AddEditDishScreenState();
}

class _AddEditDishScreenState extends State<AddEditDishScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  // _imagePathCtrl agora guarda a URL da imagem do Storage ou o caminho do asset
  final _imagePathCtrl = TextEditingController(); 
  
  List<String> _selectedDishCategories = [];
  final List<String> _allAvailableCategories = CategoriesData.listCategories;

  bool _isEditing = false;
  bool _isLoading = false;

  // <<< NOVO: Para a imagem selecionada localmente >>>
  File? _selectedImageFile;
  // <<< NOVO: Instância do serviço de upload >>>
  final ImageUploadService _imageUploadService = ImageUploadService();
  String? _currentImageUrlForDisplay; // Para exibir a imagem atual ou a nova

  @override
  void initState() {
    super.initState();
    _isEditing = widget.dishToEdit != null;
    if (_isEditing) {
      _nameCtrl.text = widget.dishToEdit!.name;
      _descCtrl.text = widget.dishToEdit!.description;
      _priceCtrl.text = (widget.dishToEdit!.price / 100).toStringAsFixed(2).replaceAll('.', ',');
      _imagePathCtrl.text = widget.dishToEdit!.imagePath; // URL do Storage ou caminho do asset
      _currentImageUrlForDisplay = widget.dishToEdit!.imagePath;
      _selectedDishCategories = List<String>.from(widget.dishToEdit!.categories);
    } else {
      // _imagePathCtrl.text = 'assets/dishes/default_dish.png'; // Caminho padrão para asset
      // _currentImageUrlForDisplay = 'assets/dishes/default_dish.png';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imagePathCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndSetImage(ImageSource source) async {
    final File? image = await _imageUploadService.pickImage(source);
    if (image != null) {
      setState(() {
        _selectedImageFile = image;
        _currentImageUrlForDisplay = null; // Limpa URL antiga para mostrar a nova imagem local
      });
    }
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDishCategories.isEmpty) {
      // ... (mostrar SnackBar de erro) ...
      return;
    }

    setState(() => _isLoading = true);
    String finalImagePath = _imagePathCtrl.text; // Mantém o caminho/URL existente por padrão

    // 1. Se uma nova imagem foi selecionada, faz o upload
    if (_selectedImageFile != null) {
      // Se estava editando e tinha uma imagem antiga no Storage, pode deletá-la
      if (_isEditing && widget.dishToEdit!.imagePath.startsWith('https://firebasestorage.googleapis.com')) {
        await _imageUploadService.deleteImageByUrl(widget.dishToEdit!.imagePath);
      }
      // Faz upload da nova imagem
      // O caminho no Storage pode ser 'dishes/{restaurantId}/{dishId_ou_nomeUnico}'
      final String storagePath = 'dish_images/${widget.restaurantId}';
      final String? uploadedImageUrl = await _imageUploadService.uploadImage(_selectedImageFile!, storagePath);
      
      if (uploadedImageUrl != null) {
        finalImagePath = uploadedImageUrl; // Usa a nova URL do Storage
      } else {
        // Falha no upload, decide como tratar (ex: usar imagem padrão, mostrar erro)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro no upload da imagem. Usando imagem anterior/padrão.'), backgroundColor: Colors.orange),
          );
        }
        // Mantém finalImagePath como estava ou define um padrão se for um prato novo sem imagem
        if (!_isEditing) finalImagePath = 'assets/dishes/default_dish.png';
      }
    }


    int priceInCents = 0;
    try {
      String priceText = _priceCtrl.text.trim().replaceAll(',', '.');
      double priceDouble = double.parse(priceText);
      priceInCents = (priceDouble * 100).round();
      if (priceInCents < 0) throw const FormatException("Preço não pode ser negativo.");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formato de preço inválido.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    final restaurantData = context.read<RestaurantData>();

    try {
      if (_isEditing) {
        final updatedDish = widget.dishToEdit!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: priceInCents,
          imagePath: finalImagePath, // <<< USA A URL DO STORAGE OU CAMINHO DO ASSET
          categories: _selectedDishCategories,
        );
        await restaurantData.updateDishInRestaurant(widget.restaurantId, updatedDish);
        // ... (SnackBar e pop) ...
      } else {
        final newDish = Dish(
          id: const Uuid().v4(),
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: priceInCents,
          imagePath: finalImagePath, // <<< USA A URL DO STORAGE OU CAMINHO DO ASSET
          categories: _selectedDishCategories,
        );
        await restaurantData.addDishToRestaurant(widget.restaurantId, newDish);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prato adicionado!')));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar prato: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Editar Prato" : "Adicionar Novo Prato"),
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: "Salvar Prato",
            onPressed: _isLoading ? null : _saveDish,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Campo Nome do Prato ---
              TextFormField(
                controller: _nameCtrl,
                enabled: !_isLoading, // Desabilita no loading
                decoration: const InputDecoration(
                  labelText: "Nome do Prato",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood_outlined),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Nome é obrigatório'
                            : null,
                textInputAction:
                    TextInputAction.next, // Foco vai para o próximo campo
              ),
              const SizedBox(height: 16),

              // --- Campo Descrição ---
              TextFormField(
                controller: _descCtrl,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: "Descrição",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Descrição é obrigatória'
                            : null,
                textInputAction: TextInputAction.next,
                maxLines: 3, // Permite múltiplas linhas
                minLines: 1,
              ),
              const SizedBox(height: 16),

              // --- Campo Preço ---
              TextFormField(
                controller: _priceCtrl,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: "Preço (Ex: 29,90)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  // Validação de formato e valor
                  if (v == null || v.trim().isEmpty) {
                    return 'Preço é obrigatório';
                  }
                  final priceRegExp = RegExp(
                    r'^\d+([,.]\d{1,2})?$',
                  ); // Aceita 10 ou 10,00 ou 10.00
                  if (!priceRegExp.hasMatch(v.trim())) {
                    return 'Formato inválido (use 00,00)';
                  }
                  try {
                    double priceDouble = double.parse(
                      v.trim().replaceAll(',', '.'),
                    );
                    if (priceDouble < 0) return 'Preço não pode ser negativo';
                  } catch (e) {
                    return 'Número inválido';
                  }
                  return null; // Válido
                },
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ), // Teclado numérico
                // Permite apenas números, vírgula e ponto
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                ],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // --- Campo Caminho da Imagem ---
              Text("Imagem do Prato", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImageFile != null
                    ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                    : (_currentImageUrlForDisplay != null && _currentImageUrlForDisplay!.isNotEmpty)
                        ? (_currentImageUrlForDisplay!.startsWith('http')
                            ? Image.network(_currentImageUrlForDisplay!, fit: BoxFit.cover, 
                                errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.broken_image, size: 40)))
                            : Image.asset('assets/${_currentImageUrlForDisplay!}', fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.image_not_supported, size: 40)))
                          )
                        : const Center(child: Icon(Icons.image_outlined, size: 50, color: Colors.grey)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text("Galeria"),
                    onPressed: () => _pickAndSetImage(ImageSource.gallery),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text("Câmera"),
                    onPressed: () => _pickAndSetImage(ImageSource.camera),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- FIM SELEÇÃO DE IMAGEM --
              Text(
                "Categorias do Prato (selecione uma ou mais):",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap( // Permite que os chips quebrem linha
                spacing: 8.0, // Espaço horizontal entre chips
                runSpacing: 4.0, // Espaço vertical entre linhas de chips
                children: _allAvailableCategories.map((categoryName) {
                  final bool isSelected = _selectedDishCategories.contains(categoryName);
                  return FilterChip(
                    label: Text(categoryName),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedDishCategories.add(categoryName);
                        } else {
                          _selectedDishCategories.remove(categoryName);
                        }
                      });
                    },
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                    ),
                    backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400)),
                  );
                }).toList(),
              ),
              // --- FIM SELEÇÃO DE CATEGORIAS ---

              const SizedBox(height: 24),
              // --- Botão Salvar ---
              ElevatedButton.icon(
                icon:
                    _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.save), // Esconde ícone no loading
                label:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ) // Loading
                        : Text(
                          _isEditing ? "Salvar Alterações" : "Adicionar Prato",
                        ), // Texto dinâmico
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed:
                    _isLoading ? null : _saveDish, // Chama a função de salvar
              ),
            ],
          ),
        ),
      ),
    );
  }
}