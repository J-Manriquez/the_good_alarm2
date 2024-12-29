import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/alarm.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const String alarmChannelId = 'alarm_channel';
  static const String alarmChannelName = 'Alarmas';
  static const String alarmChannelDescription = 'Notificaciones de alarmas';
  
  static const String snoozeActionId = 'SNOOZE';
  static const String stopActionId = 'STOP';
  static const String openActionId = 'OPEN';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    // Configuración para Android
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // Inicializar notificaciones
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
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
      alarmChannelName,
      description: alarmChannelDescription,
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);
  }

  Future<void> _requestPermissions() async {
    final platform = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (platform != null) {
      await platform.requestNotificationsPermission();
    }
  }
  

  Future<void> showAlarmNotification(Alarm alarm) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDescription,
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
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      ongoing: true,
      autoCancel: false,
    );

    await _notifications.show(
      alarm.id.hashCode,
      'Alarma - ${alarm.name}',
      'Es hora de despertar',
      const NotificationDetails(android: androidPlatformChannelSpecifics),
      payload: alarm.toJsonString(),
    );
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    final nextAlarmTime = alarm.getNextAlarmTime();
    
    const androidDetails = AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDescription,
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

  Future<void> cancelAlarm(String alarmId) async {
    await _notifications.cancel(alarmId.hashCode);
  }

  Future<void> cancelAllAlarms() async {
    await _notifications.cancelAll();
  }

  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
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
    await _onNotificationResponse(response);
  }

  static Future<void> _handleSnooze(Alarm alarm) async {
    // Implementar lógica de snooze
  }

  static Future<void> _handleStop(Alarm alarm) async {
    // Implementar lógica de stop
  }

  static Future<void> _handleOpen(Alarm alarm) async {
    // Implementar lógica para abrir la app
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}