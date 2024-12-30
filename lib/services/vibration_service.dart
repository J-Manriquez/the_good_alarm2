import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  static const String _prefVibrationEnabled = 'vibration_enabled';
  static const String _prefVibrationPattern = 'vibration_pattern';

  // Patrones predefinidos (duración en milisegundos)
  static const Map<String, List<int>> vibrationPatterns = {
    'suave': [0, 200, 200, 200],
    'normal': [0, 500, 200, 500],
    'intenso': [0, 1000, 200, 1000, 200, 1000],
    'sos': [0, 100, 100, 100, 100, 100, 200, 200, 200, 100, 100, 100],
    'escalado': [0, 100, 100, 200, 100, 300, 100, 400],
  };

  bool _isEnabled = true;
  String _currentPattern = 'normal';
  
  // Inicializar el servicio
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_prefVibrationEnabled) ?? true;
    _currentPattern = prefs.getString(_prefVibrationPattern) ?? 'normal';
  }

  // Getters y Setters
  bool get isEnabled => _isEnabled;
  String get currentPattern => _currentPattern;

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVibrationEnabled, enabled);
  }

  Future<void> setPattern(String pattern) async {
    if (vibrationPatterns.containsKey(pattern)) {
      _currentPattern = pattern;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefVibrationPattern, pattern);
    }
  }

  // Métodos de vibración
  Future<void> vibrate({String? pattern}) async {
    if (!_isEnabled) return;

    try {
      final selectedPattern = pattern ?? _currentPattern;
      final vibrationPattern = vibrationPatterns[selectedPattern] ?? vibrationPatterns['normal']!;

      // Usar la plataforma para vibrar
      await SystemChannels.platform.invokeMethod('HapticFeedback.vibrate', vibrationPattern);
    } catch (e) {
      print('Error al vibrar: $e');
    }
  }

  // Vibración de prueba
  Future<void> testVibration(String pattern) async {
    if (!_isEnabled) return;
    await vibrate(pattern: pattern);
  }

  // Vibración de alarma
  Future<void> startAlarmVibration() async {
    if (!_isEnabled) return;
    
    // Patrón continuo para alarma
    while (_isEnabled) {
      await vibrate();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // Detener vibración
  void stopVibration() {
    _isEnabled = false;
  }

  // Vibración de confirmación
  Future<void> vibrateConfirmation() async {
    if (!_isEnabled) return;
    await vibrate(pattern: 'suave');
  }

  // Vibración de error
  Future<void> vibrateError() async {
    if (!_isEnabled) return;
    await vibrate(pattern: 'sos');
  }
}