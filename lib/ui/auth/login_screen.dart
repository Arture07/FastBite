// lib/ui/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/ui/_core/auth_provider.dart'; // <<< USA O AuthProvider COM FIREBASE AUTH
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Mantém emails pré-preenchidos para teste, mas remove a senha
  final _emailController = TextEditingController(); // ou 'resto@test.com' ou o seu 'teste@teste.com'
  final _passwordController = TextEditingController(); // <<< Senha começa vazia
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Tenta autenticar o utilizador usando Firebase Auth.
  Future<void> _performLogin() async {
    // Limpa mensagens de erro anteriores e valida o formulário
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true); // Ativa indicador de loading

    // Obtém o provider (sem ouvir, pois é uma ação)
    final authProvider = context.read<AuthProvider>();

    try {
      // <<< CHAMA O MÉTODO REAL DO FIREBASE AUTH >>>
      await authProvider.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      // Se o login for bem-sucedido, o listener _onAuthStateChanged no AuthProvider
      // vai atualizar o estado e o MainAppWrapper cuidará da navegação.
      // Não precisamos fazer nada aqui no caso de sucesso.
      debugPrint("LoginScreen: Chamada a signInWithEmailAndPassword bem-sucedida (esperando listener).");

    } on Exception catch (e) { // <<< CAPTURA EXCEÇÕES LANÇADAS PELO PROVIDER >>>
      if (mounted) {
        setState(() {
          // Mostra a mensagem de erro vinda do provider
          _errorMessage = e.toString().replaceFirst("Exception: ", ""); // Remove "Exception: "
        });
      }
    } finally {
      // Garante que o loading termina, mesmo se houver erro ou sucesso rápido
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Lógica para recuperação de senha (inalterada, ainda simulada).
  Future<void> _forgotPassword() async {
    final TextEditingController emailResetController = TextEditingController();
    String? dialogError;

    bool? sendEmail = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Recuperar Senha"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Digite seu e-mail para enviarmos as instruções de recuperação."),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailResetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "E-mail cadastrado",
                      errorText: dialogError,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  child: const Text('Enviar Instruções'),
                  onPressed: () async { // <<< Pode ser async para chamar Firebase real
                    final email = emailResetController.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      setDialogState(() => dialogError = 'Email inválido');
                    } else {
                      // --- LÓGICA REAL FIREBASE AUTH (Exemplo) ---
                      // try {
                      //   await context.read<AuthProvider>().sendPasswordResetEmail(email); // Método a ser criado no AuthProvider
                      //   Navigator.of(dialogContext).pop(true); // Fecha se sucesso
                      // } on Exception catch (e) {
                      //   setDialogState(() => dialogError = e.toString().replaceFirst("Exception: ", ""));
                      // }
                      // --- Fim Lógica Real ---

                      // Lógica Simulada Atual:
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (sendEmail == true) {
      final emailToSend = emailResetController.text.trim();
      debugPrint("LoginScreen: Simulando envio de recuperação para $emailToSend");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se $emailToSend estiver cadastrado, você receberá instruções. (Simulação)')),
        );
      }
    }
    emailResetController.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo (inalterado)
                Image.asset('assets/logo.png', height: 300, fit: BoxFit.contain),
                const SizedBox(height: 40),
                // Campo Email (inalterado)
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: "E-mail",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || !value.contains('@') || !value.contains('.'))
                      ? 'E-mail inválido'
                      : null,
                ),
                const SizedBox(height: 16),
                // Campo Senha (inalterado)
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: "Senha",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => (value == null || value.isEmpty) ? 'Senha obrigatória' : null,
                  onFieldSubmitted: (_) => _isLoading ? null : _performLogin(),
                ),
                const SizedBox(height: 12),
                // Botão Esqueci Senha (inalterado)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: const Text("Esqueci minha senha"),
                  ),
                ),
                const SizedBox(height: 12),
                // Exibição de Mensagem de Erro (inalterado)
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Botão Entrar (inalterado)
                ElevatedButton(
                  onPressed: _isLoading ? null : _performLogin, // Chama _performLogin
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Entrar"),
                ),
                const SizedBox(height: 20),
                // Link Cadastre-se (inalterado)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Não tem uma conta?"),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/register'),
                      child: const Text("Cadastre-se"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
