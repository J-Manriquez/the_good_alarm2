import 'dart:convert';

class Alarm {
  final String id;
  String name;
  DateTime time;
  bool isEnabled;
  List<bool> weekDays; // [lun, mar, mie, jue, vie, sab, dom]
  bool isOneTime;
  int snoozeTime; // en minutos
  int snoozeCount;
  int maxSnoozeCount;
  String? selectedGame; // 'math' o 'memory'
  String? gameDifficulty; // 'easy', 'medium', 'hard'
  bool requireGame;
  
  Alarm({
    required this.id,
    this.name = '',
    required this.time,
    this.isEnabled = true,
    List<bool>? weekDays,
    this.isOneTime = false,
    this.snoozeTime = 5,
    this.snoozeCount = 0,
    this.maxSnoozeCount = 3,
    this.selectedGame,
    this.gameDifficulty,
    this.requireGame = false,
  }) : weekDays = weekDays ?? List.filled(7, false);

  // Copia del objeto con posibles modificaciones
  Alarm copyWith({
    String? name,
    DateTime? time,
    bool? isEnabled,
    List<bool>? weekDays,
    bool? isOneTime,
    int? snoozeTime,
    int? snoozeCount,
    int? maxSnoozeCount,
    String? selectedGame,
    String? gameDifficulty,
    bool? requireGame,
  }) {
    return Alarm(
      id: id,
      name: name ?? this.name,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      weekDays: weekDays ?? List.from(this.weekDays),
      isOneTime: isOneTime ?? this.isOneTime,
      snoozeTime: snoozeTime ?? this.snoozeTime,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      selectedGame: selectedGame ?? this.selectedGame,
      gameDifficulty: gameDifficulty ?? this.gameDifficulty,
      requireGame: requireGame ?? this.requireGame,
    );
  }

  // Convertir a Map para almacenamiento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time.toIso8601String(),
      'isEnabled': isEnabled,
      'weekDays': weekDays,
      'isOneTime': isOneTime,
      'snoozeTime': snoozeTime,
      'snoozeCount': snoozeCount,
      'maxSnoozeCount': maxSnoozeCount,
      'selectedGame': selectedGame,
      'gameDifficulty': gameDifficulty,
      'requireGame': requireGame,
    };
  }

  // Crear objeto desde Map
  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      name: json['name'],
      time: DateTime.parse(json['time']),
      isEnabled: json['isEnabled'],
      weekDays: List<bool>.from(json['weekDays']),
      isOneTime: json['isOneTime'],
      snoozeTime: json['snoozeTime'],
      snoozeCount: json['snoozeCount'],
      maxSnoozeCount: json['maxSnoozeCount'],
      selectedGame: json['selectedGame'],
      gameDifficulty: json['gameDifficulty'],
      requireGame: json['requireGame'],
    );
  }

  // Convertir a String para almacenamiento
  String toJsonString() => jsonEncode(toJson());

  // Crear objeto desde String
  factory Alarm.fromJsonString(String jsonString) {
    return Alarm.fromJson(jsonDecode(jsonString));
  }

  // Obtener próxima fecha de alarma
  DateTime getNextAlarmTime() {
    if (isOneTime) {
      return time.isBefore(DateTime.now()) ? time.add(const Duration(days: 1)) : time;
    }

    DateTime now = DateTime.now();
    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Si la hora ya pasó hoy, empezar a buscar desde mañana
    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // Buscar el próximo día activo
    for (int i = 0; i < 7; i++) {
      int weekday = candidate.weekday - 1; // 0 = Lunes, 6 = Domingo
      if (weekDays[weekday]) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }

    // Si no hay días activos, retornar null o lanzar una excepción
    throw Exception('No active days set for alarm');
  }

  // Verificar si la alarma debe sonar en un día específico
  bool shouldRingOn(DateTime date) {
    if (isOneTime) {
      return date.year == time.year &&
             date.month == time.month &&
             date.day == time.day;
    }
    return weekDays[date.weekday - 1];
  }

  // Activar/desactivar la alarma
  void toggleEnabled() {
    isEnabled = !isEnabled;
  }

  // Registrar un snooze
  bool canSnooze() {
    return snoozeCount < maxSnoozeCount;
  }

  void incrementSnoozeCount() {
    if (canSnooze()) {
      snoozeCount++;
    }
  }

  void resetSnoozeCount() {
    snoozeCount = 0;
  }

  // Obtener tiempo hasta la próxima alarma en minutos
  int getTimeToAlarmInMinutes() {
    final nextAlarm = getNextAlarmTime();
    return nextAlarm.difference(DateTime.now()).inMinutes;
  }
}