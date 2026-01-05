import 'package:flutter/foundation.dart';
import 'package:wildrapport/interfaces/data_apis/interaction_types_api_interface.dart';
import 'package:wildrapport/models/api_models/interaction_type.dart';

class InteractionTypesManager {
  final InteractionTypesApiInterface _api;
  List<InteractionType>? _cached;

  InteractionTypesManager(this._api);

  /// Ensure types are fetched and cached. Returns the cached list.
  Future<List<InteractionType>> ensureFetched() async {
    if (_cached != null) return _cached!;
    try {
      _cached = await _api.getAllInteractionTypes();
      return _cached!;
    } catch (e) {
      debugPrint('[InteractionTypesManager] fetch error: $e');
      _cached = const [];
      return _cached!;
    }
  }

  /// Get the display name for a known type id. Returns null if not found.
  String? nameForTypeId(int id) {
    if (_cached == null) return null;
    for (final t in _cached!) {
      if (t.id == id) return t.name;
    }
    return null;
  }
}
