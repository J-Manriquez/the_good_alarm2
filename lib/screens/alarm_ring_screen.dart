import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import '../configuracion/app_settings.dart';
import 'games/math_game_screen.dart';
import 'games/memory_game_screen.dart';

class AlarmRingScreen extends StatefulWidget {
  final Alarm alarm;

  const AlarmRingScreen({
    super.key,
    required this.alarm,
  });

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSnoozing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _requestWakeLock();
    _startVibration();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  Future<void> _requestWakeLock() async {
    // Implementar wake lock para mantener la pantalla encendida
    // Usar package: wakelock
  }

  void _startVibration() {
    final appSettings = context.read<AppSettings>();
    if (appSettings.vibrationEnabled) {
      // Implementar vibración
      // Usar package: vibration
    }
  }

  void _stopVibration() {
    // Detener vibración
  }

  Future<void> _handleStopAlarm() async {
    if (widget.alarm.requireGame && !_isSnoozing) {
      final gameCompleted = await _showGame();
      if (!gameCompleted) {
        return;
      }
    }

    if (mounted) {
      final alarmService = context.read<AlarmService>();
      await alarmService.stopAlarm(widget.alarm.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleSnooze() async {
    setState(() => _isSnoozing = true);
    
    final alarmService = context.read<AlarmService>();
    await alarmService.snoozeAlarm(widget.alarm.id);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showGame() async {
    if (!mounted) return false;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          if (widget.alarm.selectedGame == 'math') {
            return MathGameScreen(
              difficulty: widget.alarm.gameDifficulty ?? 'easy',
              onGameComplete: () => Navigator.pop(context, true),
              onGameFailed: () => Navigator.pop(context, false),
            );
          } else {
            return MemoryGameScreen(
              difficulty: widget.alarm.gameDifficulty ?? 'easy',
              onGameComplete: () => Navigator.pop(context, true),
              onGameFailed: () => Navigator.pop(context, false),
            );
          }
        },
      ),
    );

    return result ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopVibration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return PopScope(
      canPop: false, // Prevenir el botón de retroceso
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cabecera con la hora
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _animation.value,
                              child: Text(
                                _formatTime(widget.alarm.time),
                                style: TextStyle(
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.alarm.name.isEmpty ? 'Alarma' : widget.alarm.name,
                          style: TextStyle(
                            fontSize: 24,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botones de acción
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.alarm.canSnooze() && !_isSnoozing) ...[
                          ElevatedButton(
                            onPressed: _handleSnooze,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Posponer ${widget.alarm.snoozeTime} minutos',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: _handleStopAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            widget.alarm.requireGame
                                ? 'Detener con Juego'
                                : 'Detener',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}