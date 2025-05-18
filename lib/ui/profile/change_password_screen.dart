// lib/ui/profile/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/auth_provider.dart'; // <<< USA O AuthProvider COM FIREBASE AUTH
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmNewPasswordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmNewPasswordCtrl.dispose();
    super.dispose();
  }

  /// Tenta alterar a senha do utilizador usando Firebase Auth.
  Future<void> _submitChangePassword() async {
    // Valida o formulário e a confirmação da nova senha
    if (_newPasswordCtrl.text != _confirmNewPasswordCtrl.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As novas senhas não coincidem!'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true); // Ativa loading

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Guarda para usar após async
    final navigator = Navigator.of(context); // Guarda para usar após async

    try {
      // <<< CHAMA O MÉTODO REAL DE ALTERAR SENHA >>>
      await authProvider.changePassword(
        _oldPasswordCtrl.text, // Senha atual para reautenticação
        _newPasswordCtrl.text, // Nova senha
      );

      // Se chegou aqui, a senha foi alterada com sucesso
       if (mounted) {
          scaffoldMessenger.showSnackBar(
             const SnackBar(content: Text('Senha alterada com sucesso!'), backgroundColor: Colors.green),
          );
          navigator.pop(); // Volta para a tela anterior (Configurações)
       }

    } on Exception catch (e) { // <<< CAPTURA EXCEÇÕES LANÇADAS PELO PROVIDER >>>
       if (mounted) {
          scaffoldMessenger.showSnackBar(
             SnackBar(
                content: Text(e.toString().replaceFirst("Exception: ", "")), // Mostra erro
                backgroundColor: Colors.redAccent,
             ),
          );
       }
    } finally {
      // Garante que o loading termina
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alterar Senha")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Campo Senha Atual (inalterado)
              TextFormField(
                controller: _oldPasswordCtrl,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: "Senha Atual", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_open_outlined)),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Campo Nova Senha (inalterado)
              TextFormField(
                controller: _newPasswordCtrl,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: "Nova Senha", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Nova senha deve ter no mínimo 6 caracteres' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Campo Confirmar Nova Senha (inalterado)
              TextFormField(
                controller: _confirmNewPasswordCtrl,
                enabled: !_isLoading,
                decoration: const InputDecoration(labelText: "Confirmar Nova Senha", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirme a nova senha';
                  if (v != _newPasswordCtrl.text) return 'As novas senhas não coincidem';
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isLoading ? null : _submitChangePassword(),
              ),
              const SizedBox(height: 24),
              // Botão Alterar Senha (inalterado)
              ElevatedButton(
                onPressed: _isLoading ? null : _submitChangePassword,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Alterar Senha"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
