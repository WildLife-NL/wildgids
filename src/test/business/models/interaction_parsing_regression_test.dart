import 'package:flutter_test/flutter_test.dart';
import 'package:wildgids/models/api_models/interaction_type.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';

void main() {
  group('Interaction parsing regression', () {
    test('InteractionType parses string ID from backend', () {
      final model = InteractionType.fromJson({
        'ID': '1',
        'name': 'Waarneming',
        'description': 'Test',
      });

      expect(model.id, 1);
      expect(model.name, 'Waarneming');
    });

    test('MyInteraction parses nested type ID as string', () {
      final interaction = MyInteraction.fromJson({
        'ID': 'abc',
        'description': 'desc',
        'location': {'latitude': 52.0, 'longitude': 5.0},
        'moment': '2026-05-05T10:00:00Z',
        'place': {'latitude': 52.1, 'longitude': 5.1},
        'timestamp': '2026-05-05T10:00:00Z',
        'species': {'ID': 'wolf', 'name': 'Wolf', 'commonName': 'Wolf'},
        'user': {'ID': 'u1', 'name': 'User'},
        'type': {'ID': '2', 'name': 'Schade', 'description': 'Damage'},
      });

      expect(interaction.type.id, 2);
      expect(interaction.type.name, 'Schade');
    });
  });
}
