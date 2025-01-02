import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_good_alarm/models/alarm_history_entry.dart';

class AlarmHistoryService {
  static final AlarmHistoryService _instance = AlarmHistoryService._internal();
  factory AlarmHistoryService() => _instance;
  AlarmHistoryService._internal();

  static const String _storageKey = 'alarm_history_entries';
  late SharedPreferences _prefs;
  List<AlarmHistoryEntry> _historyEntries = [];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadHistoryEntries();
  }

  Future<void> _loadHistoryEntries() async {
    final String? entriesJson = _prefs.getString(_storageKey);
    if (entriesJson != null) {
      final List<dynamic> entriesList = jsonDecode(entriesJson);
      _historyEntries = entriesList
          .map((json) => AlarmHistoryEntry.fromJson(json))
          .toList();
    }
  }

  Future<void> _saveHistoryEntries() async {
    final String entriesJson = jsonEncode(
      _historyEntries.map((entry) => entry.toJson()).toList(),
    );
    await _prefs.setString(_storageKey, entriesJson);
  }

  Future<void> addHistoryEntry(AlarmHistoryEntry entry) async {
    _historyEntries.add(entry);
    
    // Mantener solo los últimos 100 registros
    if (_historyEntries.length > 100) {
      _historyEntries.removeRange(0, _historyEntries.length - 100);
    }

    await _saveHistoryEntries();
  }

  List<AlarmHistoryEntry> getHistoryForAlarm(String alarmId) {
    return _historyEntries
        .where((entry) => entry.alarmId == alarmId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<AlarmHistoryEntry> getAllHistory() {
    return List.from(_historyEntries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}