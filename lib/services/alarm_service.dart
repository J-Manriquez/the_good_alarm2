import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import 'notification_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static const String _storageKey = 'alarms';
  final NotificationService _notificationService = NotificationService();
  late SharedPreferences _prefs;
  List<Alarm> _alarms = [];

  final _alarmsController = StreamController<List<Alarm>>.broadcast();
  Stream<List<Alarm>> get alarmsStream => _alarmsController.stream;

  // Getter para la lista de alarmas
  List<Alarm> get alarms => List.unmodifiable(_alarms);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAlarms();
  }

  void _notifyListeners() {
    _alarmsController.add(_alarms);
  }

  Future<void> _loadAlarms() async {
    final String? alarmsJson = _prefs.getString(_storageKey);
    if (alarmsJson != null) {
      final List<dynamic> alarmsList = jsonDecode(alarmsJson);
      _alarms = alarmsList.map((json) => Alarm.fromJson(json)).toList();

      // Reprogramar alarmas activas
      for (final alarm in _alarms) {
        if (alarm.isEnabled) {
          await _notificationService.scheduleAlarm(alarm);
        }
      }
    }
  }

  Future<void> _saveAlarms() async {
    final String alarmsJson =
        jsonEncode(_alarms.map((a) => a.toJson()).toList());
    await _prefs.setString(_storageKey, alarmsJson);
  }

  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    if (alarm.isEnabled) {
      await _notificationService.scheduleAlarm(alarm);
    }
    await _saveAlarms();
    _notifyListeners();  
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      await _notificationService.cancelAlarm(alarm.id);
      _alarms[index] = alarm;
      if (alarm.isEnabled) {
        await _notificationService.scheduleAlarm(alarm);
      }
      await _saveAlarms();
      _notifyListeners();  
    }
  }

  Future<void> deleteAlarm(String alarmId) async {
    await _notificationService.cancelAlarm(alarmId);
    _alarms.removeWhere((a) => a.id == alarmId);
    await _saveAlarms();
    _notifyListeners();  
  }

  Future<void> toggleAlarm(String alarmId) async {
    final index = _alarms.indexWhere((a) => a.id == alarmId);
    if (index != -1) {
      _alarms[index].toggleEnabled();
      if (_alarms[index].isEnabled) {
        await _notificationService.scheduleAlarm(_alarms[index]);
      } else {
        await _notificationService.cancelAlarm(alarmId);
      }
      await _saveAlarms();
    }
  }

  Future<void> snoozeAlarm(String alarmId) async {
    final alarm = _alarms.firstWhere((a) => a.id == alarmId);
    if (alarm.canSnooze()) {
      alarm.incrementSnoozeCount();
      final DateTime newTime =
          DateTime.now().add(Duration(minutes: alarm.snoozeTime));
      await _notificationService.cancelAlarm(alarmId);
      await _notificationService.scheduleAlarm(alarm.copyWith(time: newTime));
      await _saveAlarms();
    }
  }

  Future<void> stopAlarm(String alarmId) async {
    final alarm = _alarms.firstWhere((a) => a.id == alarmId);
    await _notificationService.cancelAlarm(alarmId);
    alarm.resetSnoozeCount();
    if (!alarm.isOneTime) {
      await _notificationService.scheduleAlarm(alarm);
    }
    await _saveAlarms();
    _notifyListeners();  
  }

  List<Alarm> getActiveAlarms() {
    return _alarms.where((alarm) => alarm.isEnabled).toList();
  }

  List<Alarm> getAlarmsForDay(DateTime date) {
    return _alarms
        .where((alarm) => alarm.isEnabled && alarm.shouldRingOn(date))
        .toList();
  }
}
