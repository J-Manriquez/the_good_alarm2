enum AlarmEventType {
  created,      // Alarma creada
  activated,    // Alarma activada
  deactivated,  // Alarma desactivada
  triggered,    // Alarma sonó
  snoozed,      // Alarma pospuesta
  stopped,      // Alarma detenida
  dismissed,    // Alarma omitida
}

class AlarmHistoryEntry {
  final String alarmId;
  final DateTime timestamp;
  final AlarmEventType eventType;
  final Map<String, dynamic> metadata;

  AlarmHistoryEntry({
    required this.alarmId,
    required this.timestamp,
    required this.eventType,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'alarmId': alarmId,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.toString(),
      'metadata': metadata,
    };
  }

  factory AlarmHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AlarmHistoryEntry(
      alarmId: json['alarmId'],
      timestamp: DateTime.parse(json['timestamp']),
      eventType: AlarmEventType.values.firstWhere(
        (e) => e.toString() == json['eventType'],
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

