import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:the_good_alarm/configuracion/app_settings.dart';
import 'package:the_good_alarm/configuracion/theme_provider.dart';
import 'package:the_good_alarm/services/alarm_service.dart';

// Importaremos estos archivos cuando los creemos
// import 'config/theme_provider.dart';
// import 'services/notification_service.dart';
// import 'services/background_service.dart';
// import 'screens/home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar notificaciones
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
    print('Error initializing notifications: $e');
  }

  // Solicitar permisos
  await requestPermissions();

  // Iniciar servicio en segundo plano
  await initializeService();

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  await Permission.notification.request();
  await Permission.systemAlertWindow.request();
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'alarm_service',
      initialNotificationTitle: 'Servicio de Alarma',
      initialNotificationContent: 'Iniciando...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration:
        IosConfiguration(), // Requerido por el paquete aunque no lo usemos
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Lógica del servicio en segundo plano
  // Aquí implementaremos la lógica para manejar las alarmas
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
        Provider<AlarmService>(create: (_) => AlarmService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Alarm Game App',
            themeMode: themeProvider.themeMode,
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            home: const Placeholder(), // Aquí irá HomeScreen
          );
        },
      ),
    );
  }
}
