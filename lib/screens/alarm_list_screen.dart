import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../widgets/alarm_list_item.dart';
import 'alarm_edit_screen.dart';
import '../configuracion/theme_provider.dart';
import '../configuracion/app_settings.dart';

class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarmService = Provider.of<AlarmService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appSettings = Provider.of<AppSettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmas'),
        actions: [
          // Botón para cambiar el tema
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
            onPressed: _showSettingsDialog(context, appSettings),
          ),
        ],
      ),
      body: StreamBuilder<List<Alarm>>(
        stream: alarmService.alarmsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final alarms = snapshot.data!;
          
          if (alarms.isEmpty) {
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
                    'Toca el botón + para crear una alarma',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: alarms.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: AlarmListItem(
                  alarm: alarm,
                  onTap: () => _editAlarm(context, alarm),
                  onToggle: (enabled) => _toggleAlarm(context, alarm),
                  onDelete: () => _deleteAlarm(context, alarm),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createAlarm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Alarma'),
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

  void _toggleAlarm(BuildContext context, Alarm alarm) {
    final alarmService = Provider.of<AlarmService>(context, listen: false);
    alarmService.toggleAlarm(alarm.id);
  }

  Future<void> _deleteAlarm(BuildContext context, Alarm alarm) async {
    final alarmService = Provider.of<AlarmService>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alarma'),
        content: const Text('¿Estás seguro de que quieres eliminar esta alarma?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await alarmService.deleteAlarm(alarm.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alarma eliminada'),
          ),
        );
      }
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

  VoidCallback _showSettingsDialog(BuildContext context, AppSettings settings) {
    return () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Configuración'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formato de hora
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
              // Formato de entrada
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
              // Volumen de alarma
              ListTile(
                title: const Text('Volumen de alarma'),
                subtitle: Slider(
                  value: settings.alarmVolume,
                  onChanged: settings.setAlarmVolume,
                  divisions: 10,
                  label: '${(settings.alarmVolume * 100).round()}%',
                ),
              ),
              // Vibración
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
    };
  }
}