// lib/ui/restaurant_profile/edit_restaurant_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/data/restaurant_data.dart';
import 'package:myapp/model/restaurant.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/services/image_upload_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditRestaurantProfileScreen extends StatefulWidget {
  const EditRestaurantProfileScreen({super.key});

  @override
  State<EditRestaurantProfileScreen> createState() => _EditRestaurantProfileScreenState();
}

class _EditRestaurantProfileScreenState extends State<EditRestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  // _imagePathCtrl agora guarda a URL da imagem do Storage ou o caminho do asset
  final _imagePathCtrl = TextEditingController(); 
  // TODO: Adicionar controllers para categorias do restaurante, distância, etc.

  bool _isLoading = false;
  bool _isDataLoading = true;
  Restaurant? _currentRestaurantData; // Para guardar os dados originais do restaurante

  File? _selectedImageFile;
  String? _currentImageUrlForDisplay;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    if (!mounted) return;
    setState(() => _isDataLoading = true);
    await Future.delayed(const Duration(milliseconds: 50)); // Pequeno delay para UX

    final authProvider = context.read<AuthProvider>();
    final restaurantData = context.read<RestaurantData>();
    final restaurantId = authProvider.currentUser?.id; // ID do restaurante é o ID do utilizador

    if (restaurantId != null) {
      try {
        // Encontra o restaurante na lista do provider
        // Garante que a lista de restaurantes no provider está carregada
        if (!restaurantData.isLoaded) {
           await restaurantData.loadRestaurants();
        }
        _currentRestaurantData = restaurantData.listRestaurant.firstWhere((r) => r.id == restaurantId);
        
        _nameCtrl.text = _currentRestaurantData!.name;
        _descCtrl.text = _currentRestaurantData!.description;
        _imagePathCtrl.text = _currentRestaurantData!.imagePath; // URL do Storage ou caminho do asset
        _currentImageUrlForDisplay = _currentRestaurantData!.imagePath;
        // TODO: Preencher outros controllers (categorias, etc.)
      } catch (e) {
        debugPrint("EditRestaurantProfileScreen: Erro ao carregar dados do restaurante $restaurantId: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao carregar dados do restaurante.'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Não foi possível identificar o restaurante.'), backgroundColor: Colors.red),
        );
         if (Navigator.canPop(context)) Navigator.pop(context);
      }
    }
    if (mounted) {
      setState(() => _isDataLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imagePathCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final File? image = await _imageUploadService.pickImage(source);
    if (image != null) {
      setState(() {
        _selectedImageFile = image;
        _currentImageUrlForDisplay = null; 
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _currentRestaurantData == null) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String finalImagePath = _currentRestaurantData!.imagePath; // Imagem atual como padrão

    if (_selectedImageFile != null) {
      debugPrint("EditRestaurantProfile: Nova imagem selecionada, fazendo upload...");
      // Opcional: Deletar imagem antiga do Storage
      if (_currentRestaurantData!.imagePath.startsWith('https://firebasestorage.googleapis.com')) {
        // await _imageUploadService.deleteImageByUrl(_currentRestaurantData!.imagePath);
      }
      
      // Caminho no Storage para imagens de perfil de restaurante
      final String storagePath = 'restaurant_profiles/${_currentRestaurantData!.id}';
      final String? uploadedImageUrl = await _imageUploadService.uploadImage(_selectedImageFile!, storagePath);
      
      if (uploadedImageUrl != null) {
        finalImagePath = uploadedImageUrl;
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Erro no upload da nova imagem. Usando imagem anterior/padrão.'), backgroundColor: Colors.orange),
        );
        // Mantém a imagem antiga se o upload falhar
      }
    }

    final updatedRestaurant = _currentRestaurantData!.copyWith(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      imagePath: finalImagePath, // Nova URL ou a antiga
      // TODO: Atualizar outros campos como categorias, distância, etc.
    );

    try {
      await context.read<RestaurantData>().updateRestaurantProfile(updatedRestaurant);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Perfil do restaurante atualizado com sucesso!'), backgroundColor: Colors.green),
      );
      if (navigator.canPop()) navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil do restaurante: ${e.toString()}'), backgroundColor: Colors.red),
      );
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
                    Center( // Para a imagem de perfil/banner do restaurante
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container( // Container para a imagem
                            width: double.infinity,
                            height: 180, // Altura desejada para o banner/imagem
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                              image: _selectedImageFile != null
                                  ? DecorationImage(image: FileImage(_selectedImageFile!), fit: BoxFit.cover)
                                  : (_currentImageUrlForDisplay != null && _currentImageUrlForDisplay!.isNotEmpty
                                      ? DecorationImage(
                                          image: _currentImageUrlForDisplay!.startsWith('http')
                                              ? CachedNetworkImageProvider(_currentImageUrlForDisplay!)
                                              : AssetImage('assets/$_currentImageUrlForDisplay!') as ImageProvider,
                                          fit: BoxFit.cover,
                                          onError: (err, stack) => const Icon(Icons.storefront, size: 60, color: Colors.grey), // Fallback de erro
                                        )
                                      : null // Sem imagem se _currentImageUrlForDisplay for nulo/vazio
                                    ),
                            ),
                            child: (_selectedImageFile == null && (_currentImageUrlForDisplay == null || _currentImageUrlForDisplay!.isEmpty))
                                ? Center(child: Icon(Icons.storefront_outlined, size: 70, color: Colors.grey.shade700))
                                : null,
                          ),
                          Material(
                            color: theme.colorScheme.primary,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              onTap: _isLoading ? null : () { /* ... _showImageSourceActionSheet ... */ 
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext bc) {
                                    return SafeArea(
                                      child: Wrap(
                                        children: <Widget>[
                                          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeria'), onTap: () { _pickImage(ImageSource.gallery); Navigator.of(context).pop(); }),
                                          ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Câmera'), onTap: () { _pickImage(ImageSource.camera); Navigator.of(context).pop(); }),
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
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(controller: _nameCtrl, enabled: !_isLoading, decoration: const InputDecoration(labelText: "Nome do Restaurante", border: OutlineInputBorder(), prefixIcon: Icon(Icons.storefront_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null, textInputAction: TextInputAction.next),
                    const SizedBox(height: 16),
                    TextFormField(controller: _descCtrl, enabled: !_isLoading, decoration: const InputDecoration(labelText: "Descrição", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Descrição é obrigatória' : null, textInputAction: TextInputAction.next, maxLines: 3, minLines: 1),
                    const SizedBox(height: 16),
                    // TODO: Adicionar campos para categorias do restaurante, distância, etc.
                    // Exemplo para categorias (string separada por vírgula, precisaria de lógica de parse/join):
                    // TextFormField(controller: _categoriesCtrl, decoration: InputDecoration(labelText: "Categorias (separadas por vírgula)")),
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