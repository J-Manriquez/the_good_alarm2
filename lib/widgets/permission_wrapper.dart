import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class PermissionWrapper extends StatefulWidget {
  final Widget child;

  const PermissionWrapper({
    super.key,
    required this.child,
  });

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  final PermissionService _permissionService = PermissionService();
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await _permissionService.checkInitialPermissions();
    if (!_permissionService.areAllCriticalPermissionsGranted && mounted) {
      await _permissionService.requestRequiredPermissions(context);
    }
    if (mounted) {
      setState(() {
        _checkingPermissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_permissionService.areAllCriticalPermissionsGranted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Permisos Necesarios',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Para usar las alarmas, necesitamos algunos permisos básicos.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _permissionService.temporarilySkipPermissions();
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: const Text('Más tarde'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _permissionService.requestRequiredPermissions(context);
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      child: const Text('Conceder Permisos'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}