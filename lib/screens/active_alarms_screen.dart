import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import './alarm_edit_screen.dart';

class ActiveAlarmsScreen extends StatelessWidget {
  const ActiveAlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarmService = Provider.of<AlarmService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmas Activas'),
      ),
      body: StreamBuilder<List<Alarm>>(
        stream: alarmService.alarmsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeAlarms = snapshot.data!.where((a) => a.isEnabled).toList();

          if (activeAlarms.isEmpty) {
            return const Center(
              child: Text('No hay alarmas activas'),
            );
          }

          return ListView.builder(
            itemCount: activeAlarms.length,
            itemBuilder: (context, index) {
              final alarm = activeAlarms[index];
              return ListTile(
                title: Text(
                  alarm.name.isNotEmpty ? alarm.name : 'Alarma',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(_formatTime(alarm.time)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: alarm.isEnabled,
                      onChanged: (bool value) {
                        // Desactivar alarma
                        alarmService.toggleAlarm(alarm.id);
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String choice) {
                        if (choice == 'edit') {
                          // Navegar a edición de alarma
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlarmEditScreen(alarm: alarm),
                            ),
                          );
                        } else if (choice == 'delete') {
                          // Mostrar confirmación de eliminación
                          _showDeleteConfirmation(context, alarmService, alarm);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context, 
    AlarmService alarmService, 
    Alarm alarm
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alarma'),
        content: const Text('¿Estás seguro de eliminar esta alarma?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              alarmService.deleteAlarm(alarm.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}