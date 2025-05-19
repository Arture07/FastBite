// lib/ui/profile/edit_client_profile_screen.dart
import 'dart:io'; // Para File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/services/error_handler.dart';
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/services/image_upload_service.dart'; // Seu serviço de upload
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Para FirebaseAuthException

class EditClientProfileScreen extends StatefulWidget {
  const EditClientProfileScreen({super.key});

  @override
  State<EditClientProfileScreen> createState() => _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends State<EditClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // Email não será editável

  bool _isLoading = false; // Para o botão Salvar
  bool _isDataLoading = true; // Para o carregamento inicial dos dados

  File? _selectedImageFile; // Arquivo da nova imagem selecionada localmente
  String? _currentImageUrl;   // URL da imagem atual vinda do Firestore/Auth
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isDataLoading = true);
    await Future.delayed(const Duration(milliseconds: 50)); 
    final authProvider = context.read<AuthProvider>();
    final userModel = authProvider.currentUser; 
    final firebaseUser = authProvider.firebaseUser; 
    if (userModel != null) {
      _nameCtrl.text = userModel.name;
      _emailCtrl.text = userModel.email; 
      _currentImageUrl = userModel.userImagePath ?? firebaseUser?.photoURL;
    } else {
      if (mounted) {
        ErrorHandler.handleGenericError(context, "Utilizador não encontrado para edição.");
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    }
    if (mounted) setState(() => _isDataLoading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context); // Captura antes do async
    String? newImageDownloadUrl = _currentImageUrl;

    if (authProvider.currentUser == null || authProvider.currentUser!.id.isEmpty) {
      if (mounted) ErrorHandler.handleGenericError(context, "ID do utilizador não disponível.");
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (_selectedImageFile != null) {
      try {
        final String storagePath = 'user_profiles/${authProvider.currentUser!.id}';
        if (_currentImageUrl != null && _currentImageUrl!.startsWith('https://firebasestorage.googleapis.com')) {
          await _imageUploadService.deleteImageByUrl(_currentImageUrl!);
        }
        newImageDownloadUrl = await _imageUploadService.uploadImage(
          _selectedImageFile!,
          storagePath,
          fileName: 'profile_picture.jpg'
        );
      } on fb_auth.FirebaseException catch (e) { // Erro específico do Storage
        if (mounted) ErrorHandler.handleFirebaseStorageError(context, e, operation: "upload da foto de perfil");
        newImageDownloadUrl = _currentImageUrl; // Mantém a antiga se o upload falhar
      } catch (e) { // Outros erros no upload
        if (mounted) ErrorHandler.handleGenericError(context, e, operation: "upload da foto de perfil");
        newImageDownloadUrl = _currentImageUrl;
      }
    }

    // Só prossegue para atualizar perfil se o upload foi bem-sucedido (ou não houve nova imagem)
    // Se newImageDownloadUrl for nulo após uma tentativa de upload, significa que falhou.
    // A mensagem de erro do upload já foi mostrada.
    // Se _selectedImageFile era nulo, newImageDownloadUrl será _currentImageUrl.

    try {
      await authProvider.updateUserProfile(
        name: _nameCtrl.text.trim(),
        photoURL: newImageDownloadUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( // SnackBar de sucesso direto
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        if (navigator.canPop()) navigator.pop();
      }
    } on fb_auth.FirebaseAuthException catch (e) { // Erro do Auth
      if (mounted) ErrorHandler.handleGenericError(context, e, operation: "atualizar perfil (Auth)"); // Pode criar um handler específico para Auth
    } catch (e) { // Erro do Firestore (via AuthProvider) ou outro
      if (mounted) ErrorHandler.handleGenericError(context, e, operation: "atualizar perfil");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
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
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!)
                                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                    ? (_currentImageUrl!.startsWith('http')
                                        ? CachedNetworkImageProvider(_currentImageUrl!)
                                        : AssetImage('assets/$_currentImageUrl') as ImageProvider) 
                                    : const AssetImage('assets/user_placeholder.png') 
                                  ),
                            child: (_selectedImageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty || !_currentImageUrl!.startsWith('http')))
                                ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
                                : null,
                          ),
                          Material(
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
                                          ListTile(
                                            leading: const Icon(Icons.photo_library),
                                            title: const Text('Escolher da Galeria'),
                                            onTap: () {
                                              Navigator.of(context).pop(); // Fecha o bottom sheet primeiro
                                              _pickImage(ImageSource.gallery);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.photo_camera),
                                            title: const Text('Tirar Foto'),
                                            onTap: () {
                                              Navigator.of(context).pop(); // Fecha o bottom sheet primeiro
                                              _pickImage(ImageSource.camera);
                                            },
                                          ),
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
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      enabled: false, 
                      decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                    ),
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
