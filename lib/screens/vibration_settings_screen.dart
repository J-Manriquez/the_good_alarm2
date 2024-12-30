import 'package:flutter/material.dart';
import '../services/vibration_service.dart';

class VibrationSettingsScreen extends StatefulWidget {
  const VibrationSettingsScreen({super.key});

  @override
  State<VibrationSettingsScreen> createState() => _VibrationSettingsScreenState();
}

class _VibrationSettingsScreenState extends State<VibrationSettingsScreen> {
  final VibrationService _vibrationService = VibrationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Vibración'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Vibración'),
            subtitle: const Text('Activar o desactivar la vibración'),
            value: _vibrationService.isEnabled,
            onChanged: (value) async {
              await _vibrationService.setEnabled(value);
              setState(() {});
            },
          ),
          if (_vibrationService.isEnabled) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Patrones de Vibración',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...VibrationService.vibrationPatterns.keys.map(
              (pattern) => _buildPatternTile(pattern),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternTile(String pattern) {
    final isSelected = _vibrationService.currentPattern == pattern;
    
    return ListTile(
      title: Text(
        pattern.substring(0, 1).toUpperCase() + pattern.substring(1),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _vibrationService.testVibration(pattern),
          ),
          Radio<String>(
            value: pattern,
            groupValue: _vibrationService.currentPattern,
            onChanged: (value) async {
              if (value != null) {
                await _vibrationService.setPattern(value);
                setState(() {});
              }
            },
          ),
        ],
      ),
      selected: isSelected,
      onTap: () async {
        await _vibrationService.setPattern(pattern);
        setState(() {});
      },
    );
  }
}