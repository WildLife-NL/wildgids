import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/living_labs_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = LivingLabsApi(ApiClient('https://backend.test'));
  final labs = [
    {'ID': 'one', 'name': 'Lab from server', 'definition': null},
  ];
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'bearer_token': 'test-token'}),
  );

  test(
    'uses the configured authenticated endpoint and caches a valid list',
    () async {
      final result = await http.runWithClient(
        api.getAll,
        () => MockClient((request) async {
          expect(request.url.toString(), 'https://backend.test/livinglabs/');
          expect(request.headers['Authorization'], 'Bearer test-token');
          return http.Response(jsonEncode(labs), 200);
        }),
      );
      expect(result.single.name, 'Lab from server');
      expect((await api.readCache()).single.id, 'one');
      expect(
        await LivingLabsApi(ApiClient('https://other.test')).readCache(),
        isEmpty,
      );
    },
  );

  for (final response in [
    http.Response('', 401),
    http.Response('', 503),
    http.Response('broken', 200),
    http.Response('{}', 200),
  ]) {
    test(
      'rejects invalid response ${response.statusCode}/${response.body}',
      () async {
        await expectLater(
          http.runWithClient(
            api.getAll,
            () => MockClient((_) async => response),
          ),
          throwsA(isA<Exception>()),
        );
        expect(await api.readCache(), isEmpty);
      },
    );
  }

  test('rejects corrupt, old and future-dated cached lists', () async {
    for (final value in [
      'broken',
      jsonEncode({
        'fetchedAt':
            DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        'labs': labs,
      }),
      jsonEncode({
        'fetchedAt':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'labs': labs,
      }),
    ]) {
      SharedPreferences.setMockInitialValues({
        'home_backend_labs_v1_https://backend.test': value,
      });
      expect(await api.readCache(), isEmpty);
    }
  });
}
