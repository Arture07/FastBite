// lib/ui/profile/edit_client_profile_screen.dart
import 'dart:io'; // Para File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Para ImagePicker
import 'package:myapp/ui/_core/auth_provider.dart';
import 'package:myapp/services/image_upload_service.dart'; // Seu serviço de upload
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Para exibir imagem da URL com cache
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

    // Pequeno delay para UX, pode ser removido se o acesso for síncrono rápido
    await Future.delayed(const Duration(milliseconds: 50));

    final authProvider = context.read<AuthProvider>();
    // Os dados do utilizador (incluindo userImagePath) vêm do seu modelo User
    // que é populado no AuthProvider a partir do Firestore.
    // O photoURL do FirebaseUser do AuthProvider pode ser usado como fallback ou fonte primária.
    final userModel = authProvider.currentUser; 
    final firebaseUser = authProvider.firebaseUser; // Opcional, para photoURL direto do Auth

    if (userModel != null) {
      _nameCtrl.text = userModel.name;
      _emailCtrl.text = userModel.email; // Email geralmente não é editável
      // Prioriza a imagem do seu modelo User, depois do FirebaseUser.photoURL
      _currentImageUrl = userModel.userImagePath ?? firebaseUser?.photoURL;
      debugPrint("EditClientProfileScreen: Dados carregados. Nome: ${userModel.name}, Imagem URL: $_currentImageUrl");
    } else {
      // Lidar com caso de utilizador nulo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Utilizador não encontrado para edição.'), backgroundColor: Colors.red),
        );
        // Considerar voltar para a tela anterior se não houver utilizador
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
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Permite ao utilizador escolher uma imagem da galeria ou câmera.
  Future<void> _pickImage(ImageSource source) async {
    final File? image = await _imageUploadService.pickImage(source);
    if (image != null) {
      setState(() {
        _selectedImageFile = image;
        // Opcional: limpar _currentImageUrl para que a UI mostre _selectedImageFile imediatamente
        // _currentImageUrl = null; 
      });
    }
  }

  /// Salva as alterações do perfil.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!mounted) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    // Captura ScaffoldMessenger e Navigator ANTES de operações async
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    String? newImageDownloadUrl = _currentImageUrl; // Mantém a URL atual por padrão

    // 1. Se uma nova imagem foi selecionada, faz o upload
    if (_selectedImageFile != null) {
      debugPrint("EditClientProfile: Nova imagem selecionada, fazendo upload...");
      
      // Opcional: Deletar imagem antiga do Storage se existir e for diferente da padrão
      // Esta lógica pode ser complexa se a imagem padrão for um asset local.
      // Por simplicidade, vamos apenas fazer upload da nova.
      // if (_currentImageUrl != null && _currentImageUrl!.startsWith('https://firebasestorage.googleapis.com')) {
      //   await _imageUploadService.deleteImageByUrl(_currentImageUrl!);
      // }
      
      // Define um caminho no Firebase Storage para perfis de utilizadores
      // Usa o UID do utilizador para garantir que o caminho é único por utilizador
      final String storagePath = 'user_profiles/${authProvider.currentUser!.id}';
      newImageDownloadUrl = await _imageUploadService.uploadImage(_selectedImageFile!, storagePath);

      if (newImageDownloadUrl == null) {
        // Falha no upload, informa o utilizador e não atualiza a imagem
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Erro no upload da nova imagem de perfil. A imagem anterior será mantida (se houver).'), backgroundColor: Colors.orange),
        );
        newImageDownloadUrl = _currentImageUrl; // Reverte para a imagem antiga ou nula
      } else {
         debugPrint("EditClientProfile: Nova imagem de perfil carregada: $newImageDownloadUrl");
      }
    }

    // 2. Atualiza os dados do utilizador (nome e URL da imagem no Auth e Firestore)
    try {
      await authProvider.updateUserProfile(
        name: _nameCtrl.text.trim(),
        photoURL: newImageDownloadUrl, // Passa a nova URL da imagem (pode ser a mesma ou nula)
      );
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
      );
      if (navigator.canPop()) navigator.pop(); // Volta para a tela anterior
    } on fb_auth.FirebaseAuthException catch (e) {
       scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao atualizar perfil: ${e.message ?? "Tente novamente."}'), backgroundColor: Colors.red),
      );
    } 
    catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro desconhecido ao atualizar perfil: ${e.toString()}'), backgroundColor: Colors.red),
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
                                ? FileImage(_selectedImageFile!) // Mostra imagem local selecionada
                                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                    ? (_currentImageUrl!.startsWith('http') // Verifica se é URL de rede
                                        ? CachedNetworkImageProvider(_currentImageUrl!) // Usa CachedNetworkImage para URLs
                                        : AssetImage('assets/$_currentImageUrl') as ImageProvider) // Assume asset local
                                    : const AssetImage('assets/user_placeholder.png') // Imagem padrão de asset
                                  ),
                            child: (_selectedImageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty || !_currentImageUrl!.startsWith('http')))
                                ? Icon(Icons.person, size: 60, color: Colors.grey.shade700) // Ícone se não houver imagem
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
                                              _pickImage(ImageSource.gallery);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.photo_camera),
                                            title: const Text('Tirar Foto'),
                                            onTap: () {
                                              _pickImage(ImageSource.camera);
                                              Navigator.of(context).pop();
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
                      enabled: false, // Email não é editável
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