import 'package:wildrapport/models/enums/animal_gender.dart';
import 'package:wildrapport/models/animal_waarneming_models/view_count_model.dart';
import 'package:wildrapport/models/enums/animal_condition.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_gender_view_count_model.dart'; // <-- Import the new file!

class AnimalModel {
  final String? animalId;
  final String? animalImagePath;
  final String animalName;
  final String? category;
  final List<AnimalGenderViewCount> genderViewCounts;
  final AnimalCondition? condition;

  AnimalModel({
    this.animalId,
    this.animalImagePath,
    required this.animalName,
    this.category,
    required this.genderViewCounts,
    this.condition,
  });

  // Helper methods
  AnimalGender? get gender {
    return genderViewCounts.isNotEmpty ? genderViewCounts.first.gender : null;
  }

  ViewCountModel? get viewCount {
    return genderViewCounts.isNotEmpty
        ? genderViewCounts.first.viewCount
        : null;
  }

  AnimalModel updateGender(AnimalGender newGender) {
    return AnimalModel(
      animalId: animalId,
      animalImagePath: animalImagePath,
      animalName: animalName,
      category: category,
      genderViewCounts: [
        AnimalGenderViewCount(
          gender: newGender,
          viewCount: viewCount ?? ViewCountModel(),
        ),
      ],
      condition: condition,
    );
  }

  AnimalModel updateViewCount(ViewCountModel newViewCount) {
    return AnimalModel(
      animalId: animalId,
      animalImagePath: animalImagePath,
      animalName: animalName,
      category: category,
      genderViewCounts: [
        AnimalGenderViewCount(
          gender: gender ?? AnimalGender.onbekend,
          viewCount: newViewCount,
        ),
      ],
      condition: condition,
    );
  }
}
