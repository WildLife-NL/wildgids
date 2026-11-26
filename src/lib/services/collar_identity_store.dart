import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/utils/ble_mac_format.dart';

/// Apple supplies a peripheral UUID, while the backend requires an EUI-48.
/// Keep a user-confirmed mapping; never invent a MAC from a UUID, partial
/// SPxxxxxx name, or an undocumented manufacturer-data byte layout.
class CollarIdentityStore {
  static const _key = 'collar_device_hardware_addresses';

  static String deviceKey(String id) => id.trim().toUpperCase();

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = jsonDecode(prefs.getString(_key) ?? '{}');
      if (raw is! Map) return {};
      return {
        for (final entry in raw.entries)
          if (entry.key is String &&
              entry.value is String &&
              isValidBleHardwareAddress(entry.value))
            deviceKey(entry.key): entry.value as String,
      };
    } on FormatException {
      return {};
    }
  }

  static String? validate(String address, {String? advertisedName}) {
    final mac = formatBleHardwareAddress(address);
    if (!isValidBleHardwareAddress(mac)) {
      return 'Vul het volledige Bluetooth-MAC-adres in, bijvoorbeeld AA:BB:CC:DD:EE:FF.';
    }
    // Smart Parks documents SP + the last three MAC bytes as the default name.
    final name = (advertisedName ?? '').trim().toUpperCase();
    if (RegExp(r'^SP[0-9A-F]{6}$').hasMatch(name) &&
        !mac.replaceAll(':', '').endsWith(name.substring(2))) {
      return 'Dit adres hoort niet bij $name. Controleer het adres van deze tracker.';
    }
    return null;
  }

  static Future<void> save(String deviceId, String hardwareAddress) async {
    final mac = formatBleHardwareAddress(hardwareAddress);
    final error = validate(mac);
    if (error != null) throw ArgumentError(error);
    final mappings = await load();
    mappings[deviceKey(deviceId)] = mac;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(mappings));
  }
}
