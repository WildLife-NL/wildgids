import 'package:flutter/foundation.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';

class SubmittedSightingsProvider extends ChangeNotifier {
  final List<AnimalSightingModel> _submittedSightings = [];

  List<AnimalSightingModel> get submittedSightings =>
      List.unmodifiable(_submittedSightings);

  void addSighting(AnimalSightingModel sighting) {
    _submittedSightings.insert(0, sighting); // Add to front (most recent first)
    notifyListeners();
  }

  void removeSighting(AnimalSightingModel sighting) {
    _submittedSightings.remove(sighting);
    notifyListeners();
  }

  void clearSightings() {
    _submittedSightings.clear();
    notifyListeners();
  }
}
