import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  double _fontSizeMultiplier = 1.0;

  ThemeMode get themeMode => _themeMode;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setFontSizeMultiplier(double value) {
    _fontSizeMultiplier = value;
    notifyListeners();
  }
}
