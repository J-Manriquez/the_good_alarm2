import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:the_good_alarm/configuracion/app_settings.dart';
import 'package:the_good_alarm/configuracion/theme_provider.dart';
import 'package:the_good_alarm/screens/home_screen.dart';
import 'package:the_good_alarm/services/alarm_history_service.dart';
import 'package:the_good_alarm/services/alarm_service.dart';
import 'package:logging/logging.dart';
import 'package:the_good_alarm/services/notification_service.dart';
import 'package:the_good_alarm/services/permission_service.dart';
import 'package:the_good_alarm/widgets/permission_wrapper.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final _logger = Logger('MainApp');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Inicializar notificaciones
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  try {
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        // Manejar la respuesta de la notificación
      },
    );
  } catch (e) {
    _logger.severe('Error initializing notifications: $e');
  }

  // Solicitar permisos
  await requestPermissions();

  // Inicializar servicios
  final permissionService = PermissionService();
  await permissionService
      .resetTemporarySkip(); // Resetear el estado temporal al inicio

  final notificationService = NotificationService();
  await notificationService.initialize();

  final alarmService = AlarmService();
  await alarmService.initialize();

  // Iniciar servicio en segundo plano
  await initializeService();

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  // Solicitar los permisos principales
  await [
    Permission.notification,
    Permission.scheduleExactAlarm,
    Permission.systemAlertWindow,
    Permission.location,
  ].request();
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Crear el canal de notificación
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'alarm_service', // id
    'Servicio de Alarma', // title
    description: 'Canal para el servicio de alarma en segundo plano',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Crear el canal de notificación
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: channel.id,
      initialNotificationTitle: channel.name,
      initialNotificationContent:
          channel.description ?? 'Servicio en ejecución',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onBackground: onIosBackground,
      onForeground: onStart,
    ),
  );

  // Iniciar el servicio
  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Asegúrate de inicializar correctamente
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Configuración del canal de notificación
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'alarm_service',
    'Servicio de Alarma',
    description: 'Canal para el servicio de alarma en segundo plano',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Configuración de la notificación
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
  );

  final NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  // Mostrar notificación inicial
  await flutterLocalNotificationsPlugin.show(
    888,
    'Servicio de Alarma',
    'La aplicación está ejecutándose en segundo plano',
    platformChannelSpecifics,
  );

  // Manejar actualizaciones
  service.on('update').listen((event) async {
    await flutterLocalNotificationsPlugin.show(
      888,
      'Servicio de Alarma',
      'Ejecutándose en segundo plano',
      platformChannelSpecifics,
    );
  });

  // Timer para mantener el servicio activo
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    // Cambiar la forma de manejar el servicio en primer plano
    if (service is AndroidServiceInstance) {
      // Verificar si el servicio está en primer plano
      if (await service.isForegroundService()) {
        // Mostrar notificación de actualización
        await flutterLocalNotificationsPlugin.show(
          888,
          'Servicio de Alarma',
          'Activo - ${DateTime.now().toString()}',
          platformChannelSpecifics,
        );

        // Enviar datos al canal de Flutter
        service.invoke(
          'update',
          {
            "current_date": DateTime.now().toIso8601String(),
          },
        );
      }
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

Future<void> updateNotification(String title, String body) async {
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'alarm_service',
    'Servicio de Alarma',
    channelDescription: 'Notificaciones del servicio de alarma',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true,
    autoCancel: false,
  );

  final platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    888,
    title,
    body,
    platformChannelSpecifics,
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider<AlarmService>(
          create: (_) {
            final service = AlarmService();
            service.initialize(); // Inicializar el servicio
            return service;
          },
        ),
        Provider<PermissionService>(create: (_) => PermissionService()),
        Provider<AlarmHistoryService>(
          create: (_) {
            final service = AlarmHistoryService();
            service.initialize(); // Inicializar el servicio
            return service;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'The Good Alarm',
            themeMode: themeProvider.themeMode,
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            home: PermissionWrapper(
              child: HomeScreen(), // Tu pantalla principal
            ),
          );
        },
      ),
    );
  }
}
