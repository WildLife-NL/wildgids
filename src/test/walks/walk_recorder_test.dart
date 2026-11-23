import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/models/walk_recording.dart';
import 'package:wildgids/providers/walk_recorder.dart';
import 'package:wildgids/services/live_location_service.dart';
import 'package:wildgids/services/walk_store.dart';

class MemoryWalkStore implements WalkStore {
  final Map<String, WalkArchive> archives = {};
  bool fail = false;
  bool corrupt = false;
  @override
  Future<WalkArchive> load(String owner) async {
    if (corrupt) throw const FormatException();
    return archives[owner] ?? const WalkArchive();
  }

  @override
  Future<void> save(String owner, WalkArchive archive) async {
    if (fail) throw const FileSystemException('disk full');
    archives[owner] = WalkArchive.fromJson(
      jsonDecode(jsonEncode(archive.toJson())),
    );
  }
}

Position fix(DateTime time, double lat, double lon, {double accuracy = 5}) =>
    Position(
      latitude: lat,
      longitude: lon,
      timestamp: time,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

Future<void> flush() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late DateTime now;
  late MemoryWalkStore store;
  late StreamController<Position> source;
  late LiveLocationService service;
  late WalkRecorder recorder;
  late List<LocationSettings> settings;

  setUp(() {
    now = DateTime.utc(2026, 10, 24, 12);
    store = MemoryWalkStore();
    source = StreamController.broadcast();
    settings = [];
    service = LiveLocationService(
      source: (value) {
        settings.add(value);
        return source.stream;
      },
    );
    recorder = WalkRecorder(
      store: store,
      locations: service,
      owner: () async => 'user-1',
      authorize: () async {},
      now: () => now,
    );
  });
  tearDown(() async {
    recorder.dispose();
    await flush();
    await source.close();
  });

  test(
    'idle recorder never starts GPS; start is explicit and idempotent',
    () async {
      await recorder.initialize();
      expect(settings, isEmpty);
      await recorder.start();
      await recorder.start();
      await flush();
      expect(settings, hasLength(1));
      expect(recorder.recording, isTrue);
      expect(store.archives['user-1']!.draft, isNotNull);
    },
  );

  test(
    'records turns, filters jitter, inaccurate, stale, duplicate and jump fixes',
    () async {
      await recorder.start();
      await flush();
      source.add(fix(now, 52, 4));
      await flush();
      now = now.add(const Duration(seconds: 10));
      source.add(fix(now, 52.0001, 4));
      await flush();
      now = now.add(const Duration(seconds: 10));
      source.add(fix(now, 52.0001, 4.0002));
      await flush();
      source.add(fix(now, 52.0001, 4.0002));
      source.add(fix(now.subtract(const Duration(minutes: 5)), 53, 5));
      now = now.add(const Duration(seconds: 1));
      source.add(fix(now, 52.000101, 4.000201));
      await flush();
      now = now.add(const Duration(seconds: 1));
      source.add(fix(now, 53, 5));
      await flush();
      source.add(fix(now, 52.0003, 4.0004, accuracy: 100));
      source.add(fix(now, double.nan, 4));
      await flush();
      expect(recorder.current!.points, hasLength(3));
      expect(recorder.current!.distanceMeters, inInclusiveRange(20, 30));
      expect(store.archives['user-1']!.draft!.points, hasLength(3));
    },
  );

  test(
    'pause excludes time and travel; resume starts a separate segment',
    () async {
      await recorder.start();
      await flush();
      source.add(fix(now, 52, 4));
      await flush();
      now = now.add(const Duration(seconds: 10));
      source.add(fix(now, 52.0001, 4));
      await flush();
      await recorder.pause();
      now = now.add(const Duration(minutes: 10));
      source.add(fix(now, 53, 5));
      await flush();
      expect(recorder.current!.points, hasLength(2));
      expect(recorder.elapsed, const Duration(seconds: 10));
      await recorder.start();
      await flush();
      source.add(fix(now, 53, 5));
      await flush();
      expect(recorder.current!.segments, hasLength(2));
      expect(recorder.current!.distanceMeters, lessThan(15));
    },
  );

  test(
    'GPS outage does not draw a straight line through unrecorded travel',
    () async {
      await recorder.start();
      await flush();
      source.add(fix(now, 52, 4));
      await flush();
      now = now.add(const Duration(minutes: 5));
      source.add(fix(now, 53, 5));
      await flush();
      expect(recorder.current!.segments, hasLength(2));
      expect(recorder.current!.distanceMeters, 0);
    },
  );

  test('permission failure keeps recorder idle', () async {
    final denied = WalkRecorder(
      store: store,
      locations: service,
      owner: () async => 'user-1',
      authorize: () async => throw StateError('Geen locatietoegang'),
    );
    await denied.start();
    expect(denied.recording, isFalse);
    expect(denied.current, isNull);
    expect(denied.error, contains('locatietoegang'));
    expect(settings, isEmpty);
    denied.dispose();
  });

  test('native stream error pauses and retains draft', () async {
    await recorder.start();
    await flush();
    source.add(fix(now, 52, 4));
    await flush();
    source.addError(StateError('permission revoked'));
    await flush();
    expect(recorder.recording, isFalse);
    expect(recorder.current!.points, hasLength(1));
    expect(recorder.error, contains('gepauzeerd'));
  });

  test(
    'failed persistence pauses and keeps unsaved points for retry',
    () async {
      await recorder.start();
      await flush();
      store.fail = true;
      source.add(fix(now, 52, 4));
      await flush();
      expect(recorder.recording, isFalse);
      expect(recorder.current!.points, hasLength(1));
      expect(await recorder.finish(save: true), isFalse);
      expect(recorder.current, isNotNull);
      store.fail = false;
      expect(await recorder.finish(save: true), isTrue);
      expect(recorder.saved.single.points, hasLength(1));
    },
  );

  test(
    'restart recovers draft paused, without silently restarting GPS',
    () async {
      await recorder.start();
      await flush();
      source.add(fix(now, 52, 4));
      await flush();
      await recorder.pause();
      final recovered = WalkRecorder(
        store: store,
        locations: service,
        owner: () async => 'user-1',
      );
      await recovered.initialize();
      expect(recovered.recording, isFalse);
      expect(recovered.current!.points, hasLength(1));
      expect(recovered.error, contains('onderbroken'));
      recovered.dispose();
    },
  );

  test('save, discard, delete and account separation', () async {
    await recorder.start();
    await flush();
    source.add(fix(now, 52, 4));
    await flush();
    await recorder.finish(save: true);
    expect(recorder.current, isNull);
    final id = recorder.saved.single.id;
    now = now.add(const Duration(minutes: 1));
    await recorder.start();
    await recorder.finish(save: false);
    expect(recorder.saved, hasLength(1));
    final other = WalkRecorder(
      store: store,
      locations: service,
      owner: () async => 'user-2',
    );
    await other.initialize();
    expect(other.saved, isEmpty);
    other.dispose();
    await recorder.deleteSaved(id);
    expect(recorder.saved, isEmpty);
    await recorder.closeAccount();
    expect(recorder.ready, isFalse);
  });

  test('corrupted archive is not silently overwritten', () async {
    store.corrupt = true;
    await recorder.start();
    expect(recorder.ready, isFalse);
    expect(recorder.recording, isFalse);
    expect(store.archives, isEmpty);
  });

  test('sighting links once to correct walk without pausing', () async {
    await recorder.start();
    await flush();
    final id = recorder.current!.id;
    final sighting = WalkSighting(
      id: 'report-1',
      name: 'Vos',
      point: WalkPoint(52, 4, now),
    );
    await recorder.addSighting(sighting, walkId: 'other');
    expect(recorder.current!.sightings, isEmpty);
    await recorder.addSighting(sighting, walkId: id);
    await recorder.addSighting(sighting, walkId: id);
    expect(recorder.current!.sightings, hasLength(1));
    expect(recorder.recording, isTrue);
  });

  test(
    'single GPS stream upgrades for a walk and survives map disposal',
    () async {
      final received = <Position>[];
      final map = service.watch().listen(received.add);
      await flush();
      await recorder.start();
      await flush();
      expect(settings, hasLength(2));
      await map.cancel();
      await flush();
      expect(settings, hasLength(2));
      source.add(fix(now, 52, 4));
      await flush();
      expect(recorder.current!.points, hasLength(1));
      final reopenedMap = service.watch().listen(received.add);
      await flush();
      expect(settings, hasLength(2));
      await recorder.pause();
      await flush();
      expect(settings, hasLength(3));
      await reopenedMap.cancel();
    },
  );

  test(
    'iOS uses visible background tracking; Android uses foreground service',
    () {
      final ios =
          LiveLocationService.settings(true, TargetPlatform.iOS)
              as AppleSettings;
      expect(ios.allowBackgroundLocationUpdates, isTrue);
      expect(ios.showBackgroundLocationIndicator, isTrue);
      expect(ios.pauseLocationUpdatesAutomatically, isFalse);
      expect(
        (LiveLocationService.settings(false, TargetPlatform.iOS)
                as AppleSettings)
            .allowBackgroundLocationUpdates,
        isFalse,
      );
      final android =
          LiveLocationService.settings(true, TargetPlatform.android)
              as AndroidSettings;
      expect(android.foregroundNotificationConfig, isNotNull);
      expect(android.foregroundNotificationConfig!.enableWakeLock, isTrue);
      expect(
        (LiveLocationService.settings(false, TargetPlatform.android)
                as AndroidSettings)
            .foregroundNotificationConfig,
        isNull,
      );
    },
  );

  test(
    'local file snapshots round trip and reject malformed coordinates',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'wildgids-walk-test-',
      );
      try {
        final disk = FileWalkStore(directory: () async => directory);
        final walk = WalkRecording(
          id: '1',
          startedAt: now,
          points: [WalkPoint(52, 4, now)],
        );
        await disk.save('test-owner', WalkArchive(draft: walk));
        expect(
          (await disk.load('test-owner')).draft!.points.single.latitude,
          52,
        );
        await disk.save('test-owner', WalkArchive(saved: [walk]));
        expect((await disk.load('test-owner')).draft, isNull);
        expect((await disk.load('test-owner')).saved, hasLength(1));
        expect((await disk.load('different-owner')).saved, isEmpty);
        final invalid = walk.toJson();
        (invalid['points'] as List).first['latitude'] = 100;
        expect(() => WalkRecording.fromJson(invalid), throwsFormatException);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
