import 'package:shared_preferences/shared_preferences.dart';

class SpeciesClickTracker {
  static const String _keyPrefix = 'clicked_species_';
  static const String _globalKey = 'clicked_species_global';

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userID');
  }

  static Future<String> _resolveStorageKey() async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) return _globalKey;
    return '$_keyPrefix$userId';
  }

  static Future<Set<String>> _getClickedSet() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveStorageKey();
    final list = prefs.getStringList(key) ?? const <String>[];
    return list.toSet();
  }

  static Future<bool> isClicked(String speciesId) async {
    if (speciesId.isEmpty) return false;
    final set = await _getClickedSet();
    return set.contains(speciesId);
  }

  static Future<void> markClicked(String speciesId) async {
    if (speciesId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _resolveStorageKey();
    final set = (prefs.getStringList(key) ?? const <String>[]).toSet();
    if (set.add(speciesId)) {
      await prefs.setStringList(key, set.toList());
    }
  }
}
