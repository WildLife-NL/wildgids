import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/contact_api.dart';

Position position(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class RecordingContactClient extends ApiClient {
  RecordingContactClient() : super('https://example.test/');
  final requests =
      <
        ({
          String method,
          String path,
          Map<String, dynamic> body,
          bool authenticated,
        })
      >[];
  int statusCode = 200;
  String? responseBody;

  Future<http.Response> _respond(
    String method,
    String path,
    Map<String, dynamic> body,
    bool authenticated,
  ) async {
    requests.add((
      method: method,
      path: path,
      body: body,
      authenticated: authenticated,
    ));
    return http.Response(
      responseBody ??
          jsonEncode({
            'ID': 'contact-1',
            'start': '2026-11-18T10:00:00Z',
            if (method == 'PUT') 'end': '2026-11-18T10:05:00Z',
          }),
      statusCode,
    );
  }

  @override
  Future<http.Response> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _respond('POST', url, body, authenticated);

  @override
  Future<http.Response> put(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) => _respond('PUT', url, body, authenticated);
}

class ContactGeolocator extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  Position result = position(52.38, 4.63);
  Object? error;
  int positionRequests = 0;
  int lastKnownRequests = 0;
  int permissionRequests = 0;
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    lastKnownRequests++;
    return position(0, 0);
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    settings = locationSettings;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RecordingContactClient client;
  late ContactGeolocator gps;
  late GeolocatorPlatform originalGps;
  late ContactApi api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = RecordingContactClient();
    originalGps = GeolocatorPlatform.instance;
    gps = ContactGeolocator();
    GeolocatorPlatform.instance = gps;
    api = ContactApi(client);
  });

  tearDown(() {
    GeolocatorPlatform.instance = originalGps;
  });

  test(
    'start includes the current GPS position and saves the active contact',
    () async {
      final contact = await api.startContact('AA:BB:CC:DD:EE:FF');
      final request = client.requests.single;
      expect(request.method, 'POST');
      expect(request.path, 'contact/');
      expect(request.authenticated, isTrue);
      expect(request.body, {
        'contactHardwareAddress': 'AA:BB:CC:DD:EE:FF',
        'location': {'latitude': 52.38, 'longitude': 4.63},
      });
      expect(contact.id, 'contact-1');
      expect(await api.loadActiveSession(), (
        id: 'contact-1',
        mac: 'AA:BB:CC:DD:EE:FF',
      ));
      expect(gps.settings?.accuracy, LocationAccuracy.high);
      expect(gps.settings?.timeLimit, ContactApi.locationTimeout);
      expect(gps.lastKnownRequests, 0);
    },
  );

  test(
    'end reads GPS again rather than reusing the starting coordinates',
    () async {
      await api.startContact('AA:BB:CC:DD:EE:FF');
      gps.result = position(52.39, 4.65);
      final ended = await api.endContact(' contact-1 ');
      final request = client.requests.last;
      expect(request.method, 'PUT');
      expect(request.path, 'contact/');
      expect(request.authenticated, isTrue);
      expect(request.body, {
        'contactID': 'contact-1',
        'location': {'latitude': 52.39, 'longitude': 4.65},
      });
      expect(ended.isActive, isFalse);
      expect(gps.positionRequests, 2);
      expect(gps.lastKnownRequests, 0);
      expect(await api.loadActiveSession(), (id: null, mac: null));
    },
  );

  test(
    'a restored contact can end with current GPS without having started in this app session',
    () async {
      await api.endContact('restored-contact');
      expect(client.requests.single.body['contactID'], 'restored-contact');
      expect(client.requests.single.body['location'], {
        'latitude': 52.38,
        'longitude': 4.63,
      });
      expect(gps.positionRequests, 1);
    },
  );

  test(
    'an empty contact ID fails before requesting GPS or sending HTTP',
    () async {
      await expectLater(api.endContact('  '), throwsException);
      expect(gps.positionRequests, 0);
      expect(client.requests, isEmpty);
    },
  );

  test('location services disabled prevents a start request', () async {
    gps.serviceEnabled = false;
    await expectLater(api.startContact('AA:BB:CC:DD:EE:FF'), throwsStateError);
    expect(client.requests, isEmpty);
    expect(gps.positionRequests, 0);
    expect(await api.loadActiveSession(), (id: null, mac: null));
  });

  for (final permission in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
    LocationPermission.unableToDetermine,
  ]) {
    test(
      '$permission does not send a request or open an automatic permission prompt',
      () async {
        gps.permission = permission;
        await expectLater(
          api.startContact('AA:BB:CC:DD:EE:FF'),
          throwsStateError,
        );
        expect(client.requests, isEmpty);
        expect(gps.positionRequests, 0);
        expect(gps.permissionRequests, 0);
      },
    );
  }

  test('always permission uses the same current-location request', () async {
    gps.permission = LocationPermission.always;
    await api.startContact('AA:BB:CC:DD:EE:FF');
    expect(gps.positionRequests, 1);
    expect(gps.permissionRequests, 0);
  });

  test(
    'a GPS timeout preserves the active session and the end can be retried',
    () async {
      await api.startContact('AA:BB:CC:DD:EE:FF');
      gps.error = TimeoutException('no fix');
      await expectLater(api.endContact('contact-1'), throwsStateError);
      expect(client.requests, hasLength(1));
      expect(await api.loadActiveSession(), (
        id: 'contact-1',
        mac: 'AA:BB:CC:DD:EE:FF',
      ));
      gps.error = null;
      gps.result = position(52.4, 4.66);
      await api.endContact('contact-1');
      expect(client.requests.last.body['location'], {
        'latitude': 52.4,
        'longitude': 4.66,
      });
      expect(await api.loadActiveSession(), (id: null, mac: null));
    },
  );

  for (final invalid in [
    (double.nan, 4.63),
    (52.38, double.infinity),
    (91.0, 4.63),
    (52.38, -181.0),
  ]) {
    test('invalid GPS coordinates $invalid are not sent', () async {
      gps.result = position(invalid.$1, invalid.$2);
      await expectLater(
        api.startContact('AA:BB:CC:DD:EE:FF'),
        throwsStateError,
      );
      expect(client.requests, isEmpty);
    });
  }

  test(
    'zero coordinates are accepted as a real position, never inserted as a fallback',
    () async {
      gps.result = position(0, 0);
      await api.startContact('AA:BB:CC:DD:EE:FF');
      expect(client.requests.single.body['location'], {
        'latitude': 0.0,
        'longitude': 0.0,
      });
    },
  );

  test('a failed start response does not save a contact locally', () async {
    client.statusCode = 500;
    await expectLater(api.startContact('AA:BB:CC:DD:EE:FF'), throwsException);
    expect(await api.loadActiveSession(), (id: null, mac: null));
  });

  test('an iOS UUID is rejected before GPS or any backend request', () async {
    await expectLater(
      api.startContact('e006b3a7-ef7b-4980-a668-1f8005f84383'),
      throwsArgumentError,
    );
    expect(gps.positionRequests, 0);
    expect(client.requests, isEmpty);
  });

  test('an unregistered tracker produces an actionable message', () async {
    client.statusCode = 404;
    await expectLater(
      api.startContact('AA:BB:CC:DD:EE:FF'),
      throwsA(
        isA<ContactRequestException>().having(
          (error) => error.message,
          'message',
          contains('niet geregistreerd'),
        ),
      ),
    );
    expect(await api.loadActiveSession(), (id: null, mac: null));
  });

  test('a failed end response preserves the active session', () async {
    await api.startContact('AA:BB:CC:DD:EE:FF');
    client.statusCode = 500;
    await expectLater(api.endContact('contact-1'), throwsException);
    expect(await api.loadActiveSession(), (
      id: 'contact-1',
      mac: 'AA:BB:CC:DD:EE:FF',
    ));
  });

  test('malformed end responses do not discard the active session', () async {
    await api.startContact('AA:BB:CC:DD:EE:FF');
    client.responseBody = 'invalid json';
    await expectLater(api.endContact('contact-1'), throwsFormatException);
    expect(await api.loadActiveSession(), (
      id: 'contact-1',
      mac: 'AA:BB:CC:DD:EE:FF',
    ));
  });
}
