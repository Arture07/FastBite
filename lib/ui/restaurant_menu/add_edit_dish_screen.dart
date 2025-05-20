// lib/ui/restaurant_menu/add_edit_dish_screen.dart
import 'dart:io'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/data/categories_data.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/model/dish.dart';
import 'package:myapp/services/image_upload_service.dart';
import 'package:myapp/services/error_handler.dart'; // Para tratar erros
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Para exibir imagem da rede

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
  // _imagePathCtrl não é mais usado para input direto, mas pode ser útil para debug
  // final _imagePathCtrl = TextEditingController(); 
  
  List<String> _selectedDishCategories = [];
  final List<String> _allAvailableCategories = CategoriesData.listCategories;

  bool _isEditing = false;
  bool _isLoading = false;

  File? _selectedImageFile; // Para a nova imagem selecionada localmente
  String? _currentDishImageUrl; // Para a URL da imagem existente (se houver)
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.dishToEdit != null;
    if (_isEditing) {
      final dish = widget.dishToEdit!;
      _nameCtrl.text = dish.name;
      _descCtrl.text = dish.description;
      _priceCtrl.text = (dish.price / 100.0).toStringAsFixed(2).replaceAll('.', ',');
      _currentDishImageUrl = dish.imagePath; // Guarda a URL/caminho atual
      _selectedDishCategories = List<String>.from(dish.categories);
    } else {
      // Para um novo prato, você pode definir uma imagem padrão de asset se quiser
      // _currentDishImageUrl = 'assets/dishes/default_dish.png'; 
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    // _imagePathCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    try {
      final File? image = await _imageUploadService.pickImage(source);
      if (image != null) {
        setState(() {
          _selectedImageFile = image;
          // Opcional: se quiser que a UI mostre a imagem local imediatamente
          // _currentDishImageUrl = null; 
        });
      }
    } catch (e) {
      if (mounted) ErrorHandler.handleGenericError(context, e, operation: "selecionar imagem para o prato");
    }
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDishCategories.isEmpty) {
      if (mounted) ErrorHandler.handleGenericError(context, "Selecione pelo menos uma categoria para o prato.");
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context); // Captura antes de async
    String finalImagePath = _currentDishImageUrl ?? 'assets/dishes/default_dish.png'; // Fallback para imagem padrão

    // 1. Upload da nova imagem, se selecionada
    if (_selectedImageFile != null) {
      try {
        final String storagePath = 'dish_images/${widget.restaurantId}';
        // Deleta a imagem antiga do Storage se ela existir e for uma URL do Firebase Storage
        if (_currentDishImageUrl != null && _currentDishImageUrl!.startsWith('https://firebasestorage.googleapis.com')) {
          await _imageUploadService.deleteImageByUrl(_currentDishImageUrl!);
        }
        // Faz upload da nova imagem. O nome do arquivo será gerado pelo serviço (UUID).
        finalImagePath = await _imageUploadService.uploadImage(_selectedImageFile!, storagePath);
      } on FirebaseException catch (e) {
        if (mounted) ErrorHandler.handleFirebaseStorageError(context, e, operation: "upload da imagem do prato");
        setState(() => _isLoading = false); return; // Para a execução se o upload falhar
      } catch (e) {
        if (mounted) ErrorHandler.handleGenericError(context, e, operation: "upload da imagem do prato");
        setState(() => _isLoading = false); return; // Para a execução se o upload falhar
      }
    }

    // 2. Conversão do preço para centavos
    int priceInCents = 0;
    try {
      priceInCents = (double.parse(_priceCtrl.text.trim().replaceAll(',', '.')) * 100).round();
      if (priceInCents < 0) throw const FormatException("Preço não pode ser negativo.");
    } catch (e) {
      if (mounted) ErrorHandler.handleGenericError(context, "Formato de preço inválido.");
      setState(() => _isLoading = false); return;
    }

    final restaurantData = context.read<RestaurantData>();

    try {
      if (_isEditing) {
        final updatedDish = widget.dishToEdit!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: priceInCents,
          imagePath: finalImagePath,
          categories: _selectedDishCategories,
          // Campos de avaliação são mantidos, pois são atualizados por outra lógica
          averageRating: widget.dishToEdit!.averageRating,
          ratingCount: widget.dishToEdit!.ratingCount,
        );
        await restaurantData.updateDishInRestaurant(widget.restaurantId, updatedDish);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prato atualizado com sucesso!'), backgroundColor: Colors.green,));
        }
      } else {
        final newDish = Dish(
          id: const Uuid().v4(),
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: priceInCents,
          imagePath: finalImagePath,
          categories: _selectedDishCategories,
          averageRating: 0.0, // Inicializa avaliação para novos pratos
          ratingCount: 0,   // Inicializa contagem
        );
        await restaurantData.addDishToRestaurant(widget.restaurantId, newDish);
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prato adicionado com sucesso!'), backgroundColor: Colors.green,));
        }
      }
      if (mounted && navigator.canPop()) navigator.pop(); // Volta para a tela anterior
    } catch (e) {
      // O erro já deve ter sido lançado e tratado pelo ErrorHandler se veio do provider
      // Mas podemos adicionar um handler genérico aqui para o caso de outras exceções
      if (mounted) ErrorHandler.handleGenericError(context, e, operation: "salvar prato");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              // Seletor de Imagem
              Text("Imagem do Prato", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: _selectedImageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(7.0), child: Image.file(_selectedImageFile!, fit: BoxFit.cover))
                    : (_currentDishImageUrl != null && _currentDishImageUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7.0),
                            child: _currentDishImageUrl!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: _currentDishImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                                  )
                                : Image.asset( // Se for um caminho de asset
                                    _currentDishImageUrl!, // Assume que já tem 'assets/' se necessário
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey)),
                                  ),
                          )
                        : const Center(child: Icon(Icons.image_outlined, size: 50, color: Colors.grey)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(icon: const Icon(Icons.photo_library_outlined), label: const Text("Galeria"), onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery)),
                  TextButton.icon(icon: const Icon(Icons.camera_alt_outlined), label: const Text("Câmera"), onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Campos do Formulário
              TextFormField(controller: _nameCtrl, enabled: !_isLoading, decoration: const InputDecoration(labelText: "Nome do Prato", border: OutlineInputBorder(), prefixIcon: Icon(Icons.fastfood_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null, textInputAction: TextInputAction.next),
              const SizedBox(height: 16),
              TextFormField(controller: _descCtrl, enabled: !_isLoading, decoration: const InputDecoration(labelText: "Descrição", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Descrição é obrigatória' : null, textInputAction: TextInputAction.next, maxLines: 3, minLines: 1),
              const SizedBox(height: 16),
              TextFormField(controller: _priceCtrl, enabled: !_isLoading, decoration: const InputDecoration(labelText: "Preço (Ex: 29,90)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)), validator: (v) { if (v == null || v.trim().isEmpty) return 'Preço é obrigatório'; final priceRegExp = RegExp(r'^\d+([,.]\d{1,2})?$'); if (!priceRegExp.hasMatch(v.trim())) return 'Formato inválido (use 00,00)'; try { double priceDouble = double.parse(v.trim().replaceAll(',', '.')); if (priceDouble < 0) return 'Preço não pode ser negativo'; } catch (e) { return 'Número inválido'; } return null; }, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))], textInputAction: TextInputAction.next),
              const SizedBox(height: 24),

              // Seleção de Categorias do Prato
              Text("Categorias do Prato:", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0, 
                runSpacing: 4.0,
                children: _allAvailableCategories.map((categoryName) {
                  final bool isSelected = _selectedDishCategories.contains(categoryName);
                  return FilterChip(
                    label: Text(categoryName),
                    selected: isSelected,
                    onSelected: _isLoading ? null : (bool selected) {
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
                    labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color),
                    backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    shape: theme.chipTheme.shape as OutlinedBorder? ?? StadiumBorder(side: BorderSide(color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Botão Salvar
              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? "Salvar Alterações" : "Adicionar Prato"),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _isLoading ? null : _saveDish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}