import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';
import 'notification_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal() {
    // Añadir esto para asegurar que el stream esté inicializado
    _initializeStream();
  }

  static const String _storageKey = 'alarms';
  final NotificationService _notificationService = NotificationService();
  late SharedPreferences _prefs;
  List<Alarm> _alarms = [];

  // Convertir a un broadcast StreamController
  var _alarmsController = StreamController<List<Alarm>>.broadcast(sync: true);
  Stream<List<Alarm>> get alarmsStream => _alarmsController.stream;

  // Getter para la lista de alarmas
  List<Alarm> get alarms => List.unmodifiable(_alarms);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAlarms();
  }

  // Nuevo método para inicializar el stream
  void _initializeStream() {
    if (_alarmsController.isClosed) {
      _alarmsController = StreamController<List<Alarm>>.broadcast(sync: true);
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

      // Añadir esto para asegurar que el stream se actualice
      _notifyListeners();
    } catch (e) {
      print('Error al cargar alarmas: $e');
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
      print('Error al guardar alarmas: $e');
    }
  }

  Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    if (alarm.isEnabled) {
      await _notificationService.scheduleAlarm(alarm);
    }
    await _saveAlarms();
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
    }
  }

  Future<void> deleteAlarm(String alarmId) async {
    await _notificationService.cancelAlarm(alarmId);
    _alarms.removeWhere((a) => a.id == alarmId);
    await _saveAlarms();
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

   void dispose() {
    _alarmsController.close();
  }

}
