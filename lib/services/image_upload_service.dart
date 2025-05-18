import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart'; // Para nomes de arquivo únicos

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Permite ao utilizador escolher uma imagem da galeria ou câmera.
  /// Retorna o arquivo da imagem selecionada ou null.
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Comprime um pouco a imagem
        maxWidth: 1024,    // Redimensiona se for muito grande
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint("ImageUploadService: Erro ao selecionar imagem: $e");
    }
    return null;
  }

  Future<String?> uploadImage(File imageFile, String path) async {
    try {
      // Gera um nome de arquivo único para evitar sobrescrever
      final String fileName = '${const Uuid().v4()}-${imageFile.path.split('/').last}';
      final Reference storageRef = _storage.ref().child('$path/$fileName');

      debugPrint("ImageUploadService: Fazendo upload de ${imageFile.path} para $path/$fileName...");
      
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint("ImageUploadService: Upload concluído! URL: $downloadUrl");
        return downloadUrl;
      } else {
        debugPrint("ImageUploadService: Upload falhou. Estado: ${snapshot.state}");
        return null;
      }
    } catch (e) {
      debugPrint("ImageUploadService: Erro no upload da imagem: $e");
      return null;
    }
  }

  /// Deleta uma imagem do Firebase Storage usando sua URL de download.
  Future<bool> deleteImageByUrl(String imageUrl) async {
    if (imageUrl.isEmpty || !imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
      debugPrint("ImageUploadService: URL de imagem inválida para exclusão.");
      return false;
    }
    try {
      Reference photoRef = _storage.refFromURL(imageUrl);
      await photoRef.delete();
      debugPrint("ImageUploadService: Imagem $imageUrl deletada do Storage.");
      return true;
    } catch (e) {
      debugPrint("ImageUploadService: Erro ao deletar imagem $imageUrl do Storage: $e");
      return false;
    }
  }
}
