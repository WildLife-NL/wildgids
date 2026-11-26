import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wildgids/data_managers/contact_api.dart';
import 'package:wildgids/services/collar_identity_store.dart';
import 'package:wildgids/utils/ble_permissions.dart';
import 'package:wildgids/models/api_models/contact_model.dart';
import 'package:wildgids/services/contact_tracing_ble.dart';
import 'package:wildgids/services/contact_tracing_monitor.dart';
import 'package:wildgids/services/contact_tracing_preferences.dart';
import 'package:wildgids/utils/ble_mac_format.dart';
import 'package:wildgids/utils/notification_service.dart';
import 'package:wildgids/widgets/contact/contact_started_sheet.dart';

/// Achtergrond-BLE: periodiek scannen, contact starten, melding bij dier.
class ContactTracingCoordinator extends ChangeNotifier {
  /// Actieve server-contacten ouder dan dit worden bij start automatisch gesloten.
  static const Duration staleActiveContactMaxAge = Duration(hours: 12);
  ContactTracingCoordinator({
    required ContactApi contactApi,
    required ContactTracingMonitor monitor,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _contactApi = contactApi,
       _monitor = monitor,
       _navigatorKey = navigatorKey;

  final ContactApi _contactApi;
  final ContactTracingMonitor _monitor;
  final GlobalKey<NavigatorState>? _navigatorKey;

  bool _initialized = false;
  ContactTracingSettings _settings = const ContactTracingSettings(
    backgroundEnabled: false,
    backgroundIntervalSeconds:
        ContactTracingPreferences.defaultBackgroundIntervalSeconds,
    activeScanIntervalSeconds:
        ContactTracingPreferences.defaultActiveScanIntervalSeconds,
    signalLossSeconds: ContactTracingPreferences.defaultSignalLossSeconds,
    notifyOnAnimalFound: true,
    onlySmartParks: true,
  );
  final Map<String, String> _hardwareAddresses = {};
  bool _scanInFlight = false;
  bool _disposed = false;
  bool _needsBluetoothPermission = false;
  int _scanEpoch = 0;
  bool _backgroundScanning = false;
  bool _registerInFlight = false;
  int _registrationEpoch = 0;
  String? _inFlightContactId;
  String? _inFlightRegistrationMac;
  String _statusMessage = 'Uit';

  /// Na handmatig beëindigen: zelfde MAC niet opnieuw registreren tot signaal weg-tijd.
  final Map<String, DateTime> _manualEndBlockUntil = {};

  /// Korte onderdrukking van "Contact gestart" voor dezelfde MAC na handmatig einde.
  final Map<String, DateTime> _suppressContactStartedForMac = {};

  final Map<String, ScanResult> _discoveryDevices = {};
  final Map<String, ScanResult> _discoveryDevicesRaw = {};
  Timer? _backgroundTimer;
  StreamSubscription<List<ScanResult>>? _discoveryScanSub;

  bool get backgroundEnabled => _settings.backgroundEnabled;
  int get backgroundIntervalSeconds => _settings.backgroundIntervalSeconds;
  int get activeScanIntervalSeconds => _settings.activeScanIntervalSeconds;
  int get signalLossSeconds => _settings.signalLossSeconds;
  bool get notifyOnAnimalFound => _settings.notifyOnAnimalFound;
  bool get onlySmartParks => _settings.onlySmartParks;
  bool get backgroundScanning => _backgroundScanning;
  bool get registeringContact => _registerInFlight;
  bool get needsBluetoothPermission => _needsBluetoothPermission;
  String get statusMessage => _statusMessage;
  ContactTracingMonitor get monitor => _monitor;

  String? hardwareAddressFor(ScanResult result) {
    final id = CollarIdentityStore.deviceKey(result.device.remoteId.str);
    final mac = formatBleHardwareAddress(id);
    return isValidBleHardwareAddress(mac) ? mac : _hardwareAddresses[id];
  }

  Future<void> registerDevice(
    ScanResult result, {
    String? hardwareAddress,
  }) async {
    if (_disposed || _registerInFlight || _monitor.hasActiveSession) return;
    if (hardwareAddress != null) {
      final error = CollarIdentityStore.validate(
        hardwareAddress,
        advertisedName: ContactTracingBle.deviceLabel(result),
      );
      if (error != null) throw ArgumentError(error);
      final mac = formatBleHardwareAddress(hardwareAddress);
      await CollarIdentityStore.save(result.device.remoteId.str, mac);
      _hardwareAddresses[CollarIdentityStore.deviceKey(
            result.device.remoteId.str,
          )] =
          mac;
    }
    await _registerStrongest(result);
  }

  List<ScanResult> get discoveryDevicesSorted {
    final list =
        _discoveryDevices.values.where(_acceptScanResult).toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return list;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _settings = await ContactTracingPreferences.loadAll();
    _hardwareAddresses.addAll(await CollarIdentityStore.load());
    _applySettingsToMonitor();
    _monitor.onContactEnded = (contact, {required automatic}) {
      unawaited(_onContactEnded(contact, automatic: automatic));
    };
    _monitor.addListener(_onMonitorChanged);
    await _closeStaleActiveContactsOnServer();
    await _restoreActiveContactFromServer();
    await _applyBackgroundState();
    notifyListeners();
  }

  Future<void> _persist(ContactTracingSettings settings) async {
    _settings = settings;
    await ContactTracingPreferences.save(_settings);
    _applySettingsToMonitor();
    notifyListeners();
  }

  void _applySettingsToMonitor() {
    _monitor.applySettings(
      activeScanIntervalSeconds: _settings.activeScanIntervalSeconds,
      signalLossSeconds: _settings.signalLossSeconds,
    );
  }

  bool _isMacBlockedFromReconnect(String mac) {
    final until = _manualEndBlockUntil[mac];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _manualEndBlockUntil.remove(mac);
      return false;
    }
    return true;
  }

  bool _shouldSuppressContactStarted(Contact contact) {
    final mac = _macFromContact(contact);
    if (mac == null) return false;
    if (_isMacBlockedFromReconnect(mac)) return true;
    final until = _suppressContactStartedForMac[mac];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _suppressContactStartedForMac.remove(mac);
      return false;
    }
    return true;
  }

