import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bluetooth LE permissions + adapter check (Android/iOS).
class BlePermissions {
  BlePermissions._();

  static const permissionDeniedMessage =
      'Bluetooth-permissie nodig voor scannen (Instellingen → Wild Gids)';
  static const androidPermissionDeniedMessage =
      'Bluetooth- en locatie-permissies nodig voor scannen';

  static bool isPermissionError(String? message) =>
      message == permissionDeniedMessage ||
      message == androidPermissionDeniedMessage;

  /// Scan/connect are Android permissions, not aliases for Apple's Bluetooth
  /// permission. Requesting them on iOS always reports denied.
  @visibleForTesting
  static List<Permission> permissionsFor(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => [Permission.bluetooth],
        TargetPlatform.android => [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ],
        _ => [],
      };

  static Future<String?> ensureReady() async {
    try {
      return await _checkReady();
    } catch (error) {
      debugPrint('[BlePermissions] Bluetooth check failed: $error');
      return 'Bluetooth controleren mislukt. Probeer opnieuw.';
    }
  }

  static Future<String?> _checkReady() async {
    if (!(await FlutterBluePlus.isSupported)) {
      return 'Bluetooth niet ondersteund op dit apparaat';
    }

    final permissions = permissionsFor(defaultTargetPlatform);
    if (permissions.isEmpty) {
      return 'Bluetooth niet ondersteund op dit apparaat';
    }
    final statuses = await permissions.request();
    final denied =
        statuses.entries
            .where((e) => !e.value.isGranted && !e.value.isLimited)
            .map((e) => e.key)
            .toList();
    if (denied.isNotEmpty) {
      debugPrint('[BlePermissions] denied: $denied');
      if (defaultTargetPlatform == TargetPlatform.android) {
        return androidPermissionDeniedMessage;
      }
      return permissionDeniedMessage;
    }

    final state = await FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => BluetoothAdapterState.off,
        );

    if (state == BluetoothAdapterState.unauthorized) {
      return permissionDeniedMessage;
    }
    if (state != BluetoothAdapterState.on) {
      return 'Zet Bluetooth aan';
    }

    return null;
  }
}
