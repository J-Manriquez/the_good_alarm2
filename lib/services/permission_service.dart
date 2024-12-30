import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static const String _tempSkipPermissionsKey = 'temp_skip_permissions';

  final List<Permission> _criticalPermissions = [
    Permission.notification,
    Permission.scheduleExactAlarm,
  ];

  final List<Permission> _backgroundPermissions = [
    Permission.systemAlertWindow,
    Permission.ignoreBatteryOptimizations,
  ];

  final List<Permission> _locationPermissions = [
    Permission.location,
    Permission.locationAlways,
    Permission.locationWhenInUse,
  ];

  final Map<Permission, bool> _permissionStatus = {};
  bool _temporarilySkipped = false;

  Future<bool> checkInitialPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    _temporarilySkipped = prefs.getBool(_tempSkipPermissionsKey) ?? false;

    // Verificar permisos críticos
    for (var permission in _criticalPermissions) {
      final status = await permission.status;
      _permissionStatus[permission] = status.isGranted;
    }

    // Verificar permisos de segundo plano
    for (var permission in _backgroundPermissions) {
      final status = await permission.status;
      _permissionStatus[permission] = status.isGranted;
    }

    // Verificar permisos de ubicación
    for (var permission in _locationPermissions) {
      final status = await permission.status;
      _permissionStatus[permission] = status.isGranted;
    }

    return _criticalPermissions.every((p) => 
        _permissionStatus[p] == true) || _temporarilySkipped;
  }

  Future<void> temporarilySkipPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tempSkipPermissionsKey, true);
    _temporarilySkipped = true;
  }

  Future<void> resetTemporarySkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tempSkipPermissionsKey);
    _temporarilySkipped = false;
  }

  // Solicitar permisos críticos y mostrar diálogo para optimizaciones
  
  Future<bool> requestRequiredPermissions(BuildContext context) async {
    bool allGranted = true;

    // Solicitar permisos críticos
    for (var permission in _criticalPermissions) {
      final status = await permission.request();
      _permissionStatus[permission] = status.isGranted;
      if (!status.isGranted) allGranted = false;
    }

    // Solicitar permisos de segundo plano
    for (var permission in _backgroundPermissions) {
      await permission.request();
    }

    // Solicitar permisos de ubicación
    for (var permission in _locationPermissions) {
      await permission.request();
    }

    return allGranted;
  }

  Future<void> _showOptimizationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Optimización Recomendada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para garantizar el mejor funcionamiento de las alarmas, recomendamos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOptimizationItem(
              context,
              'Desactivar optimización de batería',
              'Para que las alarmas funcionen incluso en segundo plano',
              Permission.ignoreBatteryOptimizations,
            ),
            const SizedBox(height: 8),
            _buildOptimizationItem(
              context,
              'Permitir control de sonido',
              'Para gestionar el volumen de las alarmas',
              Permission.accessNotificationPolicy,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await temporarilySkipPermissions();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Más tarde'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Configurar'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationItem(
    BuildContext context,
    String title,
    String description,
    Permission permission,
  ) {
    return FutureBuilder<bool>(
      future: permission.isGranted,
      builder: (context, snapshot) {
        final isGranted = snapshot.data ?? false;
        return Row(
          children: [
            Icon(
              isGranted ? Icons.check_circle : Icons.warning,
              color: isGranted ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool get areAllCriticalPermissionsGranted {
    return _criticalPermissions.every(
      (permission) => _permissionStatus[permission] == true,
    ) || _temporarilySkipped;
  }

  bool isPermissionGranted(Permission permission) {
    return _permissionStatus[permission] ?? false;
  }


}