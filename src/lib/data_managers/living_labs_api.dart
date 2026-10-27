import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/models/ui_models/weather_living_lab.dart';

class LivingLabsApi {
  LivingLabsApi(this.client);

  final ApiClient client;
  String get _cacheKey => 'home_backend_labs_v1_${client.baseUrl}';

  Future<List<WeatherLivingLab>> getAll() async {
    final response = await client
        .get('/livinglabs/')
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Living labs request failed (${response.statusCode})');
    }
    final labs = WeatherLivingLab.parseList(jsonDecode(response.body));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'fetchedAt': DateTime.now().toIso8601String(),
          'labs': jsonDecode(response.body),
        }),
      );
    } catch (_) {
      // Storage failure must not discard a valid backend response.
    }
    return labs;
  }

  Future<List<WeatherLivingLab>> readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return const [];
      final cache = jsonDecode(raw) as Map<String, dynamic>;
      final age = DateTime.now().difference(DateTime.parse(cache['fetchedAt']));
      if (age < Duration.zero || age > const Duration(days: 7)) return const [];
      return WeatherLivingLab.parseList(cache['labs']);
    } catch (_) {
      return const [];
    }
  }
}
