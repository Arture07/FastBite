// lib/utils/error_handler.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Para FirebaseException
// Importar exceções específicas se precisar de tratamento mais granular
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  static void _showErrorSnackBar(BuildContext context, String message) {
    // Garante que o context ainda está montado e pode mostrar SnackBars
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent[700],
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      // Fallback se o context não puder mostrar SnackBar
      debugPrint("ErrorHandler: Impossível mostrar SnackBar. Erro: $message");
    }
  }

  /// Trata FirebaseException do Storage.
  static void handleFirebaseStorageError(BuildContext context, FirebaseException e, {String? operation}) {
    String message;
    String operationMsg = operation != null ? " na operação de '$operation'" : "";

    debugPrint("Firebase Storage Error$operationMsg: Code: ${e.code}, Message: ${e.message}");

    switch (e.code) {
      case 'object-not-found':
        message = 'Arquivo não encontrado no servidor$operationMsg.';
        break;
      case 'unauthorized':
        message = 'Você não tem permissão para esta operação de armazenamento$operationMsg.';
        break;
      case 'canceled':
        message = 'A operação de upload foi cancelada$operationMsg.';
        break;
      case 'quota-exceeded':
        message = 'Cota de armazenamento excedida$operationMsg. Contacte o suporte.';
        break;
      case 'project-not-found':
      case 'bucket-not-found':
        message = 'Erro de configuração do armazenamento$operationMsg. Contacte o suporte.';
        break;
      case 'retry-limit-exceeded':
        message = 'Limite de tentativas excedido$operationMsg. Verifique sua conexão.';
        break;
      default:
        message = 'Erro no Firebase Storage$operationMsg: ${e.message ?? e.code}';
    }
    _showErrorSnackBar(context, message);
  }

  /// Trata FirebaseException do Firestore.
  static void handleFirestoreError(BuildContext context, FirebaseException e, {String? operation}) {
    String message;
    String operationMsg = operation != null ? " na operação de '$operation'" : "";
    debugPrint("Firestore Error$operationMsg: Code: ${e.code}, Message: ${e.message}");

     switch (e.code) {
      case 'permission-denied':
        message = 'Permissão negada para esta operação$operationMsg.';
        break;
      case 'not-found':
        message = 'Documento ou recurso não encontrado$operationMsg.';
        break;
      case 'unavailable':
        message = 'Serviço temporariamente indisponível$operationMsg. Tente mais tarde.';
        break;
      case 'already-exists':
        message = 'Este item já existe$operationMsg.';
        break;
      default:
        message = 'Erro no banco de dados$operationMsg: ${e.message ?? e.code}';
    }
     _showErrorSnackBar(context, message);
  }
  
  /// Trata FirebaseException do Auth.
  static void handleFirebaseAuthError(BuildContext context, FirebaseException e, {String? operation}) {
    String message;
    String operationMsg = operation != null ? " na operação de '$operation'" : "";
    debugPrint("FirebaseAuth Error$operationMsg: Code: ${e.code}, Message: ${e.message}");

    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        message = 'Credenciais inválidas$operationMsg.';
        break;
      case 'email-already-in-use':
        message = 'Este e-mail já está em uso$operationMsg.';
        break;
      case 'requires-recent-login':
         message = 'Esta operação requer login recente. Por favor, saia e entre novamente.';
         break;
      case 'weak-password':
         message = 'A senha fornecida é muito fraca.';
         break;
      case 'user-disabled':
         message = 'Esta conta de utilizador foi desabilitada.';
         break;
      default:
        message = 'Erro de autenticação$operationMsg: ${e.message ?? e.code}';
    }
    _showErrorSnackBar(context, message);
  }


  /// Trata outras exceções genéricas.
  static void handleGenericError(BuildContext context, dynamic e, {String? operation}) {
    String operationMsg = operation != null ? " durante '$operation'" : "";
    // Tenta extrair uma mensagem mais limpa da exceção
    String errorMessage = e.toString();
    if (e is Exception) {
        // Remove o prefixo "Exception: " se existir
        final prefix = "Exception: ";
        if (errorMessage.startsWith(prefix)) {
            errorMessage = errorMessage.substring(prefix.length);
        }
    }
    
    debugPrint("Erro genérico$operationMsg: $errorMessage");
    _showErrorSnackBar(context, 'Ocorreu um erro inesperado$operationMsg: $errorMessage');
  }
}