import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/alarm.dart';
import 'notification_service.dart';
import 'alarm_service.dart';

@pragma('vm:entry-point')
void backgroundMain() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  final service = FlutterBackgroundService();
  
  service.invoke('stopService');
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> initialize() async {
    await _service.configure(
      iosConfiguration: IosConfiguration(), // Requerido por el paquete
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'alarm_service',
        initialNotificationTitle: 'Servicio de Alarma',
        initialNotificationContent: 'Ejecutándose en segundo plano',
        foregroundServiceNotificationId: 888,
        autoStartOnBoot: true,
      ),
    );

    await _service.startService();
  }

  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  Future<void> updateAlarms() async {
    _service.invoke('updateAlarms');
  }

  Future<void> stopService() async {
    _service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Inicializar servicios necesarios
  final notificationService = NotificationService();
  final alarmService = AlarmService();
  await notificationService.initialize();
  await alarmService.initialize();

  // Verificar alarmas cada minuto
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Actualizar notificación del servicio
        service.setForegroundNotificationInfo(
          title: 'Servicio de Alarma',
          content: 'Monitoreando alarmas - ${DateTime.now().toString()}',
        );
      }
    }

    _checkAlarms(alarmService, notificationService);
  });

  // Manejar eventos del servicio
  service.on('updateAlarms').listen((event) async {
    await alarmService.initialize();
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Manejar reinicios del dispositivo
  service.on('onBoot').listen((event) async {
    await _handleDeviceBoot(alarmService, notificationService);
  });
}

Future<void> _checkAlarms(
  AlarmService alarmService,
  NotificationService notificationService,
) async {
  final now = DateTime.now();
  final activeAlarms = alarmService.getActiveAlarms();

  for (final alarm in activeAlarms) {
    if (_shouldTriggerAlarm(alarm, now)) {
      await _triggerAlarm(alarm, notificationService);
    }
  }
}

bool _shouldTriggerAlarm(Alarm alarm, DateTime now) {
  if (!alarm.isEnabled) return false;

  final nextAlarmTime = alarm.getNextAlarmTime();
  return nextAlarmTime.year == now.year &&
         nextAlarmTime.month == now.month &&
         nextAlarmTime.day == now.day &&
         nextAlarmTime.hour == now.hour &&
         nextAlarmTime.minute == now.minute;
}

Future<void> _triggerAlarm(
  Alarm alarm,
  NotificationService notificationService,
) async {
  // Mostrar pantalla completa y notificación
  await notificationService.showAlarmNotification(alarm);
}

Future<void> _handleDeviceBoot(
  AlarmService alarmService,
  NotificationService notificationService,
) async {
  // Reprogramar todas las alarmas activas después del reinicio
  final activeAlarms = alarmService.getActiveAlarms();
  for (final alarm in activeAlarms) {
    await notificationService.scheduleAlarm(alarm);
  }
}