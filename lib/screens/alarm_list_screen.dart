import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_good_alarm/configuracion/app_settings.dart';
import 'package:the_good_alarm/screens/vibration_settings_screen.dart';
import 'package:the_good_alarm/widgets/intervalos.dart';
import '../models/time_interval_settings.dart';
import '../services/alarm_service.dart';
import '../models/alarm.dart';
import 'alarm_edit_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  late TimeIntervalSettings _intervalSettings;

  @override
  void initState() {
    super.initState();
    _loadIntervalSettings();
  }

  Future<void> _loadIntervalSettings() async {
    final settings = await TimeIntervalSettings.load();
    setState(() {
      _intervalSettings = settings;
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<Alarm> _filterAlarmsByInterval(
      List<Alarm> alarms, TimeOfDay start, TimeOfDay end) {
    return alarms.where((alarm) {
      final alarmTime = TimeOfDay.fromDateTime(alarm.time);
      return _isTimeInInterval(alarmTime, start, end);
    }).toList();
  }

  bool _isTimeInInterval(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final timeMinutes = time.hour * 60 + time.minute;

    // Manejar caso de intervalo que cruza la media noche
    if (endMinutes < startMinutes) {
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final alarmService = Provider.of<AlarmService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todas las Alarmas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showIntervalConfigModal,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final alarmService =
              Provider.of<AlarmService>(context, listen: false);
          await alarmService.initialize();
        },
        child: Consumer<AlarmService>(
          builder: (context, alarmService, child) {
            final alarms = alarmService.alarms;
            final morningAlarms = _filterAlarmsByInterval(alarms,
                _intervalSettings.morningStart, _intervalSettings.morningEnd);
            final afternoonAlarms = _filterAlarmsByInterval(
                alarms,
                _intervalSettings.afternoonStart,
                _intervalSettings.afternoonEnd);
            final nightAlarms = _filterAlarmsByInterval(alarms,
                _intervalSettings.nightStart, _intervalSettings.nightEnd);

            // Verificar si no hay alarmas en absoluto
            if (alarms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alarm_off,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay alarmas',
                      style: Theme.of(context).textTheme.titleLarge,
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

            return ListView(
              children: [
                _buildAlarmSection('Mañana', morningAlarms,
                    '${_formatTimeOfDay(_intervalSettings.morningStart)} - ${_formatTimeOfDay(_intervalSettings.morningEnd)}'),
                _buildAlarmSection('Tarde', afternoonAlarms,
                    '${_formatTimeOfDay(_intervalSettings.afternoonStart)} - ${_formatTimeOfDay(_intervalSettings.afternoonEnd)}'),
                _buildAlarmSection('Noche', nightAlarms,
                    '${_formatTimeOfDay(_intervalSettings.nightStart)} - ${_formatTimeOfDay(_intervalSettings.nightEnd)}'),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAlarmEdit(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Alarma'),
      ),
    );
  }

  Widget _buildAlarmSection(
      String title, List<Alarm> alarms, String timeInterval) {
    return ExpansionTile(
      title: Row(
        children: [
          Text(title),
          const SizedBox(width: 10),
          Text(
            timeInterval,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      initiallyExpanded: true,
      children: alarms.isEmpty
          ? [const ListTile(title: Text('No hay alarmas'))]
          : alarms.map((alarm) => _buildAlarmTile(alarm)).toList(),
    );
  }

  Widget _buildAlarmTile(Alarm alarm) {
    return ListTile(
      title: Text(alarm.name.isEmpty ? 'Alarma' : alarm.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            alarm.isOneTime ? 'Una vez' : 'Repetir',
            style: TextStyle(
              color: alarm.isOneTime ? Colors.red : Colors.green,
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Switch(
        value: alarm.isEnabled,
        onChanged: (_) => _toggleAlarm(alarm),
      ),
      onTap: () => _showAlarmOptions(alarm),
    );
  }

  void _showAlarmOptions(Alarm alarm) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAlarmEdit(context, alarm);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteAlarm(alarm);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteAlarm(Alarm alarm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Alarma'),
          content: const Text('¿Estás seguro de eliminar esta alarma?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Eliminar'),
              onPressed: () {
                final alarmService =
                    Provider.of<AlarmService>(context, listen: false);
                alarmService.deleteAlarm(alarm.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleAlarm(Alarm alarm) {
    final alarmService = Provider.of<AlarmService>(context, listen: false);
    alarmService.toggleAlarm(alarm.id);
  }

  void _navigateToAlarmEdit(BuildContext context, [Alarm? alarm]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlarmEditScreen(alarm: alarm),
      ),
    );
  }

  void _showIntervalConfigModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return IntervalConfigWidget(
          initialSettings: _intervalSettings,
          onSave: (settings) {
            setState(() {
              _intervalSettings = settings;
            });
            settings.save();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _deleteAlarm(BuildContext context, Alarm alarm) async {
    final alarmService = Provider.of<AlarmService>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alarma'),
        content:
            const Text('¿Estás seguro de que quieres eliminar esta alarma?'),
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
                  settings.timeFormat == TimeFormat.h24
                      ? '24 horas'
                      : '12 horas',
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
              // botón para configuración de vibración
              ListTile(
                title: const Text('Configuración de Vibración'),
                subtitle: Text(
                  settings.vibrationService.isEnabled
                      ? 'Activada - ${settings.vibrationService.currentPattern}'
                      : 'Desactivada',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VibrationSettingsScreen(),
                    ),
                  );
                },
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
