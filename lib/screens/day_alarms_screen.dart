import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../widgets/alarm_list_item.dart';
import 'alarm_edit_screen.dart';

class DayAlarmsScreen extends StatelessWidget {
  final DateTime selectedDate;
  final String screenTitle;

  const DayAlarmsScreen({
    super.key,
    required this.selectedDate,
    required this.screenTitle,
  });

  @override
  Widget build(BuildContext context) {
    final alarmService = Provider.of<AlarmService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        actions: [
          // Filtro o acciones adicionales si se requieren
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Método para recargar las alarmas manualmente
          await alarmService.initialize();
        },
        child: StreamBuilder<List<Alarm>>(
          stream: alarmService.alarmsStream,
          initialData: alarmService.alarms,
          builder: (context, snapshot) {
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
                      'Error al cargar alarmas',
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

            // Sin alarmas para el día
            final dayAlarms = snapshot.data?.where((alarm) {
              return alarm.isEnabled && _isAlarmForDay(alarm, selectedDate);
            }).toList() ?? [];

            if (dayAlarms.isEmpty) {
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
                      'No hay alarmas para este día',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu primera alarma para este día',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            // Lista de alarmas para el día
            return ListView.separated(
              itemCount: dayAlarms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final alarm = dayAlarms[index];
                return Dismissible(
                  key: Key(alarm.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    // Diálogo de confirmación
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar Alarma'),
                        content: const Text('¿Estás seguro de eliminar esta alarma?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    alarmService.deleteAlarm(alarm.id);
                  },
                  child: AlarmListItem(
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
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegación a creación de nueva alarma
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AlarmEditScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Alarma'),
      ),
    );
  }

  bool _isAlarmForDay(Alarm alarm, DateTime targetDate) {
    if (alarm.isOneTime) {
      return _isSameDay(alarm.time, targetDate);
    } else {
      return alarm.weekDays[targetDate.weekday - 1];
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}