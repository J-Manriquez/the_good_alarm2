import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_good_alarm/widgets/alarm_list_item.dart';
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
        actions: [
          // Acciones adicionales si se requieren
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navegar a configuración de alarmas activas
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Alarm>>(
        stream: alarmService.activeAlarmsStream,
        initialData: alarmService.activeAlarms,
        builder: (context, snapshot) {
          // Estado de carga
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return const Center(
          //     child: CircularProgressIndicator(),
          //   );
          // }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar alarmas activas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(snapshot.error.toString()),
                  ElevatedButton(
                    onPressed: () => alarmService.initialize(),
                    child: const Text('Reintentar'),
                  )
                ],
              ),
            );
          }

          // Sin alarmas activas
          final activeAlarms = snapshot.data ?? [];
          if (activeAlarms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay alarmas activas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activa algunas alarmas para verlas aquí',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Lista de alarmas activas
          return ListView.separated(
            itemCount: activeAlarms.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final alarm = activeAlarms[index];
              return AlarmListItem(
                alarm: alarm,
                onTap: () {
                  // Navegación a edición de alarma
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlarmEditScreen(alarm: alarm),
                    ),
                  );
                },
                onToggle: (enabled) {
                  alarmService.toggleAlarm(alarm.id);
                },
                onDelete: () {
                  alarmService.deleteAlarm(alarm.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegación a creación de nueva alarma
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AlarmEditScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
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