import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeIntervalSettings {
  late TimeOfDay morningStart;
  late TimeOfDay morningEnd;
  late TimeOfDay afternoonStart;
  late TimeOfDay afternoonEnd;
  late TimeOfDay nightStart;
  late TimeOfDay nightEnd;

  TimeIntervalSettings({
    TimeOfDay? morningStart,
    TimeOfDay? morningEnd,
    TimeOfDay? afternoonStart,
    TimeOfDay? afternoonEnd,
    TimeOfDay? nightStart,
    TimeOfDay? nightEnd,
  }) {
    this.morningStart = morningStart ?? const TimeOfDay(hour: 5, minute: 0);
    this.morningEnd = morningEnd ?? const TimeOfDay(hour: 11, minute: 59);
    this.afternoonStart = afternoonStart ?? const TimeOfDay(hour: 12, minute: 0);
    this.afternoonEnd = afternoonEnd ?? const TimeOfDay(hour: 20, minute: 59);
    this.nightStart = nightStart ?? const TimeOfDay(hour: 21, minute: 0);
    this.nightEnd = nightEnd ?? const TimeOfDay(hour: 4, minute: 59);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('morningStartHour', morningStart.hour);
    await prefs.setInt('morningStartMinute', morningStart.minute);
    await prefs.setInt('morningEndHour', morningEnd.hour);
    await prefs.setInt('morningEndMinute', morningEnd.minute);
    await prefs.setInt('afternoonStartHour', afternoonStart.hour);
    await prefs.setInt('afternoonStartMinute', afternoonStart.minute);
    await prefs.setInt('afternoonEndHour', afternoonEnd.hour);
    await prefs.setInt('afternoonEndMinute', afternoonEnd.minute);
    await prefs.setInt('nightStartHour', nightStart.hour);
    await prefs.setInt('nightStartMinute', nightStart.minute);
    await prefs.setInt('nightEndHour', nightEnd.hour);
    await prefs.setInt('nightEndMinute', nightEnd.minute);
  }

  static Future<TimeIntervalSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeIntervalSettings(
      morningStart: TimeOfDay(
        hour: prefs.getInt('morningStartHour') ?? 5,
        minute: prefs.getInt('morningStartMinute') ?? 0,
      ),
      morningEnd: TimeOfDay(
        hour: prefs.getInt('morningEndHour') ?? 11,
        minute: prefs.getInt('morningEndMinute') ?? 59,
      ),
      afternoonStart: TimeOfDay(
        hour: prefs.getInt('afternoonStartHour') ?? 12,
        minute: prefs.getInt('afternoonStartMinute') ?? 0,
      ),
      afternoonEnd: TimeOfDay(
        hour: prefs.getInt('afternoonEndHour') ?? 20,
        minute: prefs.getInt('afternoonEndMinute') ?? 59,
      ),
      nightStart: TimeOfDay(
        hour: prefs.getInt('nightStartHour') ?? 21,
        minute: prefs.getInt('nightStartMinute') ?? 0,
      ),
      nightEnd: TimeOfDay(
        hour: prefs.getInt('nightEndHour') ?? 4,
        minute: prefs.getInt('nightEndMinute') ?? 59,
      ),
    );
  }

  bool isValidConfiguration() {
    // Mejorar la validación para manejar intervalos que cruzan la media noche
    return _validateInterval(morningStart, morningEnd) &&
           _validateInterval(afternoonStart, afternoonEnd) &&
           _validateInterval(nightStart, nightEnd) &&
           !_intervalsOverlap();
  }

  bool _validateInterval(TimeOfDay start, TimeOfDay end) {
    // Convertir a minutos desde media noche
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;

    // Manejar caso de intervalo que cruza la media noche
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    return startMinutes < endMinutes;
  }

  bool _intervalsOverlap() {
    // Convertir todos los intervalos a minutos desde media noche
    List<int> morningMinutes = _intervalToMinutes(morningStart, morningEnd);
    List<int> afternoonMinutes = _intervalToMinutes(afternoonStart, afternoonEnd);
    List<int> nightMinutes = _intervalToMinutes(nightStart, nightEnd);

    // Verificar si hay intersecciones
    return _hasOverlap(morningMinutes, afternoonMinutes) ||
           _hasOverlap(morningMinutes, nightMinutes) ||
           _hasOverlap(afternoonMinutes, nightMinutes);
  }

  List<int> _intervalToMinutes(TimeOfDay start, TimeOfDay end) {
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;

    // Manejar caso de intervalo que cruza la media noche
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    return [startMinutes, endMinutes];
  }

  bool _hasOverlap(List<int> interval1, List<int> interval2) {
    return !(interval1[1] < interval2[0] || interval2[1] < interval1[0]);
  }

  // Método para convertir TimeOfDay a minutos desde media noche
  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // Método para convertir minutos a TimeOfDay
  TimeOfDay _minutesToTimeOfDay(int minutes) {
    int adjustedMinutes = minutes % (24 * 60);
    return TimeOfDay(
      hour: adjustedMinutes ~/ 60,
      minute: adjustedMinutes % 60,
    );
  }

  // Método para ajustar un intervalo de tiempo
  TimeIntervalSettings adjustInterval({
    TimeOfDay? morningStart,
    TimeOfDay? morningEnd,
    TimeOfDay? afternoonStart,
    TimeOfDay? afternoonEnd,
    TimeOfDay? nightStart,
    TimeOfDay? nightEnd,
  }) {
    return TimeIntervalSettings(
      morningStart: morningStart ?? this.morningStart,
      morningEnd: morningEnd ?? this.morningEnd,
      afternoonStart: afternoonStart ?? this.afternoonStart,
      afternoonEnd: afternoonEnd ?? this.afternoonEnd,
      nightStart: nightStart ?? this.nightStart,
      nightEnd: nightEnd ?? this.nightEnd,
    );
  }

  // Método para dividir un intervalo de tiempo en segmentos
  List<TimeOfDay> splitInterval(TimeOfDay start, TimeOfDay end, int segments) {
    int startMinutes = _timeOfDayToMinutes(start);
    int endMinutes = _timeOfDayToMinutes(end);

    // Manejar caso de intervalo que cruza la media noche
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    int intervalMinutes = endMinutes - startMinutes;
    int segmentSize = intervalMinutes ~/ segments;

    return List.generate(segments + 1, (index) {
      int currentMinutes = startMinutes + (index * segmentSize);
      return _minutesToTimeOfDay(currentMinutes);
    });
  }

  // Método para encontrar el intervalo al que pertenece un TimeOfDay
  String getIntervalName(TimeOfDay time) {
    int minutes = _timeOfDayToMinutes(time);

    if (_isTimeInInterval(time, morningStart, morningEnd)) {
      return 'morning';
    } else if (_isTimeInInterval(time, afternoonStart, afternoonEnd)) {
      return 'afternoon';
    } else if (_isTimeInInterval(time, nightStart, nightEnd)) {
      return 'night';
    }

    return 'unknown';
  }

  // Método auxiliar para verificar si un tiempo está en un intervalo
  bool _isTimeInInterval(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    int timeMinutes = _timeOfDayToMinutes(time);
    int startMinutes = _timeOfDayToMinutes(start);
    int endMinutes = _timeOfDayToMinutes(end);

    // Manejar caso de intervalo que cruza la media noche
    if (endMinutes < startMinutes) {
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }
}
