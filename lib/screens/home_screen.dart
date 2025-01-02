import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_good_alarm/models/alarm_history_entry.dart';
import 'package:the_good_alarm/screens/active_alarms_screen.dart';
import 'package:the_good_alarm/screens/alarm_history_screen.dart';
import 'package:the_good_alarm/screens/day_alarms_screen.dart';
import 'package:the_good_alarm/services/alarm_history_service.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../configuracion/theme_provider.dart';
import '../configuracion/app_settings.dart';
import 'alarm_list_screen.dart';
import 'alarm_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final alarmService = Provider.of<AlarmService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appSettings = Provider.of<AppSettings>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await alarmService.initialize();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              snap: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _buildNextAlarmInfo(context, alarmService),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () {
                    themeProvider.setThemeMode(
                      themeProvider.themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showSettingsDialog(context, appSettings),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    // Añadir la sección de historial diario
                    Center(
                    child: Text('Historial Diario',
                        style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    // Añadir la sección de historial diario')
                    _buildDailyHistory(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createAlarm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Alarma'),
      ),
    );
  }

  Widget _buildNextAlarmInfo(BuildContext context, AlarmService alarmService) {
    return StreamBuilder<List<Alarm>>(
      stream: alarmService.alarmsStream,
      initialData: alarmService.alarms,
      builder: (context, snapshot) {
        // Manejo de errores
        if (snapshot.hasError) {
          return Text(
            'Error al cargar alarmas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              backgroundColor: Colors.red,
            ),
          );
        }

        // Sin datos o sin alarmas
        final allAlarms = snapshot.data ?? [];
        final activeAlarms = allAlarms.where((a) => a.isEnabled).toList();

        if (activeAlarms.isEmpty) {
          return const Text(
            'No hay alarmas activas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          );
        }

        final nextAlarm = _findNextAlarm(activeAlarms);
        if (nextAlarm == null) {
          return const Text(
            'No hay alarmas activas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          );
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(nextAlarm.time),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: nextAlarm.isEnabled,
                  onChanged: (bool value) {
                    alarmService.toggleAlarm(nextAlarm.id);
                  },
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.grey,
                ),
              ],
            ),
            Text(
              _getTimeUntilAlarm(nextAlarm),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            if (activeAlarms.length > 1)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActiveAlarmsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Ver todas las alarmas activas',
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  context,
                  'Hoy',
                  Icons.today,
                  () {
                    final today = DateTime.now();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DayAlarmsScreen(
                          selectedDate: today,
                          screenTitle: 'Alarmas de Hoy',
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Mañana',
                  Icons.calendar_today,
                  () {
                    final tomorrow =
                        DateTime.now().add(const Duration(days: 1));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DayAlarmsScreen(
                          selectedDate: tomorrow,
                          screenTitle: 'Alarmas de Mañana',
                        ),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Todas',
                  Icons.list,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AlarmListScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUpcomingAlarms(BuildContext context, AlarmService alarmService) {
    return StreamBuilder<List<Alarm>>(
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

        // Sin alarmas
        final allAlarms = snapshot.data ?? [];
        final activeAlarms = allAlarms
            .where((alarm) => alarm.isEnabled)
            .toList()
          ..sort(
              (a, b) => a.getNextAlarmTime().compareTo(b.getNextAlarmTime()));

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
                  'No hay alarmas configuradas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu primera alarma',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próximas Alarmas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeAlarms.take(3).length,
              itemBuilder: (context, index) {
                final alarm = activeAlarms[index];
                return Card(
                  child: ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(alarm.time),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    title: Text(alarm.name.isEmpty ? 'Alarma' : alarm.name),
                    subtitle: Text(_getTimeUntilAlarm(alarm)),
                    trailing: alarm.requireGame
                        ? Icon(
                            _getGameIcon(alarm.selectedGame),
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => _editAlarm(context, alarm),
                  ),
                );
              },
            ),
            if (activeAlarms.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AlarmListScreen(),
                      ),
                    );
                  },
                  child: const Text('Ver todas las alarmas'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Alarm? _findNextAlarm(List<Alarm> alarms) {
    if (alarms.isEmpty) return null;

    alarms.sort((a, b) {
      final aNext = a.getNextAlarmTime();
      final bNext = b.getNextAlarmTime();
      return aNext.compareTo(bNext);
    });

    return alarms.first;
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _getTimeUntilAlarm(Alarm alarm) {
    final now = DateTime.now();
    final nextAlarmTime = alarm.getNextAlarmTime();
    final difference = nextAlarmTime.difference(now);

    if (difference.inDays > 0) {
      return 'En ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'En ${difference.inMinutes} minutos';
    } else {
      return 'Muy pronto';
    }
  }

  IconData _getGameIcon(String? gameType) {
    switch (gameType) {
      case 'math':
        return Icons.calculate;
      case 'memory':
        return Icons.grid_view;
      default:
        return Icons.games;
    }
  }

  void _createAlarm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AlarmEditScreen(),
      ),
    );
  }

  void _editAlarm(BuildContext context, Alarm alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(alarm: alarm),
      ),
    );
  }

  Future<void> _createQuickAlarm(
      BuildContext context, Duration duration) async {
    final now = DateTime.now();
    final alarmTime = now.add(duration);

    final alarm = Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: alarmTime,
      isOneTime: true,
    );

    final alarmService = Provider.of<AlarmService>(context, listen: false);
    await alarmService.addAlarm(alarm);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarma creada para ${_formatTime(alarmTime)}',
          ),
          action: SnackBarAction(
            label: 'DESHACER',
            onPressed: () => alarmService.deleteAlarm(alarm.id),
          ),
        ),
      );
    }
  }

  void _showSettingsDialog(BuildContext context, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Formato de hora'),
              subtitle: Text(
                settings.timeFormat == TimeFormat.h24 ? '24 horas' : '12 horas',
              ),
              trailing: Switch(
                value: settings.timeFormat == TimeFormat.h24,
                onChanged: (value) {
                  settings.setTimeFormat(
                    value ? TimeFormat.h24 : TimeFormat.h12,
                  );
                },
              ),
            ),
            ListTile(
              title: const Text('Método de entrada'),
              subtitle: Text(
                settings.inputFormat == InputFormat.numpad
                    ? 'Teclado numérico'
                    : 'Selector circular',
              ),
              trailing: Switch(
                value: settings.inputFormat == InputFormat.numpad,
                onChanged: (value) {
                  settings.setInputFormat(
                    value ? InputFormat.numpad : InputFormat.circular,
                  );
                },
              ),
            ),
            ListTile(
              title: const Text('Volumen de alarma'),
              subtitle: Slider(
                value: settings.alarmVolume,
                onChanged: settings.setAlarmVolume,
                divisions: 10,
                label: '${(settings.alarmVolume * 100).round()}%',
              ),
            ),
            ListTile(
              title: const Text('Vibración'),
              trailing: Switch(
                value: settings.vibrationEnabled,
                onChanged: settings.setVibrationEnabled,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyHistory(BuildContext context) {
    final alarmHistoryService = Provider.of<AlarmHistoryService>(context);
    final today = DateTime.now();

    // Filtrar entradas de historial del día de hoy
    final todayEntries = alarmHistoryService.getAllHistory().where((entry) {
      return isSameDay(entry.timestamp, today);
    }).toList();

    if (todayEntries.isEmpty) {
      return const SizedBox.shrink(); // No mostrar nada si no hay historial
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Historial de Hoy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayEntries.length,
            itemBuilder: (context, index) {
              final entry = todayEntries[index];
              return ListTile(
                title: Text(_getEventTitle(entry.eventType)),
                subtitle: Text('Alarma: ${entry.alarmId}'),
                trailing: Text(_formatTime(entry.timestamp)),
              );
            },
          ),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlarmHistoryScreen(),
                  ),
                );
              },
              child: const Text('Ver historial completo'),
            ),
          ),
        ],
      ),
    );
  }

  // Método de ayuda para formatear el título del evento
  String _getEventTitle(AlarmEventType eventType) {
    switch (eventType) {
      case AlarmEventType.created:
        return 'Alarma Creada';
      case AlarmEventType.activated:
        return 'Alarma Activada';
      case AlarmEventType.deactivated:
        return 'Alarma Desactivada';
      case AlarmEventType.triggered:
        return 'Alarma Sonó';
      case AlarmEventType.snoozed:
        return 'Alarma Pospuesta';
      case AlarmEventType.stopped:
        return 'Alarma Detenida';
      case AlarmEventType.dismissed:
        return 'Alarma Omitida';
      default:
        return eventType.toString();
    }
  }

  // Método de ayuda para comparar fechas
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
