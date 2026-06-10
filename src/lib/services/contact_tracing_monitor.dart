import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wildgids/data_managers/contact_api.dart';
import 'package:wildgids/utils/ble_permissions.dart';
import 'package:wildgids/models/api_models/contact_model.dart';
import 'package:wildgids/services/contact_tracing_ble.dart';
import 'package:wildgids/utils/ble_mac_format.dart';

typedef ContactEndedCallback = void Function(
  Contact contact, {
  required bool automatic,
});

/// Volgt een actief contact via BLE-advertenties (geen GATT-verbinding).
class ContactTracingMonitor extends ChangeNotifier {
  ContactTracingMonitor(this._contactApi);

  final ContactApi _contactApi;

  ContactEndedCallback? onContactEnded;

  static const Duration presenceCheckInterval = Duration(seconds: 5);
  static const Duration scanDuration = Duration(seconds: 8);

  Duration _signalLossAfter = const Duration(seconds: 30);
  Duration _rescanInterval = const Duration(seconds: 30);

  String? _activeContactId;
  String? _activeContactMac;
  Contact? _activeContact;
  DateTime? _sessionStartedAt;
  DateTime? _lastSeenAt;
  int? _lastAdvertisementRssi;
  bool _isScanning = false;
  bool _busyEnding = false;
  String? _lastAutoEndMessage;
  Contact? _lastEndedContact;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  Timer? _rescanTimer;
  Timer? _presenceTimer;

  bool get hasActiveSession => _activeContactId != null;
  bool get isScanning => _isScanning;
  bool get busyEnding => _busyEnding;
  int get signalLossSeconds => _signalLossAfter.inSeconds;
  int get activeScanIntervalSeconds => _rescanInterval.inSeconds;
  String? get activeContactId => _activeContactId;
  String? get activeContactMac => _activeContactMac;
  Contact? get activeContact => _activeContact;
  Contact? get lastEndedContact => _lastEndedContact;
  DateTime? get lastSeenAt => _lastSeenAt;
  int? get lastAdvertisementRssi => _lastAdvertisementRssi;
  String? get lastAutoEndMessage => _lastAutoEndMessage;

  String? get activeAnimalLabel {
    final c = _activeContact;
    if (c == null) return null;
    final name = c.collarAnimalName;
    final species = c.collarAnimalSpecies;
    if (name != null && species != null) return '$name ($species)';
    return name ?? species;
  }

  Duration? get timeSinceLastSeen {
    if (_lastSeenAt == null) return null;
    return DateTime.now().difference(_lastSeenAt!);
  }

  void applySettings({
    required int activeScanIntervalSeconds,
    required int signalLossSeconds,
  }) {
    _rescanInterval = Duration(seconds: activeScanIntervalSeconds);
    _signalLossAfter = Duration(seconds: signalLossSeconds);
    if (_activeContactId != null) {
      _restartActiveTimers();
    }
    notifyListeners();
  }

  void _restartActiveTimers() {
    _rescanTimer?.cancel();
    _presenceTimer?.cancel();
    _rescanTimer = Timer.periodic(_rescanInterval, (_) {
      unawaited(_runScan());
    });
    _presenceTimer = Timer.periodic(presenceCheckInterval, (_) {
      unawaited(_checkSignalLoss());
    });
  }

  Future<void> start({
    required String contactId,
    required String mac,
    required Contact contact,
  }) async {
    final formattedMac = formatBleHardwareAddress(mac);
    if (_activeContactId == contactId &&
        _activeContactMac == formattedMac &&
        _rescanTimer != null) {
      return;
    }

    await stop(notify: false);

    _activeContactId = contactId;
    _activeContactMac = formattedMac;
    _activeContact = contact;
    _sessionStartedAt = DateTime.now();
    _lastSeenAt = null;
    _lastAdvertisementRssi = null;
    _lastAutoEndMessage = null;
    _lastEndedContact = null;

    await _ensureScanPipeline();
    _restartActiveTimers();

    unawaited(_runScan());
    notifyListeners();
  }

  Future<Contact?> endActiveContact({bool automatic = false}) async {
    final id = _activeContactId;
    if (id == null || _busyEnding) return null;

    _busyEnding = true;
    notifyListeners();

    Contact? result;
    try {
      await FlutterBluePlus.stopScan();
      result = await _contactApi.endContact(id);
      _lastEndedContact = result;
      if (automatic) {
        final label = activeAnimalLabel ?? 'collar';
        _lastAutoEndMessage = 'Signaal weg — contact met $label beëindigd.';
      } else {
        _lastAutoEndMessage = null;
      }
      debugPrint('[ContactTracingMonitor] Ended contact $id');
      onContactEnded?.call(result, automatic: automatic);
    } catch (e) {
      _lastAutoEndMessage = automatic
          ? 'Automatisch beëindigen mislukt: $e'
          : null;
      rethrow;
    } finally {
      _busyEnding = false;
      await stop();
    }
    return result;
  }

  Future<void> stop({bool notify = true}) async {
    _rescanTimer?.cancel();
    _rescanTimer = null;
    _presenceTimer?.cancel();
    _presenceTimer = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await _isScanningSubscription?.cancel();
    _isScanningSubscription = null;
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
    }
    _isScanning = false;
    _activeContactId = null;
    _activeContactMac = null;
    _activeContact = null;
    _sessionStartedAt = null;
    _lastSeenAt = null;
    _lastAdvertisementRssi = null;
    if (notify) notifyListeners();
  }

  Future<void> _ensureScanPipeline() async {
    await _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen(_onScanResults);

    await _isScanningSubscription?.cancel();
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      if (_isScanning == scanning) return;
      _isScanning = scanning;
      notifyListeners();
    });
  }

  void _onScanResults(List<ScanResult> results) {
    final targetMac = _activeContactMac;
    if (targetMac == null) return;

    for (final result in results) {
      if (!ContactTracingBle.isSmartParksAdvertisement(result)) continue;
      final mac = formatBleHardwareAddress(result.device.remoteId.str);
      if (mac != targetMac) continue;
      _markSeen(result.rssi);
      return;
    }
  }

  void _markSeen(int rssi) {
    _lastSeenAt = DateTime.now();
    _lastAdvertisementRssi = rssi;
    notifyListeners();
  }

  Future<bool> _ensureBleReady() async {
    return (await BlePermissions.ensureReady()) == null;
  }

  Future<void> _runScan() async {
    if (_activeContactId == null || _busyEnding) return;
    if (_isScanning) return;
    if (!await _ensureBleReady()) return;

    try {
      await FlutterBluePlus.startScan(
        timeout: scanDuration,
        androidUsesFineLocation: true,
      );
    } catch (e, st) {
      debugPrint('[ContactTracingMonitor] scan failed: $e\n$st');
    }
  }

  Future<void> _checkSignalLoss() async {
    if (_activeContactId == null || _busyEnding) return;
    final started = _sessionStartedAt;
    if (started == null) return;

    final last = _lastSeenAt;
    if (last == null) {
      // Geen enkele BLE-advertentie gezien — na grace toch beëindigen (anders blijft
      // het contact op de server actief, bv. na herstart zonder collar in bereik).
      if (DateTime.now().difference(started) <= _signalLossAfter) return;
      await endActiveContact(automatic: true);
      return;
    }

    if (DateTime.now().difference(last) <= _signalLossAfter) return;
    await endActiveContact(automatic: true);
  }

  void clearAutoEndMessage() {
    _lastAutoEndMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(stop(notify: false));
    super.dispose();
  }
}

