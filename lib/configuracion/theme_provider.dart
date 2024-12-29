import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;
  
  ThemeProvider() {
    _loadPreferences();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final String? themeModeString = _prefs.getString(AppConstants.keyThemeMode);
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(AppConstants.keyThemeMode, mode.toString());
    notifyListeners();
  }
  
  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primaryLightColor,
        secondary: AppConstants.accentLightColor,
      ),
      // Personaliza más aspectos del tema aquí
    );
  }
  
  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryDarkColor,
        secondary: AppConstants.accentDarkColor,
      ),
      // Personaliza más aspectos del tema aquí
    );
  }
}