import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/api_models/contact_model.dart';

void main() {
  test('Contact parses animal, species and conveyance messages', () {
    final contact = Contact.fromJson({
      'ID': 'c-1',
      'contactHardwareAddress': 'AA:BB:CC:DD:EE:FF',
      'start': '2026-05-26T10:00:00Z',
      'borneSensorDeployment': {
        'sensorID': 'sensor-42',
        'animal': {
          'ID': 'animal-1',
          'name': 'Bam',
          'species': {'commonName': 'Wolf'},
        },
      },
      'conveyances': [
        {
          'ID': 'cv-1',
          'timestamp': '2026-05-26T10:00:01Z',
          'message': {
            'name': 'Welkom',
            'text': 'Blijf op afstand van het dier.',
            'severity': 2,
          },
        },
      ],
    });

    expect(contact.animalDisplayLabel, 'Bam (Wolf)');
    expect(contact.sensorId, 'sensor-42');
    expect(contact.conveyances, hasLength(1));
    expect(contact.conveyances.first.messageText, contains('afstand'));
    expect(contact.conveyances.first.displayText, contains('afstand'));
  });
}
