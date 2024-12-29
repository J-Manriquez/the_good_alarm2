import 'package:flutter/material.dart';

class AppConstants {
  // Temas
  static const Color primaryLightColor = Color(0xFF2196F3);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color accentLightColor = Color(0xFF03A9F4);
  static const Color accentDarkColor = Color(0xFF0288D1);
  
  // Configuraciones de juego
  static const int mathGameEasyProblems = 3;
  static const int mathGameMediumProblems = 5;
  static const int mathGameHardProblems = 7;
  
  static const int memoryGameEasyPairs = 6;
  static const int memoryGameMediumPairs = 12;
  static const int memoryGameHardPairs = 18;
  
  // Configuraciones de alarma
  static const int defaultSnoozeTime = 5; // minutos
  static const int maxSnoozeCount = 3;
  
  // Keys para SharedPreferences
  static const String keyThemeMode = 'theme_mode';
  static const String keyTimeFormat = 'time_format';
  static const String keyUseNumpad = 'use_numpad';
  static const String keyAlarmVolume = 'alarm_volume';
  static const String keyVibrationEnabled = 'vibration_enabled';
}