import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/managers/api_managers/interaction_manager.dart';
import 'package:wildgids/models/beta_models/interaction_model.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/enums/interaction_type.dart';
import '../mock_generator.mocks.dart';
import '../helpers/interaction_helpers.dart';

// Wait for an observable result, not an arbitrary delay after a stream event.
Future<void> waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 1000; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('The expected queue operation did not complete');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InteractionManager manager;
  late MockInteractionApiInterface api;
  late MockConnectivity connectivity;
  late MockReportable report;
  late StreamController<List<ConnectivityResult>> changes;
  late SharedPreferences prefs;
  late Map<String, dynamic> payload;

  setUp(() async {
    await InteractionHelpers.setupEnvironment();
    prefs = await SharedPreferences.getInstance();
    api = InteractionHelpers.getMockInteractionApi();
    connectivity = MockConnectivity();
    report = MockReportable();
    payload = {
      'location': {'latitude': 51.4416, 'longitude': 5.4697},
      'place': {'latitude': 51.4416, 'longitude': 5.4697},
      'moment': '2026-11-08T12:00:00Z',
      'speciesID': 'beaver',
      'typeID': 1,
      'notes': 'Aantal: onbekend. Bij de beek.',
      'reportOfSighting': {'involvedAnimals': <dynamic>[]},
    };
    when(report.toJson()).thenReturn(payload);
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(connectivity.onConnectivityChanged).thenAnswer((_) => changes.stream);
    InteractionHelpers.setupOnlineConnectivity(connectivity);
    manager = InteractionManager(
      interactionAPI: api,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    manager.dispose();
    await changes.close();
  });

  List<String> queue() => prefs.getStringList('interaction_cache') ?? [];
  Future<void> cacheOffline() async {
    when(api.sendInteraction(any)).thenThrow(const SocketException('offline'));
    expect(
      await manager.postInteraction(report, InteractionType.waarneming),
      isNull,
    );
    expect(queue(), hasLength(1));
  }

  group('InteractionManager', () {
    test(
      'posts successfully even when connectivity hints say offline',
      () async {
        InteractionHelpers.setupOfflineConnectivity(connectivity);
        InteractionHelpers.setupSuccessfulInteractionResponse(api);
        final result = await manager.postInteraction(
          report,
          InteractionType.waarneming,
        );
        expect(result!.interactionID, 'int-123');
        expect(queue(), isEmpty);
        final sent =
            verify(api.sendInteraction(captureAny)).captured.single
                as Interaction;
        expect(sent.userID, 'test-user-123');
        expect(sent.interactionType, InteractionType.waarneming);
        expect(sent.report.toJson(), payload);
      },
    );

    test('does not post without a logged-in user', () async {
      await prefs.remove('userID');
      await expectLater(
        manager.postInteraction(report, InteractionType.waarneming),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains("User Profile Wasn't Loaded"),
          ),
        ),
      );
      verifyNever(api.sendInteraction(any));
      expect(queue(), isEmpty);
    });

    test('caches a transport failure without changing the report', () async {
      await cacheOffline();
      final cached = Interaction.fromJson(jsonDecode(queue().single));
      expect(cached.userID, 'test-user-123');
      expect(cached.interactionType, InteractionType.waarneming);
      expect(cached.report.toJson(), payload);
      verify(api.sendInteraction(any)).called(1);
    });

    test('also caches HTTP client connection failures', () async {
      when(
        api.sendInteraction(any),
      ).thenThrow(http.ClientException('connection lost'));
      expect(
        await manager.postInteraction(report, InteractionType.waarneming),
        isNull,
      );
      expect(
        Interaction.fromJson(jsonDecode(queue().single)).report.toJson(),
        payload,
      );
    });

    test('does not treat an API rejection as an offline success', () async {
      InteractionHelpers.setupFailedInteractionResponse(api);
      await expectLater(
        manager.postInteraction(report, InteractionType.waarneming),
        throwsException,
      );
      expect(queue(), isEmpty);
    });

    test(
      'reconnection retries the saved payload and removes it after success',
      () async {
        await cacheOffline();
        clearInteractions(api);
        InteractionHelpers.setupSuccessfulInteractionResponse(api);
        manager.init();
        changes.add([ConnectivityResult.wifi]);
        await waitUntil(() => queue().isEmpty);
        final sent =
            verify(api.sendInteraction(captureAny)).captured.single
                as Interaction;
        expect(sent.userID, 'test-user-123');
        expect(sent.report.toJson(), payload);
      },
    );

    test(
      'failed retry retains the report and a later reconnect sends it',
      () async {
        await cacheOffline();
        final saved = queue().single;
        var attempts = 0;
        when(api.sendInteraction(any)).thenAnswer((_) async {
          attempts++;
          throw const SocketException('still offline');
        });
        manager.init();
        changes.add([ConnectivityResult.wifi]);
        await waitUntil(() => attempts == 1);
        // Drain the failed request handler before triggering the next event.
        await Future<void>.delayed(Duration.zero);
        expect(queue(), [saved]);
        InteractionHelpers.setupSuccessfulInteractionResponse(api);
        changes.add([ConnectivityResult.mobile]);
        await waitUntil(() => queue().isEmpty);
      },
    );

    test('another account cannot send or remove the saved report', () async {
      await cacheOffline();
      final saved = queue().single;
      clearInteractions(api);
      await prefs.setString('userID', 'different-user');
      manager.init();
      changes.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(queue(), [saved]);
      verifyNever(api.sendInteraction(any));
      await prefs.setString('userID', 'test-user-123');
      InteractionHelpers.setupSuccessfulInteractionResponse(api);
      changes.add([ConnectivityResult.wifi]);
      await waitUntil(() => queue().isEmpty);
      verify(api.sendInteraction(any)).called(1);
    });

    test(
      'none connectivity does not retry and disposal cancels listening',
      () async {
        await cacheOffline();
        clearInteractions(api);
        manager.init();
        expect(changes.hasListener, isTrue);
        changes.add([ConnectivityResult.none]);
        await Future<void>.delayed(Duration.zero);
        verifyNever(api.sendInteraction(any));
        expect(queue(), hasLength(1));
        manager.dispose();
        expect(changes.hasListener, isFalse);
      },
    );

    test(
      'retrying keeps reports queued while the request is in flight',
      () async {
        await cacheOffline();
        final first = queue().single;
        final second = jsonEncode(
          Interaction(
              interactionType: InteractionType.waarneming,
              userID: 'test-user-123',
              report: report,
            ).toJson()
            ..['report'] = {...payload, 'notes': 'A second encounter'},
        );
        final response = Completer<InteractionResponse>();
        var started = false;
        when(api.sendInteraction(any)).thenAnswer((_) async {
          started = true;
          return await response.future;
        });
        manager.init();
        changes.add([ConnectivityResult.wifi]);
        await waitUntil(() => started);
        await prefs.setStringList('interaction_cache', [first, second]);
        response.complete(InteractionHelpers.createMockInteractionResponse());
        await waitUntil(() => queue().length == 1);
        expect(queue(), [second]);
      },
    );
  });
}
