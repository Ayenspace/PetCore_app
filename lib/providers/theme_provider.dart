import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_themeKey, mode.name),
    );
    notifyListeners();
  }

  void toggleTheme() {
    setTheme(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    if (saved == null) return;

    final modes = ThemeMode.values.where((mode) => mode.name == saved);
    if (modes.isEmpty) return;
    _themeMode = modes.first;
    notifyListeners();
  }
}
