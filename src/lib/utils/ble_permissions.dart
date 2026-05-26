import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bluetooth LE permissions + adapter check (Android/iOS).
class BlePermissions {
  BlePermissions._();

  static Future<String?> ensureReady() async {
    if (!(await FlutterBluePlus.isSupported)) {
      return 'Bluetooth niet ondersteund op dit apparaat';
    }

    final toRequest = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];
    if (Platform.isAndroid) {
      // Needed on many Android builds for scan results to appear.
      toRequest.add(Permission.locationWhenInUse);
    }

    final statuses = await toRequest.request();
    final denied = statuses.entries
        .where((e) => !e.value.isGranted && !e.value.isLimited)
        .map((e) => e.key)
        .toList();
    if (denied.isNotEmpty) {
      debugPrint('[BlePermissions] denied: $denied');
      return 'Bluetooth- en locatie-permissies nodig voor scannen';
    }

    final state = await FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => BluetoothAdapterState.off,
        );

    if (state != BluetoothAdapterState.on) {
      return 'Zet Bluetooth aan';
    }

    return null;
  }
}
