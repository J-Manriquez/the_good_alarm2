import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_good_alarm/models/alarm_history_entry.dart';
import '../models/alarm.dart';
import 'notification_service.dart';
import 'package:the_good_alarm/services/alarm_history_service.dart';

class AlarmService with ChangeNotifier {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal() {
    _initializeStream();
  }

  static const String _storageKey = 'alarms';
  final NotificationService _notificationService = NotificationService();
  late SharedPreferences _prefs;
  List<Alarm> _alarms = [];

  // Usar un BehaviorSubject para mantener el último estado
  late StreamController<List<Alarm>> _alarmsController =
      StreamController<List<Alarm>>.broadcast();
  Stream<List<Alarm>> get alarmsStream => _alarmsController.stream;

  // Stream específico para alarmas activas
  Stream<List<Alarm>> get activeAlarmsStream => alarmsStream
      .map((allAlarms) => allAlarms.where((alarm) => alarm.isEnabled).toList());

  // Getter para la lista de alarmas
  List<Alarm> get alarms => List.unmodifiable(_alarms);

  // Getter para alarmas activas
  List<Alarm> get activeAlarms =>
      _alarms.where((alarm) => alarm.isEnabled).toList();

  final AlarmHistoryService _alarmHistoryService = AlarmHistoryService();

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadAlarms();
    } catch (e) {
      debugPrint('Error inicializando AlarmService: $e');
      _notifyListeners(); // Notificar incluso en caso de error
    }
  }

  void _initializeStream() {
    if (_alarmsController.isClosed) {
      _alarmsController = StreamController<List<Alarm>>.broadcast();
    }
  }

  void _notifyListeners() {
    if (!_alarmsController.isClosed) {
      _alarmsController.add(List.unmodifiable(_alarms));
    }
  }

  Future<void> _loadAlarms() async {
    try {
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
      } else {
        _alarms = [];
      }

      _notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar alarmas: $e');
      _alarms = [];
      _notifyListeners();
    }
  }

  Future<void> _saveAlarms() async {
    try {
      final String alarmsJson =
          jsonEncode(_alarms.map((a) => a.toJson()).toList());
      await _prefs.setString(_storageKey, alarmsJson);
      _notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar alarmas: $e');
      _notifyListeners();
    }
  }

  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    // Registrar evento de creación
    await _alarmHistoryService.addHistoryEntry(
      AlarmHistoryEntry(
        alarmId: alarm.id,
        timestamp: DateTime.now(),
        eventType: AlarmEventType.created,
      ),
    );

    if (alarm.isEnabled) {
      await _notificationService.scheduleAlarm(alarm);
    }
    await _saveAlarms();
    _notifyListeners();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final index = _alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      await _notificationService.cancelAlarm(_alarms[index].id);
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
      _alarms[index] = _alarms[index].copyWith(
        isEnabled: !_alarms[index].isEnabled,
      );

      if (_alarms[index].isEnabled) {
        await _notificationService.scheduleAlarm(_alarms[index]);
      } else {
        await _notificationService.cancelAlarm(alarmId);
      }

      await _saveAlarms();
      _notifyListeners();
    }
  }

  Future<void> snoozeAlarm(String alarmId) async {
    final alarm = _alarms.firstWhere((a) => a.id == alarmId);
    if (alarm.canSnooze()) {
      alarm.incrementSnoozeCount();
      alarm.totalTimesSnoozed++;

      await _alarmHistoryService.addHistoryEntry(
        AlarmHistoryEntry(
          alarmId: alarmId,
          timestamp: DateTime.now(),
          eventType: AlarmEventType.snoozed,
          metadata: {
            'snoozeCount': alarm.snoozeCount,
          },
        ),
      );

      final DateTime newTime =
          DateTime.now().add(Duration(minutes: alarm.snoozeTime));
      await _notificationService.cancelAlarm(alarmId);
      await _notificationService.scheduleAlarm(alarm.copyWith(time: newTime));
      await _saveAlarms();
      _notifyListeners();
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

  // void dispose() {
  //   _alarmsController.close();
  // }
}
