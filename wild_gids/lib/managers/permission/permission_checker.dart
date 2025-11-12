import 'package:flutter/material.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
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
      debugPrint('\x1B[31m[${widget.runtimeType}] Providers not initialized\x1B[0m');
      return;
    }

    bool hasPermission = await _permissionManager!.isPermissionGranted(
      PermissionType.location,
    );
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('Permission granted: $hasPermission, serviceEnabled: $serviceEnabled');

    // If either permission or device location service is missing, request/ask the user.
    if (!hasPermission || !serviceEnabled) {
      // Defer permission/service request to a synchronous callback with fresh context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // ensure state is still active before using context
        _requestPermissions();
      });
    } else {
      await _handlePermissionGranted();
    }
  }

  void _requestPermissions() {
    if (_permissionManager == null || _appStateProvider == null) {
      debugPrint('\x1B[31m[${widget.runtimeType}] Providers not initialized\x1B[0m');
      return;
    }

    // Use fresh context here. Make permission mandatory: if the user denies,
    // show a blocking dialog that forces them to either retry, open settings,
    // or exit the app. Loop until permission is granted and the device location
    // service is enabled, or the user exits.
    Future<void>.microtask(() async {
      // Initial permission request (permission manager internally shows rationale if needed)
      // ignore: use_build_context_synchronously
      bool hasPermission = await _permissionManager!.requestPermission(
        context,
        PermissionType.location,
        showRationale: true,
      );

      if (!mounted) return; // avoid using context across async gap

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (hasPermission && serviceEnabled) {
        await _handlePermissionGranted();
        return;
      }

      debugPrint('\x1B[31m[${widget.runtimeType}] Location permission/service missing - showing mandatory dialog\x1B[0m');

      // Loop until permission and device location service are available or user exits
      while (!(hasPermission && serviceEnabled)) {
        if (!mounted) break; // user likely left the screen

        // Ask the user to enable permission and/or device location service
        // ignore: use_build_context_synchronously
        final action = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Locatie vereist'),
            content: const Text(
              'WildGids heeft locatie-tracking nodig om te werken. Geef locatie toestemming en zet locatie (GPS) aan, of sluit de app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('retry'),
                child: const Text('Opnieuw proberen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('settings'),
                child: const Text('Instellingen openen'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('exit'),
                child: const Text('Afsluiten'),
              ),
            ],
          ),
        );

        if (action == 'retry') {
          if (!mounted) break;
          // ignore: use_build_context_synchronously
          hasPermission = await _permissionManager!.requestPermission(
            context,
            PermissionType.location,
            showRationale: true,
          );
          if (!mounted) break;
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!mounted) break;
          if (hasPermission && serviceEnabled) {
            await _handlePermissionGranted();
            break;
          }
        } else if (action == 'settings') {
          // Open OS location settings (device) so user can enable GPS, and also open app settings
          await Geolocator.openLocationSettings();
          await ph.openAppSettings();
          if (!mounted) break;
          // After returning from settings, re-check grant status and service status.
          hasPermission = await _permissionManager!.isPermissionGranted(PermissionType.location);
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!mounted) break;
          if (hasPermission && serviceEnabled) {
            await _handlePermissionGranted();
            break;
          }
        } else {
          // Exit the app
          SystemNavigator.pop();
          break;
        }
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
