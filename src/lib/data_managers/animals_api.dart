import 'dart:convert';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/animals_api_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';

class AnimalsApi implements AnimalsApiInterface {
  final ApiClient apiClient;
  AnimalsApi(this.apiClient);

  @override
  Future<List<AnimalPin>> getAllAnimals() async {
    final res = await apiClient.get('animals/', authenticated: true);

    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isEmpty) return const [];
      final data = json.decode(body);
      final list = (data is List) ? data : const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((m) => AnimalPin.fromJson(m))
          .toList();
    }

    if (res.statusCode == 204) return const [];
    throw Exception('Animals GET failed (${res.statusCode}): ${res.body}');
  }
}

