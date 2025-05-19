// lib/services/image_upload_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart'; // Para nomes de arquivo únicos

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Permite ao utilizador escolher uma imagem da galeria ou câmera.
  Future<File?> pickImage(ImageSource source, {int imageQuality = 70, double maxWidth = 1024}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      debugPrint("ImageUploadService: Erro ao selecionar imagem: $e");
      // Opcional: relançar uma exceção customizada ou retornar null
      // throw Exception("Falha ao selecionar imagem: ${e.toString()}");
    }
    return null;
  }

  /// Faz upload de um arquivo de imagem para o Firebase Storage.
  /// [imageFile]: O arquivo da imagem a ser carregada.
  /// [path]: O caminho no Storage onde a imagem será salva (ex: 'user_profiles', 'restaurant_banners').
  /// [fileName]: Opcional. O nome do arquivo no Storage. Se nulo, um UUID com a extensão original será gerado.
  /// Retorna a URL de download da imagem ou lança uma exceção em caso de erro.
  Future<String> uploadImage(File imageFile, String path, {String? fileName}) async {
    if (path.isEmpty || path.endsWith('/')) {
      final errorMsg = "ImageUploadService: ERRO - Caminho (path) inválido ou terminando com /: '$path'";
      debugPrint(errorMsg);
      throw ArgumentError(errorMsg);
    }
    
    final String? effectiveInputFileName = (fileName != null && fileName.trim().isNotEmpty) ? fileName.trim() : null;

    try {
      String finalFileName;
      String fileExtension = imageFile.path.split('.').lastOrNull?.toLowerCase() ?? 'jpg';
      if (fileExtension.isEmpty || fileExtension.length > 4 || !['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        fileExtension = 'jpg'; // Fallback para jpg se a extensão for estranha ou ausente
      }

      if (effectiveInputFileName != null) {
        if (effectiveInputFileName.contains('.')) {
          finalFileName = effectiveInputFileName;
        } else {
          finalFileName = '$effectiveInputFileName.$fileExtension';
        }
      } else {
        finalFileName = '${const Uuid().v4()}.$fileExtension';
      }
      
      final String fullStoragePath = '$path/$finalFileName'; 
      final Reference storageRef = _storage.ref().child(fullStoragePath);

      debugPrint("ImageUploadService: Iniciando upload de ${imageFile.path} para $fullStoragePath...");
      
      String contentType = 'image/jpeg'; // Padrão
      if (finalFileName.endsWith('.png')) {
        contentType = 'image/png';
      } else if (finalFileName.endsWith('.gif')) {
        contentType = 'image/gif';
      }

      UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: contentType),
      );
      
      TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint("ImageUploadService: Upload concluído! URL: $downloadUrl");
        return downloadUrl;
      } else {
        debugPrint("ImageUploadService: Upload falhou. Estado: ${snapshot.state}. Bytes transferidos: ${snapshot.bytesTransferred}/${snapshot.totalBytes}");
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message: 'O upload da imagem falhou com estado: ${snapshot.state}',
        );
      }
    } on FirebaseException catch (e) { 
      debugPrint("ImageUploadService: ERRO DETALHADO Firebase no upload: $e");
      debugPrint("ImageUploadService: Código do erro: ${e.code}");
      debugPrint("ImageUploadService: Mensagem do erro: ${e.message}");
      throw e; // Relança a FirebaseException para ser tratada pela UI
    } 
    catch (e, s) { 
      debugPrint("ImageUploadService: Erro GERAL no upload da imagem: $e");
      debugPrint("ImageUploadService: Stacktrace do erro geral: $s");
      throw Exception("Erro desconhecido durante o upload da imagem: ${e.toString()}");
    }
  }

  /// Deleta uma imagem do Firebase Storage usando sua URL de download.
  Future<bool> deleteImageByUrl(String imageUrl) async {
    if (imageUrl.isEmpty || !imageUrl.startsWith('https://firebasestorage.googleapis.com')) {
      debugPrint("ImageUploadService: URL de imagem inválida ou não é do Firebase Storage para exclusão: $imageUrl");
      return false; // Não lança exceção, apenas indica falha
    }
    try {
      Reference photoRef = _storage.refFromURL(imageUrl);
      await photoRef.delete();
      debugPrint("ImageUploadService: Imagem $imageUrl deletada do Storage.");
      return true;
    } on FirebaseException catch (e) {
      debugPrint("ImageUploadService: Erro Firebase ao deletar imagem $imageUrl do Storage: ${e.code} - ${e.message}");
      if (e.code == 'object-not-found') {
        debugPrint("ImageUploadService: Imagem não encontrada no Storage, pode já ter sido deletada.");
        return true; // Considera sucesso se o objetivo era não ter a imagem lá
      }
      // Não relança, apenas retorna false para a UI decidir como lidar
      return false;
    } catch (e) {
      debugPrint("ImageUploadService: Erro GERAL ao deletar imagem $imageUrl do Storage: $e");
      return false;
    }
  }
}