import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_good_alarm/screens/active_alarms_screen.dart';
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
      body: CustomScrollView(
        slivers: [
          // Modificado SliverAppBar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            // Cambiar a false para que aparezca contraído por defecto
            snap: false,
            // Eliminar título
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
              // Botón de tema
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
              // Botón de configuración
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsDialog(context, appSettings),
              ),
            ],
          ),
          // Contenido principal (sin cambios)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildUpcomingAlarms(context, alarmService),
                ],
              ),
            ),
          ),
        ],
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
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            'No hay alarmas programadas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          );
        }

        final activeAlarms = snapshot.data!.where((a) => a.isEnabled).toList();
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  context,
                  'Alarma para mañana',
                  Icons.alarm_add,
                  () => _createQuickAlarm(context, const Duration(days: 1)),
                ),
                _buildQuickActionButton(
                  context,
                  'En 1 hora',
                  Icons.hourglass_bottom,
                  () => _createQuickAlarm(context, const Duration(hours: 1)),
                ),
                _buildQuickActionButton(
                  context,
                  'Todas las alarmas',
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
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final alarms = snapshot.data ?? [];

        if (snapshot.data!.isEmpty) {
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
              ],
            ),
          );
        }

        final activeAlarms = snapshot.data!
            .where((alarm) => alarm.isEnabled)
            .toList()
          ..sort(
              (a, b) => a.getNextAlarmTime().compareTo(b.getNextAlarmTime()));

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
    final now = DateTime.now();
    final activeAlarms = alarms.where((alarm) => alarm.isEnabled).toList();
    if (activeAlarms.isEmpty) return null;

    activeAlarms.sort((a, b) {
      final aNext = a.getNextAlarmTime();
      final bNext = b.getNextAlarmTime();
      return aNext.compareTo(bNext);
    });

    return activeAlarms.first;
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
}
