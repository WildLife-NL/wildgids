import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/confirmed_trail_entrance.dart';

Map<String, dynamic> entranceRecord({
  String id = 'koevlak',
  List<String> routes = const ['1'],
}) => {
  'id': id,
  'name': 'Ingang $id',
  'latitude': 52.3948644,
  'longitude': 4.5941305,
  'routeIds': routes,
  'confirmed': true,
  'source':
      'https://www.np-zuidkennemerland.nl/gebiedsinformatie/overzichtskaart/',
  'verifiedOn': '2026-11-19',
};

void main() {
  test(
    'only explicitly confirmed entrances with park evidence are navigable',
    () {
      final entries = parseConfirmedTrailEntrances(
        jsonEncode({
          'entrances': [
            entranceRecord(),
            {...entranceRecord(id: 'unreviewed'), 'confirmed': false},
            {...entranceRecord(id: 'unknown')}..remove('confirmed'),
          ],
        }),
      );
      expect(entries.map((e) => e.id), ['koevlak']);
      expect(
        entries.single.directions.queryParameters['destination'],
        '52.3948644,4.5941305',
      );
    },
  );

  test(
    'missing evidence, invalid coordinates and duplicate IDs fail closed',
    () {
      for (final record in [
        {...entranceRecord(), 'source': 'https://example.com/unreviewed'},
        {...entranceRecord(), 'source': 'http://www.np-zuidkennemerland.nl/'},
        {...entranceRecord(), 'latitude': 91},
        {...entranceRecord(), 'routeIds': <String>[]},
        {...entranceRecord(), 'verifiedOn': null},
      ]) {
        expect(
          () => parseConfirmedTrailEntrances(
            jsonEncode({
              'entrances': [record],
            }),
          ),
          throwsFormatException,
        );
      }
      expect(
        () => parseConfirmedTrailEntrances(
          jsonEncode({
            'entrances': [entranceRecord(), entranceRecord()],
          }),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'the six published pins cover only the twelve explicitly named trails',
    () {
      final entrances = parseConfirmedTrailEntrances(
        File('assets/routes/confirmed_entrances.json').readAsStringSync(),
      );
      expect(entrances, hasLength(6));
      expect(entrances.expand((e) => e.routeIds).toSet(), {
        '39',
        '40',
        '41',
        '44',
        '45',
        '46',
        '50',
        '67',
        '74',
        '80',
        '102',
        '103',
      });
      expect(entrances.any((e) => e.routeIds.contains('61')), isFalse);
      final koevlak = entrances.singleWhere((e) => e.id == 'koevlak');
      expect(koevlak.point.latitude, 52.3948644);
      expect(koevlak.point.longitude, 4.5941305);
    },
  );
}