  String? _macFromContact(Contact contact) {
    final raw = contact.contactHardwareAddress;
    if (raw == null || raw.isEmpty) return null;
    return formatBleHardwareAddress(raw);
  }

  void _blockMacAfterManualEnd(String mac) {
    final blockUntil = DateTime.now().add(
      Duration(seconds: _settings.signalLossSeconds),
    );
    _manualEndBlockUntil[mac] = blockUntil;
    _suppressContactStartedForMac[mac] = DateTime.now().add(
      const Duration(seconds: 8),
    );
  }

  Future<void> _safeEndContact(String contactId) async {
    try {
      await _contactApi.endContact(contactId);
    } catch (e) {
      debugPrint('[ContactTracingCoordinator] safe end $contactId: $e');
    }
  }

  Future<void> _cancelInFlightRegistration() async {
    _registrationEpoch++;
    final orphanId = _inFlightContactId;
    _inFlightContactId = null;
    _inFlightRegistrationMac = null;
    _registerInFlight = false;
    if (orphanId != null && orphanId.isNotEmpty) {
      await _safeEndContact(orphanId);
    }
  }

  /// Beëindigt elk actief contact (lokaal + server). Retourneert true als er iets gesloten is.
  Future<bool> endAllActiveContacts() async {
    final endedMac = _monitor.activeContactMac ?? _inFlightRegistrationMac;
    await _cancelInFlightRegistration();
    if (endedMac != null && endedMac.isNotEmpty) {
      _blockMacAfterManualEnd(endedMac);
    }

    await _stopBackgroundLoop();
    var ended = false;

    if (_monitor.hasActiveSession && !_monitor.busyEnding) {
      try {
        await _monitor.endActiveContact(automatic: false);
        ended = true;
      } catch (e) {
        debugPrint('[ContactTracingCoordinator] monitor end: $e');
        // A failed GPS/API request must not hide an active server contact.
        rethrow;
      }
    } else {
      await _monitor.stop(notify: false);
    }

    final stored = await _contactApi.loadActiveSession();
    final storedId = stored.id?.trim();
    if (storedId != null && storedId.isNotEmpty) {
      try {
        await _contactApi.endContact(storedId);
        ended = true;
      } catch (e) {
        debugPrint('[ContactTracingCoordinator] prefs end $storedId: $e');
      }
    }

    try {
      final contacts = await _contactApi.getMyContacts();
      for (final c in contacts) {
        if (!c.isActive) continue;
        try {
          await _contactApi.endContact(c.id);
          ended = true;
        } catch (e) {
          debugPrint('[ContactTracingCoordinator] server end ${c.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('[ContactTracingCoordinator] list contacts: $e');
    }

    _statusMessage = ended ? 'Contact beëindigd' : 'Geen actief contact';
    notifyListeners();
    if (_settings.backgroundEnabled && !_monitor.hasActiveSession) {
      await _scheduleBackgroundLoop();
    }
    return ended;
  }

  /// Zet achtergrondscan aan/uit. Bij uitzetten wordt elk actief contact beëindigd.
  /// Retourneert `true` als bij uitzetten een contact is gesloten.
  Future<bool> setBackgroundEnabled(bool enabled) async {
    var contactEnded = false;
    // Disable before ending: closing the contact must not start another scan.
    await _persist(_settings.copyWith(backgroundEnabled: enabled));
    if (!enabled) {
      contactEnded = await endAllActiveContacts();
      _statusMessage =
          contactEnded ? 'Bluetooth uit — contact beëindigd' : 'Bluetooth uit';
    }
    await _applyBackgroundState();
    return contactEnded;
  }

  Future<void> setBackgroundIntervalSeconds(int seconds) async {
    final clamped = seconds.clamp(
      ContactTracingPreferences.minBackgroundIntervalSeconds,
      ContactTracingPreferences.maxBackgroundIntervalSeconds,
    );
    await _persist(_settings.copyWith(backgroundIntervalSeconds: clamped));
    if (_settings.backgroundEnabled && !_monitor.hasActiveSession) {
      await _scheduleBackgroundLoop();
    }
  }

  Future<void> setActiveScanIntervalSeconds(int seconds) async {
    final clamped = seconds.clamp(
      ContactTracingPreferences.minActiveScanIntervalSeconds,
      ContactTracingPreferences.maxActiveScanIntervalSeconds,
    );
    await _persist(_settings.copyWith(activeScanIntervalSeconds: clamped));
  }

  Future<void> setSignalLossSeconds(int seconds) async {
    final clamped = seconds.clamp(
      ContactTracingPreferences.minSignalLossSeconds,
      ContactTracingPreferences.maxSignalLossSeconds,
    );
    await _persist(_settings.copyWith(signalLossSeconds: clamped));
  }

  Future<void> setNotifyOnAnimalFound(bool value) async {
    await _persist(_settings.copyWith(notifyOnAnimalFound: value));
  }

  Future<void> setOnlySmartParks(bool value) async {
    await _persist(_settings.copyWith(onlySmartParks: value));
    notifyListeners();
  }

  Future<void> triggerBackgroundScanNow({bool force = false}) async {
    if (_monitor.hasActiveSession) return;
    if (!force && !_settings.backgroundEnabled) return;
    await _runBackgroundDiscoveryScan();
  }

  bool _acceptScanResult(ScanResult result) {
    if (_settings.onlySmartParks) {
      return ContactTracingBle.isSmartParksAdvertisement(result);
    }
    return true;
  }

  bool _isStaleServerContact(Contact c) {
    if (!c.isActive) return false;
    return DateTime.now().difference(c.start) > staleActiveContactMaxAge;
  }

  Future<void> _closeStaleActiveContactsOnServer() async {
    try {
      final contacts = await _contactApi.getMyContacts();
      for (final c in contacts) {
        if (!_isStaleServerContact(c)) continue;
        try {
          await _contactApi.endContact(c.id);
          debugPrint(
            '[ContactTracingCoordinator] Closed stale contact ${c.id} '
            '(started ${c.start})',
          );
        } catch (e) {
          debugPrint(
            '[ContactTracingCoordinator] Stale end failed ${c.id}: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('[ContactTracingCoordinator] stale sweep failed: $e');
    }
  }

  Future<void> _restoreActiveContactFromServer() async {
    if (_monitor.hasActiveSession) return;
    try {
      final contacts = await _contactApi.getMyContacts();
      for (final c in contacts) {
        if (!c.isActive) continue;
        if (_isStaleServerContact(c)) continue;
        final mac = c.contactHardwareAddress;
        if (mac == null || mac.isEmpty) continue;
        final deviceId =
            _hardwareAddresses.entries
                .where((entry) => entry.value == formatBleHardwareAddress(mac))
                .map((entry) => entry.key)
                .firstOrNull;
        if ((defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS) &&
            deviceId == null) {
          // An existing server contact does not reveal Apple's peripheral UUID.
          // Discover/pair it first; registration then resumes it on HTTP 409.
          continue;
        }
        await _monitor.start(
          contactId: c.id,
          mac: formatBleHardwareAddress(mac),
          contact: c,
          deviceId: deviceId,
        );
        _statusMessage = 'Actief contact: ${_monitor.activeAnimalLabel ?? mac}';
        return;
      }
    } catch (e) {
      debugPrint('[ContactTracingCoordinator] restore failed: $e');
    }
  }

  void _onMonitorChanged() {
    if (_disposed) return;
    if (_monitor.hasActiveSession) {
      _stopBackgroundLoop();
      _statusMessage =
          _monitor.activeAnimalLabel != null
              ? 'Contact: ${_monitor.activeAnimalLabel}'
              : 'Contact actief';
    } else if (_settings.backgroundEnabled) {
      _statusMessage =
          'Achtergrondscan elke ${_settings.backgroundIntervalSeconds} s';
      unawaited(_scheduleBackgroundLoop());
    } else {
      _stopBackgroundLoop();
      _statusMessage = 'Uit';
    }
    notifyListeners();
  }

  Future<void> _applyBackgroundState() async {
    if (_settings.backgroundEnabled && !_monitor.hasActiveSession) {
      _statusMessage =
          'Achtergrondscan elke ${_settings.backgroundIntervalSeconds} s';
      await _scheduleBackgroundLoop();
    } else if (!_monitor.hasActiveSession) {
      await _stopBackgroundLoop();
      _statusMessage = 'Uit';
    }
    notifyListeners();
  }

  Future<void> _scheduleBackgroundLoop({bool scanNow = true}) async {
    _backgroundTimer?.cancel();
    if (_disposed ||
        !_settings.backgroundEnabled ||
        _monitor.hasActiveSession) {
      return;
    }

    if (scanNow) unawaited(_runBackgroundDiscoveryScan());

    _backgroundTimer = Timer.periodic(
      Duration(seconds: _settings.backgroundIntervalSeconds),
      (_) {
        if (!_settings.backgroundEnabled ||
            _monitor.hasActiveSession ||
            _registerInFlight) {
          return;
        }
        unawaited(_runBackgroundDiscoveryScan());
      },
    );
  }

  Future<void> _stopBackgroundLoop() async {
    _scanEpoch++;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    await _discoveryScanSub?.cancel();
    _discoveryScanSub = null;
    if (!_monitor.hasActiveSession && _backgroundScanning) {
      await FlutterBluePlus.stopScan();
    }
    _backgroundScanning = false;
    // Keep the last results available for a manual retry if registration fails.
  }

  Future<bool> _ensureBleReady() async {
    final error = await BlePermissions.ensureReady();
    _needsBluetoothPermission = BlePermissions.isPermissionError(error);
    if (error != null) {
      _statusMessage = error;
      notifyListeners();
      return false;
    }
    return true;
  }

  String _emptyScanStatusMessage() {
    if (_discoveryDevices.isNotEmpty) {
      return 'Tracker gevonden. Koppel de tracker hieronder om contact te starten.';
    }
    if (_discoveryDevicesRaw.isNotEmpty && _settings.onlySmartParks) {
      return '${_discoveryDevicesRaw.length} BLE-apparaat(en), geen Smart Parks collar — '
          'volgende scan over ${_settings.backgroundIntervalSeconds} s';
    }
    return 'Geen collar — volgende scan over ${_settings.backgroundIntervalSeconds} s';
  }

  Future<void> _runBackgroundDiscoveryScan() async {
    if (_disposed ||
        _scanInFlight ||
        _registerInFlight ||
        _monitor.hasActiveSession) {
      return;
    }
    if (!_settings.backgroundEnabled) return;
    final epoch = _scanEpoch;
    _scanInFlight = true;
    _backgroundScanning = true;
    _statusMessage = 'Bluetooth controleren…';
    _discoveryDevices.clear();
    _discoveryDevicesRaw.clear();
    notifyListeners();

    try {
      if (!await _ensureBleReady()) return;
      if (_disposed || epoch != _scanEpoch || !_settings.backgroundEnabled) {
        return;
      }
      _statusMessage = 'Scannen naar collars…';
      final startedAt = DateTime.now();
      Object? scanError;
      await _discoveryScanSub?.cancel();
      _discoveryScanSub = FlutterBluePlus.scanResults.listen(
        (results) {
          if (_disposed || epoch != _scanEpoch) return;
          for (final result in results) {
            if (result.timeStamp.isBefore(startedAt)) continue;
            _discoveryDevicesRaw[result.device.remoteId.str] = result;
            if (_acceptScanResult(result)) {
              _discoveryDevices[result.device.remoteId.str] = result;
            }
          }
          notifyListeners();
        },
        onError: (Object error) {
          scanError = error;
        },
      );
      await FlutterBluePlus.startScan(
        timeout: ContactTracingMonitor.scanDuration,
        continuousUpdates: true,
        androidUsesFineLocation: true,
      );
      // startScan completes when scanning STARTS, not after its timeout.
      // Keep the button busy and collect results for the full scan window.
      await FlutterBluePlus.isScanning
          .where((scanning) => !scanning)
          .first
          .timeout(
            ContactTracingMonitor.scanDuration + const Duration(seconds: 2),
          );
      if (_disposed || epoch != _scanEpoch || !_settings.backgroundEnabled) {
        return;
      }
      if (scanError != null) throw scanError!;
      _backgroundScanning = false;
      _statusMessage = _emptyScanStatusMessage();
      notifyListeners();
      for (final result in discoveryDevicesSorted) {
        final mac = hardwareAddressFor(result);
        if (mac == null || _isMacBlockedFromReconnect(mac)) continue;
        await _registerStrongest(result);
        break;
      }
    } catch (e, st) {
      debugPrint('[ContactTracingCoordinator] scan error: $e\n$st');
      if (!_disposed && epoch == _scanEpoch) {
        _statusMessage =
            'Scannen mislukt. Controleer Bluetooth en probeer opnieuw.';
      }
    } finally {
      _scanInFlight = false;
      if (epoch == _scanEpoch) _backgroundScanning = false;
      notifyListeners();
    }
  }

  Future<void> _registerStrongest(ScanResult result) async {
    if (_disposed ||
        !_settings.backgroundEnabled ||
        _registerInFlight ||
        _monitor.hasActiveSession) {
      return;
    }

    final mac = hardwareAddressFor(result);
    if (mac == null) {
      _statusMessage =
          'Tracker gevonden. Koppel de tracker hieronder om contact te starten.';
      notifyListeners();
      return;
    }
    if (_isMacBlockedFromReconnect(mac)) return;

    final epoch = _registrationEpoch;
    _registerInFlight = true;
    _inFlightRegistrationMac = mac;
    _statusMessage = 'Collar gevonden — contact registreren…';
    notifyListeners();

    await _stopBackgroundLoop();

    try {
      Contact contact;
      try {
        contact = await _contactApi.startContact(mac);
      } on ContactRequestException catch (error) {
        if (error.statusCode != 409) rethrow;
        final active =
            (await _contactApi.getMyContacts())
                .where(
                  (candidate) =>
                      candidate.isActive &&
                      formatBleHardwareAddress(
                            candidate.contactHardwareAddress ?? '',
                          ) ==
                          mac,
                )
                .firstOrNull;
        if (active == null) rethrow;
        contact = active;
      }
      if (epoch != _registrationEpoch) {
        await _safeEndContact(contact.id);
        return;
      }

      _inFlightContactId = contact.id;
      if (epoch != _registrationEpoch) {
        await _safeEndContact(contact.id);
        return;
      }

      if (_shouldSuppressContactStarted(contact)) {
        await _safeEndContact(contact.id);
        _statusMessage = 'Contact beëindigd — even geen herverbinding';
        if (_settings.backgroundEnabled) {
          await _scheduleBackgroundLoop();
        }
        return;
      }

      await _monitor.start(
        contactId: contact.id,
        mac: mac,
        contact: contact,
        deviceId: result.device.remoteId.str,
      );
      if (epoch != _registrationEpoch) {
        if (_monitor.hasActiveSession) {
          final rollbackId = _monitor.activeContactId;
          await _monitor.stop(notify: false);
          if (rollbackId != null) {
            await _safeEndContact(rollbackId);
          }
        }
        return;
      }

      _inFlightContactId = null;
      _statusMessage = 'Contact met ${contact.animalDisplayLabel}';
      await _onContactStarted(contact);
    } catch (e) {
      _statusMessage = 'Registreren mislukt: $e';
      debugPrint('[ContactTracingCoordinator] register failed: $e');
      if (_settings.backgroundEnabled) {
        await _scheduleBackgroundLoop(scanNow: false);
      }
    } finally {
      if (epoch == _registrationEpoch) {
        _registerInFlight = false;
        _inFlightContactId = null;
        _inFlightRegistrationMac = null;
      }
      notifyListeners();
    }
  }

  Future<void> _onContactStarted(Contact contact) async {
    if (_shouldSuppressContactStarted(contact)) {
      await _safeEndContact(contact.id);
      if (_monitor.hasActiveSession) {
        await _monitor.stop(notify: false);
      }
      if (_settings.backgroundEnabled) {
        await _scheduleBackgroundLoop();
      }
      return;
    }
    try {
      await _notifyContactStarted(contact);
    } catch (error) {
      debugPrint(
        '[ContactTracingCoordinator] Contact notification unavailable: $error',
      );
    }
    _showContactStartedSheet(contact);
  }

  Future<void> _onContactEnded(
    Contact contact, {
    required bool automatic,
  }) async {
    try {
      await _notifyContactEnded(contact, automatic: automatic);
    } catch (error) {
      debugPrint(
        '[ContactTracingCoordinator] End notification unavailable: $error',
      );
    }
  }

  Future<void> _notifyContactEnded(
    Contact contact, {
    required bool automatic,
  }) async {
    if (!_settings.notifyOnAnimalFound) return;

    final label = contact.animalDisplayLabel;
    final body =
        automatic
            ? 'Signaal weg — contact met $label beëindigd.'
            : 'Contact met $label beëindigd.';

    await NotificationService.instance.show(
      title: 'Contact beëindigd',
      body: body,
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  Future<void> _notifyContactStarted(Contact contact) async {
    if (!_settings.notifyOnAnimalFound) return;
    if (_shouldSuppressContactStarted(contact)) return;

    final messages =
        contact.conveyances
            .map((c) => c.displayText)
            .where((t) => t.isNotEmpty)
            .toList();

    if (messages.isNotEmpty) {
      await NotificationService.instance.show(
        title: 'Contact: ${contact.animalDisplayLabel}',
        body: messages.join('\n\n'),
        importance: Importance.high,
        priority: Priority.high,
      );
      return;
    }

    await NotificationService.instance.show(
      title: 'Dier in de buurt',
      body: '${contact.animalDisplayLabel} gedetecteerd via Bluetooth.',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  void _showContactStartedSheet(Contact contact) {
    if (_shouldSuppressContactStarted(contact)) return;
    final ctx = _navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    unawaited(ContactStartedSheet.show(ctx, contact));
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _monitor.removeListener(_onMonitorChanged);
    unawaited(_stopBackgroundLoop());
    super.dispose();
  }
}
