import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../configuracion/app_settings.dart';
import '../widgets/custom_numpad.dart';
import '../widgets/circular_time_picker.dart';
import 'game_selection_screen.dart';

class AlarmEditScreen extends StatefulWidget {
  final Alarm? alarm;

  const AlarmEditScreen({
    super.key,
    this.alarm,
  });

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TextEditingController _nameController;
  late TimeOfDay _selectedTime;
  late List<bool> _selectedDays;
  late bool _isOneTime;
  late bool _requireGame;
  String? _selectedGame;
  String? _gameDifficulty;
  late int _snoozeTime;
  bool _useVibration = true;
  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    final now = TimeOfDay.now();
    _nameController = TextEditingController(text: widget.alarm?.name ?? '');
    _selectedTime = widget.alarm != null
        ? TimeOfDay(
            hour: widget.alarm!.time.hour,
            minute: widget.alarm!.time.minute,
          )
        : now;
    _selectedDays = widget.alarm?.weekDays ?? List.filled(7, false);
    _isOneTime = widget.alarm?.isOneTime ?? true;
    _requireGame = widget.alarm?.requireGame ?? false;
    _selectedGame = widget.alarm?.selectedGame;
    _gameDifficulty = widget.alarm?.gameDifficulty;
    _snoozeTime = widget.alarm?.snoozeTime ?? 5;
    _useVibration = widget.alarm?.useVibration ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettings>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? 'Nueva Alarma' : 'Editar Alarma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAlarm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Selector de hora
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: appSettings.inputFormat == InputFormat.numpad
                  ? TimeInputWithNumpad(
                      onTimeSelected: (time) {
                        setState(() => _selectedTime = time);
                      },
                    )
                  : CircularTimePicker(
                      initialTime: _selectedTime,
                      onTimeChanged: (time) {
                        setState(() => _selectedTime = time);
                      },
                      use24HourFormat: appSettings.timeFormat == TimeFormat.h24,
                    ),
            ),

            // Nombre de la alarma
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la alarma',
                  hintText: 'Ejemplo: Trabajo, Gimnasio...',
                  prefixIcon: Icon(Icons.label),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selector de días
            if (!_isOneTime) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Repetir en',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _buildDaySelector(),
            ],

            // Switch para alarma única
            SwitchListTile(
              title: const Text('Alarma de una sola vez'),
              subtitle: const Text('La alarma sonará solo una vez'),
              value: _isOneTime,
              onChanged: (value) {
                setState(() => _isOneTime = value);
              },
            ),

            const Divider(),

            // Configuración del juego
            SwitchListTile(
              title: const Text('Requerir juego para apagar'),
              subtitle: const Text(
                  'Deberás completar un juego para apagar la alarma'),
              value: _requireGame,
              onChanged: (value) {
                setState(() => _requireGame = value);
                if (value && _selectedGame == null) {
                  _selectGame();
                }
              },
            ),

            if (_requireGame) ...[
              ListTile(
                title: Text(_selectedGame == null
                    ? 'Seleccionar juego'
                    : 'Juego: ${_getGameName(_selectedGame!)}'),
                subtitle: _gameDifficulty != null
                    ? Text(
                        'Dificultad: ${_getGameDifficulty(_gameDifficulty!)}')
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectGame,
              ),
            ],

            const Divider(),

            // Configuración de snooze
            ListTile(
              title: const Text('Tiempo de repetición'),
              subtitle: Text('$_snoozeTime minutos'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _snoozeTime > 1
                        ? () => setState(() => _snoozeTime--)
                        : null,
                  ),
                  Text('$_snoozeTime'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _snoozeTime < 30
                        ? () => setState(() => _snoozeTime++)
                        : null,
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('Vibración'),
              subtitle: const Text('Vibrar cuando suene la alarma'),
              trailing: Switch(
                value: _useVibration,
                onChanged: (value) {
                  setState(() {
                    _useVibration = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(7, (index) {
        return FilterChip(
          label: Text(days[index]),
          selected: _selectedDays[index],
          onSelected: (selected) {
            setState(() {
              _selectedDays[index] = selected;
            });
          },
        );
      }),
    );
  }

  Future<void> _selectGame() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => GameSelectionScreen(
          selectedGame: _selectedGame,
          difficulty: _gameDifficulty,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedGame = result['game'];
        _gameDifficulty = result['difficulty'];
      });
    }
  }

  String _getGameName(String game) {
    switch (game) {
      case 'math':
        return 'Matemáticas';
      case 'memory':
        return 'Memoria';
      default:
        return 'Desconocido';
    }
  }

  String _getGameDifficulty(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Fácil';
      case 'medium':
        return 'Media';
      case 'hard':
        return 'Difícil';
      default:
        return 'Desconocida';
    }
  }

  Future<void> _saveAlarm() async {
    if (!_isOneTime && !_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día para la alarma recurrente'),
        ),
      );
      return;
    }

    if (_requireGame && (_selectedGame == null || _gameDifficulty == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un juego y su dificultad'),
        ),
      );
      return;
    }

    final alarmService = Provider.of<AlarmService>(context, listen: false);
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newAlarm = Alarm(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      time: dateTime,
      isEnabled: true,
      weekDays: _selectedDays,
      isOneTime: _isOneTime,
      snoozeTime: _snoozeTime,
      requireGame: _requireGame,
      selectedGame: _selectedGame,
      gameDifficulty: _gameDifficulty,
      useVibration: _useVibration,
    );

    if (widget.alarm != null) {
      await alarmService.updateAlarm(newAlarm);
    } else {
      await alarmService.addAlarm(newAlarm);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
