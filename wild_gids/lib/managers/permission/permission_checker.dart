import 'package:flutter/material.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

mixin PermissionChecker<T extends StatefulWidget> on State<T> {
  bool _hasCheckedPermissions = false;
  PermissionInterface? _permissionManager;
  AppStateProvider? _appStateProvider;

  @override
  void initState() {
    super.initState();
    // Cache providers synchronously
    _permissionManager = context.read<PermissionInterface>();
    _appStateProvider = context.read<AppStateProvider>();
    initiatePermissionCheck();
  }

  void initiatePermissionCheck() {
    if (!_hasCheckedPermissions) {
      _hasCheckedPermissions = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPermissions();
      });
    }
  }

  Future<void> _checkPermissions() async {
    if (_permissionManager == null || _appStateProvider == null) {
      debugPrint(
        '\x1B[31m[${widget.runtimeType}] Providers not initialized\x1B[0m',
      );
      return;
    }

    bool hasPermission = await _permissionManager!.isPermissionGranted(
      PermissionType.location,
    );
    debugPrint('Permission granted: $hasPermission');

    if (!hasPermission) {
      // Defer permission request to a synchronous callback with fresh context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestPermissions();
      });
    } else {
      await _handlePermissionGranted();
    }
  }

  void _requestPermissions() {
    if (_permissionManager == null || _appStateProvider == null) {
      debugPrint(
        '\x1B[31m[${widget.runtimeType}] Providers not initialized\x1B[0m',
      );
      return;
    }

    // Use fresh context here
    _permissionManager!
        .requestPermission(
          context,
          PermissionType.location,
          showRationale: true,
        )
        .then((hasPermission) {
          if (hasPermission) {
            _handlePermissionGranted();
          } else {
            debugPrint(
              '\x1B[31m[${widget.runtimeType}] Location permission denied\x1B[0m',
            );
          }
        });
  }

  Future<void> _handlePermissionGranted() async {
    if (_appStateProvider == null) return;
    debugPrint('Updating location cache');
    await _appStateProvider!.updateLocationCache();
    _appStateProvider!.startLocationUpdates();
  }
}
