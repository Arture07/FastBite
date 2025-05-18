// lib/ui/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ui/_core/auth_provider.dart'; // <<< USA O AuthProvider COM FIREBASE AUTH
import 'package:myapp/model/user.dart'; // Importar User e UserRole

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _restNameCtrl = TextEditingController(); // Para nome do restaurante
  final _restDescCtrl = TextEditingController(); // Para descrição do restaurante
  UserRole _role = UserRole.client; // Estado para o tipo de conta
  bool _loading = false; // Estado de loading
  String? _errorMessage; // Mensagem de erro

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _restNameCtrl.dispose();
    _restDescCtrl.dispose();
    super.dispose();
  }

  /// Tenta registar um novo utilizador usando Firebase Auth e salvar dados no Firestore.
  Future<void> _submit() async {
    // Limpa erros e valida o formulário
    setState(() => _errorMessage = null);
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _errorMessage = 'As senhas não coincidem!');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true); // Ativa loading
    final authProvider = context.read<AuthProvider>(); // Pega o provider

    try {
      // <<< CHAMA O MÉTODO REAL DE REGISTO COM FIREBASE AUTH >>>
      await authProvider.registerWithEmailAndPassword(
        context: context, // Passa o context para o provider poder chamar RestaurantData
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text, // A senha real será usada pelo Firebase Auth
        role: _role,
        restaurantName: _role == UserRole.restaurant ? _restNameCtrl.text : null,
        restaurantDescription: _role == UserRole.restaurant ? _restDescCtrl.text : null,
      );

      // Se o registo for bem-sucedido, o listener _onAuthStateChanged no AuthProvider
      // cuidará de atualizar o estado e o MainAppWrapper fará a navegação.
      // Podemos fechar esta tela se ela foi aberta por cima (ex: vindo do Login).
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
       debugPrint("RegisterScreen: Chamada a registerWithEmailAndPassword bem-sucedida (esperando listener).");

    } on Exception catch (e) { // <<< CAPTURA EXCEÇÕES LANÇADAS PELO PROVIDER >>>
      if (mounted) {
        setState(() {
          // Mostra a mensagem de erro vinda do provider (ex: email em uso, senha fraca)
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      // Garante que o loading termina
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Campos do Formulário (sem alterações na estrutura) ---
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person_outline)),
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.isEmpty ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Email inválido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  // Firebase Auth tem validação de senha fraca, mas podemos manter a básica aqui
                  validator: (v) => v!.length < 6 ? 'Senha deve ter no mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassCtrl,
                  enabled: !_loading,
                  decoration: const InputDecoration(labelText: 'Confirmar Senha', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  textInputAction: _role == UserRole.client ? TextInputAction.done : TextInputAction.next, // Muda ação se for cliente
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirme a senha';
                    if (v != _passCtrl.text) return 'As senhas não coincidem';
                    return null;
                  },
                   onFieldSubmitted: (_) { // Tenta submeter se for o último campo (cliente)
                      if (_role == UserRole.client && !_loading) {
                         _submit();
                      }
                   }
                ),
                const SizedBox(height: 20),
                // Dropdown para Tipo de Conta (inalterado)
                DropdownButtonFormField<UserRole>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: UserRole.client, child: Text('Quero Comprar (Cliente)')),
                    DropdownMenuItem(value: UserRole.restaurant, child: Text('Quero Vender (Restaurante)')),
                  ],
                  onChanged: _loading ? null : (UserRole? v) => setState(() => _role = v!),
                  decoration: const InputDecoration(labelText: 'Tipo de conta', border: OutlineInputBorder(), prefixIcon: Icon(Icons.account_box_outlined)),
                ),
                // Campos condicionais para Restaurante (inalterados)
                if (_role == UserRole.restaurant) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _restNameCtrl,
                    enabled: !_loading,
                    decoration: const InputDecoration(labelText: 'Nome do Restaurante', prefixIcon: Icon(Icons.storefront_outlined)),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (_role == UserRole.restaurant && v!.isEmpty) ? 'Informe o nome do restaurante' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _restDescCtrl,
                    enabled: !_loading,
                    decoration: const InputDecoration(labelText: 'Descrição Breve do Restaurante', prefixIcon: Icon(Icons.description_outlined)),
                    textInputAction: TextInputAction.done, // Último campo para restaurante
                    validator: (v) => (_role == UserRole.restaurant && v!.isEmpty) ? 'Informe a descrição' : null,
                    maxLines: 3,
                    minLines: 1,
                    onFieldSubmitted: (_) => _loading ? null : _submit(), // Tenta submeter
                  ),
                ],
                const SizedBox(height: 16),
                // Exibição de Mensagem de Erro (inalterado)
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 14), textAlign: TextAlign.center),
                  ),
                // Botão Criar Conta (inalterado)
                ElevatedButton(
                  onPressed: _loading ? null : _submit, // <<< Chama _submit >>>
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Criar Conta'),
                ),
                const SizedBox(height: 16),
                // Link Entrar (inalterado)
                TextButton(
                  onPressed: _loading ? null : () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: const Text("Já tem uma conta? Entrar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}