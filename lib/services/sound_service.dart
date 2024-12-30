import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  static const platform = MethodChannel('com.example.alarm/sound');

  Future<void> playAlarmSound() async {
    try {
      await platform.invokeMethod('playAlarmSound');
    } catch (e) {
      print('Error playing alarm sound: $e');
    }
  }

  Future<void> stopAlarmSound() async {
    try {
      await platform.invokeMethod('stopAlarmSound');
    } catch (e) {
      print('Error stopping alarm sound: $e');
    }
  }
}