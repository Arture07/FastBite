// lib/ui/_core/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Chave para salvar a preferência de tema
  static const _themePrefKey = 'themeModePreference';

  // Estado inicial padrão
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoaded = false; // Flag para controlar carregamento inicial

  // Getter público para o modo de tema atual
  ThemeMode get themeMode => _themeMode;
  // Getter para saber se a preferência já foi carregada
  bool get isThemeLoaded => _isLoaded;

  // Construtor: Carrega a preferência salva ao iniciar
  ThemeProvider() {
    _loadThemePreference();
  }

  // Carrega a preferência de tema do SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Lê o nome do tema salvo (ex: 'light', 'dark', 'system')
      String? savedThemeName = prefs.getString(_themePrefKey);

      if (savedThemeName != null) {
        // Converte o nome salvo de volta para o enum ThemeMode
        _themeMode = ThemeMode.values.firstWhere(
          (e) => e.name == savedThemeName,
          orElse: () => ThemeMode.system, // Usa system como padrão se inválido
        );
      } else {
        _themeMode = ThemeMode.system; // Padrão se nada foi salvo ainda
      }
       debugPrint("ThemeProvider: Preferência de tema carregada: ${_themeMode.name}");
    } catch (e) {
       debugPrint("ThemeProvider: Erro ao carregar preferência de tema: $e");
       _themeMode = ThemeMode.system; // Usa padrão em caso de erro
    } finally {
       _isLoaded = true; // Marca como carregado
       notifyListeners(); // Notifica que o carregamento terminou (importante para UI inicial)
    }
  }

  // Salva a preferência de tema no SharedPreferences
  Future<void> _saveThemePreference(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Salva o nome do enum como string
      await prefs.setString(_themePrefKey, mode.name);
       debugPrint("ThemeProvider: Preferência de tema salva: ${mode.name}");
    } catch (e) {
       debugPrint("ThemeProvider: Erro ao salvar preferência de tema: $e");
    }
  }

  // Método público para definir um novo modo de tema
  void setThemeMode(ThemeMode mode) {
    // Só atualiza e notifica se o modo realmente mudou
    if (_themeMode != mode) {
      _themeMode = mode;
      debugPrint("ThemeProvider: Modo de tema alterado para: ${_themeMode.name}");
      _saveThemePreference(mode); // Salva a nova preferência
      notifyListeners(); // Notifica a UI para reconstruir com o novo tema
    }
  }
}
