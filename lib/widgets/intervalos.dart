
import 'package:flutter/material.dart';
import 'package:the_good_alarm/models/time_interval_settings.dart';

class IntervalConfigWidget extends StatefulWidget {
  final TimeIntervalSettings initialSettings;
  final Function(TimeIntervalSettings) onSave;

  const IntervalConfigWidget({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  @override
  State<IntervalConfigWidget> createState() => _IntervalConfigWidgetState();
}

class _IntervalConfigWidgetState extends State<IntervalConfigWidget> {
  late TimeOfDay _morningStart;
  late TimeOfDay _morningEnd;
  late TimeOfDay _afternoonStart;
  late TimeOfDay _afternoonEnd;
  late TimeOfDay _nightStart;
  late TimeOfDay _nightEnd;

  @override
  void initState() {
    super.initState();
    _morningStart = widget.initialSettings.morningStart;
    _morningEnd = widget.initialSettings.morningEnd;
    _afternoonStart = widget.initialSettings.afternoonStart;
    _afternoonEnd = widget.initialSettings.afternoonEnd;
    _nightStart = widget.initialSettings.nightStart;
    _nightEnd = widget.initialSettings.nightEnd;
  }

  Future<void> _pickTime(
      TimeOfDay initialTime, void Function(TimeOfDay) onPicked) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      setState(() {
        onPicked(pickedTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Configurar Intervalos de Tiempo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildIntervalRow('Mañana', _morningStart, _morningEnd,
              (start) => _morningStart = start, (end) => _morningEnd = end),
          _buildIntervalRow('Tarde', _afternoonStart, _afternoonEnd,
              (start) => _afternoonStart = start, (end) => _afternoonEnd = end),
          _buildIntervalRow('Noche', _nightStart, _nightEnd,
              (start) => _nightStart = start, (end) => _nightEnd = end),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalRow(
    String title,
    TimeOfDay start,
    TimeOfDay end,
    void Function(TimeOfDay) onStartChanged,
    void Function(TimeOfDay) onEndChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(title),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () => _pickTime(start, onStartChanged),
            child: Text(
                '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'),
          ),
          const SizedBox(width: 8),
          const Text('a'),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _pickTime(end, onEndChanged),
            child: Text(
                '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    final newSettings = TimeIntervalSettings(
      morningStart: _morningStart,
      morningEnd: _morningEnd,
      afternoonStart: _afternoonStart,
      afternoonEnd: _afternoonEnd,
      nightStart: _nightStart,
      nightEnd: _nightEnd,
    );

    if (newSettings.isValidConfiguration()) {
      widget.onSave(newSettings);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración de intervalos no válida')),
      );
    }
  }
}
