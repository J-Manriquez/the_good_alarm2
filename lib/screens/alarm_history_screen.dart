import 'package:flutter/material.dart';
import '../services/alarm_history_service.dart';
import '../models/alarm_history_entry.dart';

class AlarmHistoryScreen extends StatelessWidget {
  AlarmHistoryScreen({super.key}); // Añadir key y hacerlo const
  final AlarmHistoryService _historyService = AlarmHistoryService();

  @override
  Widget build(BuildContext context) {
    final historyEntries = _historyService.getAllHistory();

    return Scaffold(
      appBar: AppBar(title: Text('Historial de Alarmas')),
      body: ListView.builder(
        itemCount: historyEntries.length,
        itemBuilder: (context, index) {
          final entry = historyEntries[index];
          return ListTile(
            title: Text(_getEventTitle(entry.eventType)),
            subtitle: Text('Alarma: ${entry.alarmId}'),
            trailing: Text(_formatDateTime(entry.timestamp)),
          );
        },
      ),
    );
  }

  String _getEventTitle(AlarmEventType eventType) {
    switch (eventType) {
      case AlarmEventType.created:
        return 'Alarma Creada';
      case AlarmEventType.snoozed:
        return 'Alarma Pospuesta';
      // Añade más casos según sea necesario
      default:
        return eventType.toString();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    // Implementa un formato de fecha personalizado
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}