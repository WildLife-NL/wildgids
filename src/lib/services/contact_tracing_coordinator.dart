import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wildgids/data_managers/contact_api.dart';
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
  })  : _contactApi = contactApi,
        _monitor = monitor,
        _navigatorKey = navigatorKey;

  final ContactApi _contactApi;
  final ContactTracingMonitor _monitor;
  final GlobalKey<NavigatorState>? _navigatorKey;

  bool _initialized = false;
  late ContactTracingSettings _settings;
  bool _backgroundScanning = false;
  bool _registerInFlight = false;
  String _statusMessage = 'Uit';

  final Map<String, ScanResult> _discoveryDevices = {};
  final Map<String, ScanResult> _discoveryDevicesRaw = {};
  Timer? _backgroundTimer;
  StreamSubscription<List<ScanResult>>? _discoveryScanSub;
  StreamSubscription<bool>? _discoveryScanningSub;

  bool get backgroundEnabled => _settings.backgroundEnabled;
  int get backgroundIntervalSeconds => _settings.backgroundIntervalSeconds;
  int get activeScanIntervalSeconds => _settings.activeScanIntervalSeconds;
  int get signalLossSeconds => _settings.signalLossSeconds;
  bool get notifyOnAnimalFound => _settings.notifyOnAnimalFound;
  bool get onlySmartParks => _settings.onlySmartParks;
  bool get backgroundScanning => _backgroundScanning;
  String get statusMessage => _statusMessage;
  ContactTracingMonitor get monitor => _monitor;

  List<ScanResult> get discoveryDevicesSorted {
    final list = _discoveryDevices.values.where(_acceptScanResult).toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return list;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _settings = await ContactTracingPreferences.loadAll();
    _applySettingsToMonitor();
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

  /// Beëindigt elk actief contact (lokaal + server). Retourneert true als er iets gesloten is.
  Future<bool> endAllActiveContacts() async {
    await _stopBackgroundLoop();
    var ended = false;

    if (_monitor.hasActiveSession && !_monitor.busyEnding) {
      try {
        await _monitor.endActiveContact(automatic: false);
        ended = true;
      } catch (e) {
        debugPrint('[ContactTracingCoordinator] monitor end: $e');
        await _monitor.stop(notify: false);
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
    return ended;
  }

  /// Zet achtergrondscan aan/uit. Bij uitzetten wordt elk actief contact beëindigd.
  /// Retourneert `true` als bij uitzetten een contact is gesloten.
  Future<bool> setBackgroundEnabled(bool enabled) async {
    var contactEnded = false;
    if (!enabled) {
      contactEnded = await endAllActiveContacts();
      _statusMessage = contactEnded
          ? 'Bluetooth uit — contact beëindigd'
          : 'Bluetooth uit';
    }
    await _persist(_settings.copyWith(backgroundEnabled: enabled));
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
        await _monitor.start(
          contactId: c.id,
          mac: formatBleHardwareAddress(mac),
          contact: c,
        );
        _statusMessage = 'Actief contact: ${_monitor.activeAnimalLabel ?? mac}';
        return;
      }
    } catch (e) {
      debugPrint('[ContactTracingCoordinator] restore failed: $e');
    }
  }

  void _onMonitorChanged() {
    if (_monitor.hasActiveSession) {
      _stopBackgroundLoop();
      _statusMessage = _monitor.activeAnimalLabel != null
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

  Future<void> _scheduleBackgroundLoop() async {
    _backgroundTimer?.cancel();
    if (!_settings.backgroundEnabled || _monitor.hasActiveSession) return;

    unawaited(_runBackgroundDiscoveryScan());

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
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    await _discoveryScanSub?.cancel();
    _discoveryScanSub = null;
    await _discoveryScanningSub?.cancel();
    _discoveryScanningSub = null;
    if (!_monitor.hasActiveSession && _backgroundScanning) {
      await FlutterBluePlus.stopScan();
    }
    _backgroundScanning = false;
    _discoveryDevices.clear();
    _discoveryDevicesRaw.clear();
  }

  Future<bool> _ensureBleReady() async {
    final error = await BlePermissions.ensureReady();
    if (error != null) {
      _statusMessage = error;
      notifyListeners();
      return false;
    }
    return true;
  }

  String _emptyScanStatusMessage() {
    if (_discoveryDevicesRaw.isNotEmpty && _settings.onlySmartParks) {
      return '${_discoveryDevicesRaw.length} BLE-apparaat(en), geen Smart Parks collar — '
          'volgende scan over ${_settings.backgroundIntervalSeconds} s';
    }
    return 'Geen collar — volgende scan over ${_settings.backgroundIntervalSeconds} s';
  }

  Future<void> _runBackgroundDiscoveryScan() async {
    if (_registerInFlight || _monitor.hasActiveSession) return;
    if (!_settings.backgroundEnabled) return;
    if (!await _ensureBleReady()) return;

    _backgroundScanning = true;
    _statusMessage = 'Scannen naar collars…';
    _discoveryDevices.clear();
    _discoveryDevicesRaw.clear();
    notifyListeners();

    await _discoveryScanSub?.cancel();
    _discoveryScanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        _discoveryDevicesRaw[r.device.remoteId.str] = r;
        if (!_acceptScanResult(r)) continue;
        _discoveryDevices[r.device.remoteId.str] = r;
      }
      notifyListeners();
      final strongest = discoveryDevicesSorted;
      if (strongest.isNotEmpty &&
          !_registerInFlight &&
          !_monitor.hasActiveSession) {
        unawaited(_registerStrongest(strongest.first));
      }
    });

    await _discoveryScanningSub?.cancel();
    _discoveryScanningSub = FlutterBluePlus.isScanning.listen((v) {
      _backgroundScanning = v;
      notifyListeners();
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: ContactTracingMonitor.scanDuration,
        androidUsesFineLocation: true,
      );
    } catch (e, st) {
      debugPrint('[ContactTracingCoordinator] scan error: $e\n$st');
      _statusMessage = 'Scan mislukt: $e';
    }

    if (!_monitor.hasActiveSession && _settings.backgroundEnabled) {
      _statusMessage = discoveryDevicesSorted.isEmpty
          ? _emptyScanStatusMessage()
          : '${discoveryDevicesSorted.length} collar(s) in de buurt';
    }
    _backgroundScanning = false;
    notifyListeners();

    if (!_monitor.hasActiveSession &&
        discoveryDevicesSorted.isNotEmpty &&
        !_registerInFlight) {
      await _registerStrongest(discoveryDevicesSorted.first);
    }
  }

  Future<void> _registerStrongest(ScanResult result) async {
    if (_registerInFlight || _monitor.hasActiveSession) return;

    final mac = formatBleHardwareAddress(result.device.remoteId.str);
    if (!isValidBleHardwareAddress(mac)) return;

    _registerInFlight = true;
    _statusMessage = 'Collar gevonden — contact registreren…';
    notifyListeners();

    await _stopBackgroundLoop();

    try {
      final contact = await _contactApi.startContact(mac);
      await _monitor.start(
        contactId: contact.id,
        mac: mac,
        contact: contact,
      );

      _statusMessage = 'Contact met ${contact.animalDisplayLabel}';
      await _onContactStarted(contact);
    } catch (e) {
      _statusMessage = 'Registreren mislukt: $e';
      debugPrint('[ContactTracingCoordinator] register failed: $e');
      if (_settings.backgroundEnabled) {
        await _scheduleBackgroundLoop();
      }
    } finally {
      _registerInFlight = false;
      notifyListeners();
    }
  }

  Future<void> _onContactStarted(Contact contact) async {
    await _notifyContactStarted(contact);
    _showContactStartedSheet(contact);
  }

  Future<void> _notifyContactStarted(Contact contact) async {
    if (!_settings.notifyOnAnimalFound) return;

    final messages = contact.conveyances
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
    final ctx = _navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    unawaited(ContactStartedSheet.show(ctx, contact));
  }

  @override
  void dispose() {
    _monitor.removeListener(_onMonitorChanged);
    unawaited(_stopBackgroundLoop());
    super.dispose();
  }
}

