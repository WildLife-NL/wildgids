/// Formats a BLE address to EUI-48: `AA:BB:CC:DD:EE:FF` (API requirement).
String formatBleHardwareAddress(String raw) {
  final value = raw.trim().toUpperCase();
  if (!RegExp(
    r'^(?:[0-9A-F]{12}|(?:[0-9A-F]{2}:){5}[0-9A-F]{2}|(?:[0-9A-F]{2}-){5}[0-9A-F]{2})$',
  ).hasMatch(value)) {
    return value;
  }
  final hex = value.replaceAll(RegExp('[:-]'), '');
  if (hex.length != 12) {
    return raw.trim().toUpperCase();
  }
  final parts = <String>[];
  for (var i = 0; i < 12; i += 2) {
    parts.add(hex.substring(i, i + 2));
  }
  return parts.join(':');
}

bool isValidBleHardwareAddress(String value) {
  return RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(value);
}
