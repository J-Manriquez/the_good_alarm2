import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm.dart';
import '../services/alarm_service.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Canales de notificación
  static const String alarmChannelId = 'alarm_channel';
  static const String snoozeChannelId = 'snooze_channel';
  static const String reminderChannelId = 'reminder_channel';
  
  // IDs de acciones
  static const String snoozeActionId = 'SNOOZE';
  static const String stopActionId = 'STOP';
  static const String openActionId = 'OPEN';

  Future<void> initialize() async {
    // Inicializar timezone
    tz.initializeTimeZones();

    // Configuración para Android
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // Inicializar plugin
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await _onNotificationResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // Configurar canales
    await _setupNotificationChannels();
    
    // Solicitar permisos
    await _requestPermissions();
  }

  Future<void> _setupNotificationChannels() async {
    // Canal principal para alarmas
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      alarmChannelId,
      'Alarmas',
      description: 'Notificaciones de alarmas activas',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      showBadge: true,
    );

    // Canal para recordatorios de snooze
    const AndroidNotificationChannel snoozeChannel = AndroidNotificationChannel(
      snoozeChannelId,
      'Posponer Alarmas',
      description: 'Notificaciones de alarmas pospuestas',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    // Canal para recordatorios generales
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      reminderChannelId,
      'Recordatorios',
      description: 'Recordatorios y avisos generales',
      importance: Importance.low, // Cambiado de default a low
      enableVibration: true,
    );

    final platform = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (platform != null) {
      await platform.createNotificationChannel(alarmChannel);
      await platform.createNotificationChannel(snoozeChannel);
      await platform.createNotificationChannel(reminderChannel);
    }
  }

  // Método para programar alarmas
  Future<void> scheduleAlarm(Alarm alarm) async {
    final nextAlarmTime = alarm.getNextAlarmTime();
    
    const androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      'Alarma Programada',
      channelDescription: 'Notificación de alarma programada',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        AndroidNotificationAction(
          snoozeActionId,
          'Posponer',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          stopActionId,
          'Detener',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    await _notifications.zonedSchedule(
      alarm.id.hashCode,
      'Alarma programada - ${alarm.name}',
      'Sonará a las ${_formatTime(nextAlarmTime)}',
      tz.TZDateTime.from(nextAlarmTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: alarm.isOneTime
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
      payload: alarm.toJsonString(),
    );
  }

  Future<void> showAlarmNotification(Alarm alarm) async {
    final now = DateTime.now();
    final bool isSnoozeAllowed = alarm.canSnooze();

    final List<AndroidNotificationAction> actions = [
      if (isSnoozeAllowed)
        const AndroidNotificationAction(
          snoozeActionId,
          'Posponer',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      const AndroidNotificationAction(
        stopActionId,
        'Detener',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      'Alarma',
      channelDescription: 'Notificación de alarma activa',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      actions: actions,
      category: AndroidNotificationCategory.alarm,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
      ongoing: true,
      autoCancel: false,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      alarm.id.hashCode,
      _getNotificationTitle(alarm),
      _getNotificationBody(alarm, now),
      details,
      payload: alarm.toJsonString(),
    );

    await _vibrate();
  }

  Future<void> showSnoozeNotification(Alarm alarm) async {
    final androidDetails = AndroidNotificationDetails(
      snoozeChannelId,
      'Alarma Pospuesta',
      channelDescription: 'Notificación de alarma pospuesta',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      autoCancel: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      alarm.id.hashCode + 1,
      'Alarma Pospuesta',
      'La alarma sonará nuevamente en ${alarm.snoozeTime} minutos',
      details,
      payload: alarm.toJsonString(),
    );
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final String? payload = response.payload;
    if (payload == null) return;

    final alarm = Alarm.fromJsonString(payload);
    
    switch (response.actionId) {
      case snoozeActionId:
        await _handleSnooze(alarm);
        break;
      case stopActionId:
        await _handleStop(alarm);
        break;
      case openActionId:
      default:
        await _handleOpen(alarm);
        break;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundNotificationResponse(
    NotificationResponse response,
  ) async {
    // Manejar respuesta en segundo plano
    final notificationService = NotificationService();
    await notificationService._onNotificationResponse(response);
  }

  Future<void> _handleSnooze(Alarm alarm) async {
    final alarmService = AlarmService();
    
    if (!alarm.canSnooze()) {
      await showReminderNotification(
        'No se puede posponer',
        'Has alcanzado el límite de repeticiones',
      );
      return;
    }

    await alarmService.snoozeAlarm(alarm.id);
    await showSnoozeNotification(alarm);
    await _vibrate(pattern: [0, 100, 100, 100]);
  }

  Future<void> _handleStop(Alarm alarm) async {
    final alarmService = AlarmService();
    await alarmService.stopAlarm(alarm.id);
    await cancelAlarm(alarm.id);
    await _vibrate(pattern: [0, 50]);
  }

  Future<void> _handleOpen(Alarm alarm) async {
    // Se implementará cuando se añada la navegación
  }

  Future<void> cancelAlarm(String alarmId) async {
    await _notifications.cancel(alarmId.hashCode);
  }

  Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
  }

  Future<void> _requestPermissions() async {
    final platform = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (platform != null) {
      await platform.requestNotificationsPermission();
    }
  }

  Future<void> showReminderNotification(String title, String body) async {
    final androidDetails = AndroidNotificationDetails(
      reminderChannelId,
      'Recordatorio',
      channelDescription: 'Notificación de recordatorio',
      importance: Importance.low, // Cambiado de default a low
      priority: Priority.low, // Cambiado de default a low
      autoCancel: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      title,
      body,
      details,
    );
  }

  String _getNotificationTitle(Alarm alarm) {
    if (alarm.name.isNotEmpty) {
      return '¡Alarma! - ${alarm.name}';
    }
    return '¡Alarma!';
  }

  String _getNotificationBody(Alarm alarm, DateTime now) {
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (alarm.requireGame) {
      return 'Son las $timeStr - Completa el juego para detener la alarma';
    }
    return 'Son las $timeStr';
  }

  Future<void> _vibrate({List<int>? pattern}) async {
    try {
      if (pattern != null) {
        await SystemChannels.platform.invokeMethod('HapticFeedback.vibrate', pattern);
      } else {
        await SystemChannels.platform.invokeMethod('HapticFeedback.vibrate');
      }
    } catch (e) {
      // Manejar error de vibración
      print('Error al vibrar: $e');
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}