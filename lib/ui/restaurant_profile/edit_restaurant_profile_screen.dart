import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/services/error_handler.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/services/image_upload_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage; // Para FirebaseException do Storage

class EditRestaurantProfileScreen extends StatefulWidget {
  const EditRestaurantProfileScreen({super.key});

  @override
  State<EditRestaurantProfileScreen> createState() => _EditRestaurantProfileScreenState();
}

class _EditRestaurantProfileScreenState extends State<EditRestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _isDataLoading = true;
  Restaurant? _currentRestaurantDataForEdit; 

  File? _selectedImageFile;
  String? _currentImageUrlForDisplay; 
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    // ... (código _loadRestaurantData como no artefato edit_restaurant_profile_image_v3)
    if (!mounted) return;
    setState(() => _isDataLoading = true);
    await Future.delayed(const Duration(milliseconds: 50));
    final authProvider = context.read<AuthProvider>();
    final restaurantData = context.read<RestaurantData>();
    final restaurantId = authProvider.currentUser?.id; 
    if (restaurantId != null) {
      try {
        if (!restaurantData.isLoaded) await restaurantData.loadRestaurants();
        _currentRestaurantDataForEdit = restaurantData.listRestaurant.firstWhere((r) => r.id == restaurantId);
        _nameCtrl.text = _currentRestaurantDataForEdit!.name;
        _descCtrl.text = _currentRestaurantDataForEdit!.description;
        _currentImageUrlForDisplay = _currentRestaurantDataForEdit!.imagePath;
      } catch (e) {
        if (mounted) ErrorHandler.handleGenericError(context, e, operation: "carregar dados do restaurante");
      }
    } else {
      if (mounted) ErrorHandler.handleGenericError(context, "Não foi possível identificar o restaurante.");
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    }
    if (mounted) setState(() => _isDataLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    // ... (código _pickImage como no artefato edit_restaurant_profile_image_v3)
    try {
      final File? image = await _imageUploadService.pickImage(source);
      if (image != null) {
        setState(() { _selectedImageFile = image; });
      }
    } catch (e) {
      if (mounted) ErrorHandler.handleGenericError(context, e, operation: "selecionar imagem");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _currentRestaurantDataForEdit == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context); // Captura antes do async
    String finalImagePath = _currentRestaurantDataForEdit!.imagePath; 

    if (_selectedImageFile != null) {
      try {
        final String storagePath = 'restaurant_profiles/${_currentRestaurantDataForEdit!.id}';
        if (_currentRestaurantDataForEdit!.imagePath.startsWith('https://firebasestorage.googleapis.com')) {
           await _imageUploadService.deleteImageByUrl(_currentRestaurantDataForEdit!.imagePath);
        }
        final String? uploadedImageUrl = await _imageUploadService.uploadImage(
          _selectedImageFile!, 
          storagePath, 
          fileName: 'profile_banner.jpg'
        );
        if (uploadedImageUrl != null) {
          finalImagePath = uploadedImageUrl;
        } else {
          // O ErrorHandler já deve ter sido chamado dentro de uploadImage se foi FirebaseException
          // Mas podemos mostrar uma mensagem genérica aqui se ele retornou null por outro motivo
          if (mounted) ErrorHandler.handleGenericError(context, "Falha no upload da imagem. Usando imagem anterior.");
        }
      } on fb_storage.FirebaseException catch (e) {
        if (mounted) ErrorHandler.handleFirebaseStorageError(context, e, operation: "upload da imagem do restaurante");
        // Mantém a imagem antiga em caso de erro no upload
      } catch (e) {
        if (mounted) ErrorHandler.handleGenericError(context, e, operation: "upload da imagem do restaurante");
      }
    }

    final updatedRestaurant = _currentRestaurantDataForEdit!.copyWith(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imagePath: finalImagePath,
    );

    try {
      await context.read<RestaurantData>().updateRestaurantProfile(updatedRestaurant);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil do restaurante atualizado!'), backgroundColor: Colors.green),
        );
        if (navigator.canPop()) navigator.pop();
      }
    } catch (e) {
      if (mounted) ErrorHandler.handleGenericError(context, e, operation: "salvar perfil do restaurante");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI como no artefato edit_restaurant_profile_image_v3)
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil do Restaurante"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: "Salvar Alterações",
            onPressed: _isLoading || _isDataLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Imagem Principal / Banner", style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      height: 180, 
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _selectedImageFile != null
                              ? Image.file(_selectedImageFile!, width: double.infinity, height: 180, fit: BoxFit.cover)
                              : (_currentImageUrlForDisplay != null && _currentImageUrlForDisplay!.isNotEmpty)
                                  ? ClipRRect( 
                                      borderRadius: BorderRadius.circular(7.0), 
                                      child: CachedNetworkImage(
                                        imageUrl: _currentImageUrlForDisplay!,
                                        width: double.infinity,
                                        height: 180,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) {
                                          return Image.asset('assets/${_currentImageUrlForDisplay!}',
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.storefront_outlined, size: 60, color: Colors.grey)),
                                          );
                                        }
                                      ),
                                    )
                                  : const Center(child: Icon(Icons.storefront_outlined, size: 70, color: Colors.grey)),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Material(
                              color: theme.colorScheme.primary,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                onTap: _isLoading ? null : () { 
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext bc) {
                                      return SafeArea(
                                        child: Wrap(
                                          children: <Widget>[
                                            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeria'), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.gallery); }),
                                            ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Câmera'), onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.camera); }),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                customBorder: const CircleBorder(),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(Icons.edit, size: 20, color: theme.colorScheme.onPrimary),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(controller: _nameCtrl, enabled: !_isLoading, decoration: const InputDecoration(labelText: "Nome do Restaurante", border: OutlineInputBorder(), prefixIcon: Icon(Icons.storefront_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null, textInputAction: TextInputAction.next),
                    const SizedBox(height: 16),
                    TextFormField(controller: _descCtrl, enabled: !_isLoading, decoration: const InputDecoration(labelText: "Descrição", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Descrição é obrigatória' : null, textInputAction: TextInputAction.next, maxLines: 3, minLines: 1),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
                      label: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Salvar Alterações"),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _isLoading || _isDataLoading ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
