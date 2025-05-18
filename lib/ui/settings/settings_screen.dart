import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para salvar preferências locais
import 'package:provider/provider.dart'; // Para acessar providers
import 'package:myapp/ui/_core/auth_provider.dart'; // Para verificar login e pegar papel
import 'package:myapp/model/user.dart'; // Para usar UserRole
import 'package:myapp/ui/_core/theme_provider.dart'; // Para gerenciar o tema
import 'package:myapp/ui/profile/edit_client_profile_screen.dart';
import 'package:myapp/ui/profile/change_password_screen.dart';
// Importar se precisar navegar para o perfil do restaurante daqui
// import 'package:myapp/ui/restaurant_profile/edit_restaurant_profile_screen.dart';

// Tela de Configurações do Aplicativo
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- Chaves para salvar no SharedPreferences ---
  // Usadas para identificar unicamente as preferências salvas.
  static const _promoNotifyKey = 'notifyPromo';
  static const _statusNotifyKey = 'notifyStatus';
  // A preferência de tema agora é gerenciada pelo ThemeProvider

  // --- Variáveis de Estado Local ---
  // Controla se os dados das preferências já foram carregados
  bool _isLoading = true;
  // Guarda os valores atuais das configurações de notificação
  bool _promoNotifications = true; // Valor padrão inicial
  bool _orderStatusNotifications = true; // Valor padrão inicial
  // O estado do tema (_selectedTheme) foi removido daqui, pois é lido do ThemeProvider

  @override
  void initState() {
    super.initState();
    // Carrega as configurações salvas (apenas as gerenciadas localmente)
    // assim que a tela é iniciada.
    _loadLocalSettings();
  }

  // --- Carrega Configurações Locais do SharedPreferences ---
  Future<void> _loadLocalSettings() async {
    // Garante que o widget ainda está na árvore antes de atualizar o estado
    if (!mounted) return;
    setState(() => _isLoading = true); // Mostra loading enquanto carrega

    try {
      final prefs = await SharedPreferences.getInstance();
      // Atualiza o estado com os valores salvos ou os padrões
      setState(() {
        _promoNotifications =
            prefs.getBool(_promoNotifyKey) ?? true; // Usa true se não encontrar
        _orderStatusNotifications =
            prefs.getBool(_statusNotifyKey) ??
            true; // Usa true se não encontrar
        // O tema é carregado e gerenciado pelo ThemeProvider
      });
      debugPrint("SettingsScreen: Configurações locais carregadas.");
    } catch (e) {
      debugPrint("SettingsScreen: Erro ao carregar configurações locais: $e");
      // Mostra erro para o usuário, mas continua com os valores padrão
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar suas preferências.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      // Garante que o loading termina, mesmo se ocorrer erro
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Salva uma Configuração Local no SharedPreferences ---
  // Usada pelos toggles de notificação
  Future<void> _updateLocalSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value); // Salva o valor booleano
      debugPrint(
        "SettingsScreen: Configuração local '$key' salva como '$value'.",
      );
    } catch (e) {
      debugPrint("SettingsScreen: Erro ao salvar configuração '$key': $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar a configuração de $key.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Helper para obter o texto descritivo do modo de tema ---
  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "Claro";
      case ThemeMode.dark:
        return "Escuro";
      case ThemeMode.system:
      return "Padrão do Sistema";
    }
  }

  // --- Helper para mostrar diálogo de confirmação de Logout ---
  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirmar Saída"),
            content: const Text("Deseja realmente sair da sua conta?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Sair"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  // --- Constrói a Interface da Tela ---
  @override
  Widget build(BuildContext context) {
    // Ouve os providers para obter estado atual e reagir a mudanças
    final authProvider = context.watch<AuthProvider>();
    final themeProvider =
        context.watch<ThemeProvider>(); // Ouve o ThemeProvider
    // Determina o papel do usuário (cliente por padrão se deslogado)
    final userRole = authProvider.currentUser?.role ?? UserRole.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações"),
        elevation: 1.0, // Sombra sutil
      ),
      // Mostra loading inicial ou a lista de configurações
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                // Usa ListView para permitir rolagem se houver muitas opções
                children: [
                  // --- Seção Notificações ---
                  _buildSectionTitle(context, "Notificações"),
                  SwitchListTile(
                    title: const Text("Promoções e Novidades"),
                    subtitle: const Text(
                      "Receber ofertas especiais e notícias.",
                    ),
                    value: _promoNotifications, // Valor atual do estado
                    // Ao mudar o toggle:
                    onChanged: (bool value) {
                      setState(
                        () => _promoNotifications = value,
                      ); // Atualiza estado local
                      _updateLocalSetting(
                        _promoNotifyKey,
                        value,
                      ); // Salva no SharedPreferences
                      // TODO: Implementar lógica real de (des)registrar para notificações push
                    },
                    secondary: Icon(
                      Icons.campaign_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    activeColor:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // Cor do toggle ativo
                  ),
                  SwitchListTile(
                    title: const Text("Status dos Pedidos"),
                    subtitle: const Text(
                      "Ser notificado sobre o andamento dos pedidos.",
                    ),
                    value: _orderStatusNotifications, // Valor atual do estado
                    onChanged: (bool value) {
                      setState(
                        () => _orderStatusNotifications = value,
                      ); // Atualiza estado local
                      _updateLocalSetting(
                        _statusNotifyKey,
                        value,
                      ); // Salva no SharedPreferences
                      // TODO: Implementar lógica real de notificações de pedido
                    },
                    secondary: Icon(
                      Icons.receipt_long_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),

                  // --- Seção Aparência ---
                  _buildSectionTitle(context, "Aparência"),
                  ListTile(
                    leading: Icon(
                      Icons.brightness_6_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text("Tema do Aplicativo"),
                    // Mostra o tema ATUAL lido do ThemeProvider
                    subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      // Abre diálogo para escolher o tema
                      ThemeMode? result = await showDialog<ThemeMode>(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            // Permite atualizar visual do diálogo
                            builder: (context, setDialogState) {
                              // Pega o tema ATUAL do provider para iniciar o diálogo
                              ThemeMode currentSelectionInDialog =
                                  themeProvider.themeMode;
                              return SimpleDialog(
                                title: const Text('Escolher Tema'),
                                children:
                                    ThemeMode.values
                                        .map(
                                          (mode) => RadioListTile<ThemeMode>(
                                            title: Text(
                                              _getThemeModeText(mode),
                                            ),
                                            value: mode,
                                            groupValue:
                                                currentSelectionInDialog, // Seleção atual no diálogo
                                            onChanged: (ThemeMode? value) {
                                              // Fecha o diálogo retornando o valor escolhido
                                              if (value != null) {
                                                Navigator.pop(context, value);
                                              }
                                            },
                                          ),
                                        )
                                        .toList(),
                              );
                            },
                          );
                        },
                      );

                      // Se o usuário escolheu um tema diferente do atual
                      if (result != null && result != themeProvider.themeMode) {
                        // <<< CHAMA O ThemeProvider para mudar e salvar o tema >>>
                        context.read<ThemeProvider>().setThemeMode(result);
                        // O watch no MyApp aplicará a mudança visualmente.
                      }
                    },
                  ),

                  // --- Seção Conta (Só mostra se o usuário estiver autenticado) ---
                  if (authProvider.isAuthenticated) ...[
                    _buildSectionTitle(context, "Conta"),
                    // Item para Editar Perfil
                    ListTile(
                      leading: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      // Texto depende se é cliente ou restaurante
                      title: Text(
                        userRole == UserRole.client
                            ? "Editar Perfil"
                            : "Editar Perfil (Restaurante)",
                      ),
                      subtitle: Text(
                        userRole == UserRole.client
                            ? "Alterar nome ou e-mail."
                            : "Alterar dados cadastrais.",
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navega para a tela de edição apropriada
                        if (userRole == UserRole.client) {
                          // Navega para a tela de perfil do cliente
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const EditClientProfileScreen(),
                            ),
                          );
                        } else {
                          // Navega para a tela de perfil do restaurante
                          // import 'package:myapp/ui/restaurant_profile/edit_restaurant_profile_screen.dart';
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => const EditRestaurantProfileScreen()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Use o item "Perfil do Restaurante" no menu lateral.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    // Item para Alterar Senha
                    ListTile(
                      leading: Icon(
                        Icons.lock_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text("Alterar Senha"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navega para a tela de Alterar Senha
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    // Item para Sair da Conta
                    ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: Colors.redAccent[100],
                      ), // Cor de destaque para logout
                      title: const Text("Sair da Conta"),
                      onTap: () async {
                        // Lógica de Logout com confirmação
                        bool? confirm = await _confirmLogout(context);
                        if (confirm == true && context.mounted) {
                          // Verifica confirmação e se widget existe
                          await authProvider
                              .logout(); // Chama logout do provider
                          // A navegação para Login é tratada no MyApp pelo Consumer
                        }
                      },
                    ),
                  ], // Fim da seção Conta
                  // --- Seção Sobre ---
                  _buildSectionTitle(context, "Sobre"),
                  const ListTile(
                    // Usar pacote package_info_plus para versão real
                    leading: Icon(Icons.info_outline),
                    title: Text("Versão do Aplicativo"),
                    subtitle: Text(
                      "1.0.0 (Simulada)",
                    ), // TODO: Obter versão real
                  ),
                  // TODO: Adicionar ListTile para Termos de Serviço, Política de Privacidade, etc.
                  // ListTile( leading: Icon(Icons.description_outlined), title: Text("Termos de Serviço"), onTap: () => _launchUrl(context, 'URL_DOS_TERMOS')),
                  // ListTile( leading: Icon(Icons.privacy_tip_outlined), title: Text("Política de Privacidade"), onTap: () => _launchUrl(context, 'URL_DA_POLITICA')),
                ],
              ),
    );
  }

  // --- Helper para criar os títulos de seção ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16.0,
        24.0,
        16.0,
        8.0,
      ), // Mais espaço acima
      child: Text(
        title.toUpperCase(), // Texto em maiúsculas
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary, // Cor primária do tema
          fontWeight: FontWeight.bold,
          fontSize: 12, // Tamanho pequeno
          letterSpacing: 0.8, // Espaçamento entre letras
        ),
      ),
    );
  }
} // Fim da classe _SettingsScreenState
