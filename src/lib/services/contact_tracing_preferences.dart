import 'package:shared_preferences/shared_preferences.dart';

/// Opgeslagen instellingen voor Bluetooth-contacttracing.
class ContactTracingPreferences {
  ContactTracingPreferences._();

  static const backgroundEnabledKey = 'contact_tracing_background_enabled';
  static const backgroundIntervalSecondsKey =
      'contact_tracing_background_interval_seconds';
  static const activeScanIntervalSecondsKey =
      'contact_tracing_active_scan_interval_seconds';
  static const signalLossSecondsKey = 'contact_tracing_signal_loss_seconds';
  static const notifyOnAnimalFoundKey = 'contact_tracing_notify_on_found';
  static const onlySmartParksKey = 'contact_tracing_only_smart_parks';

  static const int defaultBackgroundIntervalSeconds = 60;
  static const int minBackgroundIntervalSeconds = 60;
  static const int maxBackgroundIntervalSeconds = 300;

  static const int defaultActiveScanIntervalSeconds = 30;
  static const int minActiveScanIntervalSeconds = 15;
  static const int maxActiveScanIntervalSeconds = 120;

  static const int defaultSignalLossSeconds = 30;
  static const int minSignalLossSeconds = 15;
  static const int maxSignalLossSeconds = 120;

  static Future<ContactTracingSettings> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return ContactTracingSettings(
      backgroundEnabled: prefs.getBool(backgroundEnabledKey) ?? false,
      backgroundIntervalSeconds: _clamp(
        prefs.getInt(backgroundIntervalSecondsKey) ??
            defaultBackgroundIntervalSeconds,
        minBackgroundIntervalSeconds,
        maxBackgroundIntervalSeconds,
      ),
      activeScanIntervalSeconds: _clamp(
        prefs.getInt(activeScanIntervalSecondsKey) ??
            defaultActiveScanIntervalSeconds,
        minActiveScanIntervalSeconds,
        maxActiveScanIntervalSeconds,
      ),
      signalLossSeconds: _clamp(
        prefs.getInt(signalLossSecondsKey) ?? defaultSignalLossSeconds,
        minSignalLossSeconds,
        maxSignalLossSeconds,
      ),
      notifyOnAnimalFound: prefs.getBool(notifyOnAnimalFoundKey) ?? true,
      onlySmartParks: prefs.getBool(onlySmartParksKey) ?? true,
    );
  }

  static Future<void> save(ContactTracingSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(backgroundEnabledKey, settings.backgroundEnabled);
    await prefs.setInt(
      backgroundIntervalSecondsKey,
      settings.backgroundIntervalSeconds,
    );
    await prefs.setInt(
      activeScanIntervalSecondsKey,
      settings.activeScanIntervalSeconds,
    );
    await prefs.setInt(signalLossSecondsKey, settings.signalLossSeconds);
    await prefs.setBool(notifyOnAnimalFoundKey, settings.notifyOnAnimalFound);
    await prefs.setBool(onlySmartParksKey, settings.onlySmartParks);
  }

  static int _clamp(int value, int min, int max) => value.clamp(min, max);
}

class ContactTracingSettings {
  const ContactTracingSettings({
    required this.backgroundEnabled,
    required this.backgroundIntervalSeconds,
    required this.activeScanIntervalSeconds,
    required this.signalLossSeconds,
    required this.notifyOnAnimalFound,
    required this.onlySmartParks,
  });

  final bool backgroundEnabled;
  final int backgroundIntervalSeconds;
  final int activeScanIntervalSeconds;
  final int signalLossSeconds;
  final bool notifyOnAnimalFound;
  final bool onlySmartParks;

  ContactTracingSettings copyWith({
    bool? backgroundEnabled,
    int? backgroundIntervalSeconds,
    int? activeScanIntervalSeconds,
    int? signalLossSeconds,
    bool? notifyOnAnimalFound,
    bool? onlySmartParks,
  }) {
    return ContactTracingSettings(
      backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      backgroundIntervalSeconds:
          backgroundIntervalSeconds ?? this.backgroundIntervalSeconds,
      activeScanIntervalSeconds:
          activeScanIntervalSeconds ?? this.activeScanIntervalSeconds,
      signalLossSeconds: signalLossSeconds ?? this.signalLossSeconds,
      notifyOnAnimalFound: notifyOnAnimalFound ?? this.notifyOnAnimalFound,
      onlySmartParks: onlySmartParks ?? this.onlySmartParks,
    );
  }
}

