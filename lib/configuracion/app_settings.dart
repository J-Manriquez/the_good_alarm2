import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

enum TimeFormat { h12, h24 }
enum InputFormat { numpad, circular }

class AppSettings with ChangeNotifier {
  late SharedPreferences _prefs;
  TimeFormat _timeFormat = TimeFormat.h24;
  InputFormat _inputFormat = InputFormat.circular;
  double _alarmVolume = 1.0;
  bool _vibrationEnabled = true;
  
  // Getters
  TimeFormat get timeFormat => _timeFormat;
  InputFormat get inputFormat => _inputFormat;
  double get alarmVolume => _alarmVolume;
  bool get vibrationEnabled => _vibrationEnabled;
  
  AppSettings() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Cargar formato de hora
    final String? timeFormatString = _prefs.getString(AppConstants.keyTimeFormat);
    if (timeFormatString != null) {
      _timeFormat = TimeFormat.values.firstWhere(
        (e) => e.toString() == timeFormatString,
        orElse: () => TimeFormat.h24,
      );
    }
    
    // Cargar formato de entrada
    _inputFormat = _prefs.getBool(AppConstants.keyUseNumpad) == true
        ? InputFormat.numpad
        : InputFormat.circular;
    
    // Cargar volumen
    _alarmVolume = _prefs.getDouble(AppConstants.keyAlarmVolume) ?? 1.0;
    
    // Cargar vibración
    _vibrationEnabled = _prefs.getBool(AppConstants.keyVibrationEnabled) ?? true;
    
    notifyListeners();
  }
  
  Future<void> setTimeFormat(TimeFormat format) async {
    _timeFormat = format;
    await _prefs.setString(AppConstants.keyTimeFormat, format.toString());
    notifyListeners();
  }
  
  Future<void> setInputFormat(InputFormat format) async {
    _inputFormat = format;
    await _prefs.setBool(
      AppConstants.keyUseNumpad,
      format == InputFormat.numpad,
    );
    notifyListeners();
  }
  
  Future<void> setAlarmVolume(double volume) async {
    _alarmVolume = volume;
    await _prefs.setDouble(AppConstants.keyAlarmVolume, volume);
    notifyListeners();
  }
  
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _prefs.setBool(AppConstants.keyVibrationEnabled, enabled);
    notifyListeners();
  }
}