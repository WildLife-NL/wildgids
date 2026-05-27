import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Smart Parks / Ranger BLE identifiers (collar contact tracing).
class ContactTracingBle {
  ContactTracingBle._();

  static const String rangerServiceUuid =
      '84aa6074-528a-8b86-d34c-b71d1ddc538d';
  static const int smartParksCompanyId = 0x0A61;

  static bool isSmartParksAdvertisement(ScanResult result) {
    final name = result.device.platformName.trim();
    final advName = result.advertisementData.advName.trim();
    final hasSpName = name.toUpperCase().startsWith('SP') ||
        advName.toUpperCase().startsWith('SP');
    final hasRangerService = result.advertisementData.serviceUuids.any(
      (u) => u.str.toLowerCase() == rangerServiceUuid,
    );
    final hasManufacturer = result.advertisementData.manufacturerData
        .containsKey(smartParksCompanyId);
    return hasSpName || hasRangerService || hasManufacturer;
  }

  static String deviceLabel(ScanResult result) {
    final name = result.device.platformName.trim();
    if (name.isNotEmpty) return name;
    final adv = result.advertisementData.advName.trim();
    if (adv.isNotEmpty) return adv;
    return 'Onbekend apparaat';
  }
}

