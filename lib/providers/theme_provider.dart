import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadTheme() {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      await _prefs.setString(_themeKey, 'dark');
    } else {
      _themeMode = ThemeMode.light;
      await _prefs.setString(_themeKey, 'light');
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String value = 'light';
    if (mode == ThemeMode.dark) {
      value = 'dark';
    } else if (mode == ThemeMode.system) {
      value = 'system';
    }
    await _prefs.setString(_themeKey, value);
    notifyListeners();
  }

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}