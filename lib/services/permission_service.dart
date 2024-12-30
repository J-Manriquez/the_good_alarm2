import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Clave para SharedPreferences
  static const String _tempSkipPermissionsKey = 'temp_skip_permissions';

  // Separar permisos por categorías
  final List<Permission> _criticalPermissions = [
    Permission.notification,
    Permission.systemAlertWindow,
  ];

  final List<Permission> _optimizationPermissions = [
    Permission.ignoreBatteryOptimizations,
    Permission.accessNotificationPolicy,
  ];

  final List<Permission> _optionalPermissions = [
    Permission.scheduleExactAlarm,
  ];

  // Estado de los permisos
  final Map<Permission, bool> _permissionStatus = {};
  bool _temporarilySkipped = false;

  // Stream para notificar cambios en los permisos
  final _permissionController = StreamController<Map<Permission, bool>>.broadcast();
  Stream<Map<Permission, bool>> get permissionStream => _permissionController.stream;

  // Verificar permisos al iniciar
  Future<bool> checkInitialPermissions() async {
    // Verificar si los permisos están temporalmente ignorados
    final prefs = await SharedPreferences.getInstance();
    _temporarilySkipped = prefs.getBool(_tempSkipPermissionsKey) ?? false;

    bool allCriticalGranted = true;
    
    // Verificar permisos críticos
    for (var permission in _criticalPermissions) {
      final status = await permission.status;
      _permissionStatus[permission] = status.isGranted;
      if (!status.isGranted) {
        allCriticalGranted = false;
      }
    }

    // Verificar permisos de optimización
    for (var permission in _optimizationPermissions) {
      final status = await permission.status;
      _permissionStatus[permission] = status.isGranted;
    }

    _permissionController.add(_permissionStatus);
    return allCriticalGranted || _temporarilySkipped;
  }

  Future<void> temporarilySkipPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tempSkipPermissionsKey, true);
    _temporarilySkipped = true;
    _permissionController.add(_permissionStatus);
  }

  Future<void> resetTemporarySkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tempSkipPermissionsKey);
    _temporarilySkipped = false;
  }

  // Solicitar permisos críticos y mostrar diálogo para optimizaciones
  Future<bool> requestRequiredPermissions(BuildContext context) async {
    // Primero solicitar permisos críticos
    bool allCriticalGranted = true;
    for (var permission in _criticalPermissions) {
      if (!await permission.isGranted) {
        final status = await permission.request();
        _permissionStatus[permission] = status.isGranted;
        if (!status.isGranted) {
          allCriticalGranted = false;
        }
      } else {
        _permissionStatus[permission] = true;
      }
    }

    // Si los permisos críticos están concedidos, mostrar diálogo para optimizaciones
    if (allCriticalGranted && context.mounted) {
      await _showOptimizationDialog(context);
    }

    _permissionController.add(_permissionStatus);
    return allCriticalGranted;
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

  void dispose() {
    _permissionController.close();
  }
}