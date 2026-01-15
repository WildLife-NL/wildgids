import 'package:wildgids/models/enums/animal_condition.dart';
import 'package:wildgids/models/enums/animal_category.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/models/ui_models/image_list_model.dart';
import 'package:wildgids/models/ui_models/date_time_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_gender_view_count_model.dart';

class AnimalSightingModel {
  final List<AnimalModel>? animals;
  final AnimalModel? animalSelected;
  final AnimalCategory? category;
  final String? description;
  final List<LocationModel>? locations; // Changed to List
  final DateTimeModel? dateTime;
  final ImageListModel? images;

  AnimalSightingModel({
    this.animals,
    this.category,
    this.description,
    this.locations, // Updated parameter name
    this.dateTime,
    this.images,
    this.animalSelected,
  });

  AnimalSightingModel copyWith({
    List<AnimalModel>? animals,
    AnimalModel? animalSelected,
    AnimalCategory? category,
    String? description,
    List<LocationModel>? locations,
    DateTimeModel? dateTime,
    ImageListModel? images,
  }) {
    return AnimalSightingModel(
      animals: animals ?? this.animals,
      animalSelected: animalSelected ?? this.animalSelected,
      category: category ?? this.category,
      description: description ?? this.description,
      locations: locations ?? this.locations,
      dateTime: dateTime ?? this.dateTime,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animals':
          animals
              ?.map(
                (animal) => {
                  'animalId': animal.animalId,
                  'animalImagePath': animal.animalImagePath,
                  'animalName': animal.animalName,
                  'condition': animal.condition?.toString(),
                  'genderViewCounts':
                      animal.genderViewCounts
                          .map((gvc) => gvc.toJson())
                          .toList(),
                },
              )
              .toList(),
      'category': category?.toString(),
      'description': description,
      'locations': locations?.map((loc) => loc.toJson()).toList(),
      'dateTime': dateTime?.toJson(),
      'images': images?.toJson(),
    };
  }

  factory AnimalSightingModel.fromJson(
    Map<String, dynamic> json,
  ) => AnimalSightingModel(
    animals:
        json['animals'] != null
            ? List<AnimalModel>.from(
              json['animals'].map(
                (x) => AnimalModel(
                  animalId: x['animalId'],
                  animalImagePath: x['animalImagePath'],
                  animalName: x['animalName'],
                  condition:
                      x['condition'] != null
                          ? AnimalCondition.values.firstWhere(
                            (e) => e.toString() == x['condition'],
                            orElse: () => AnimalCondition.andere,
                          )
                          : null,
                  genderViewCounts:
                      x['genderViewCounts'] != null
                          ? List<AnimalGenderViewCount>.from(
                            x['genderViewCounts'].map(
                              (gvc) => AnimalGenderViewCount.fromJson(gvc),
                            ),
                          )
                          : [],
                ),
              ),
            )
            : null,
    animalSelected:
        json['animalSelected'] != null
            ? AnimalModel(
              animalId: json['animalSelected']['animalId'],
              animalImagePath: json['animalSelected']['animalImagePath'],
              animalName: json['animalSelected']['animalName'],
              condition:
                  json['animalSelected']['condition'] != null
                      ? AnimalCondition.values.firstWhere(
                        (e) =>
                            e.toString() == json['animalSelected']['condition'],
                        orElse: () => AnimalCondition.andere,
                      )
                      : null,
              genderViewCounts:
                  json['animalSelected']['genderViewCounts'] != null
                      ? List<AnimalGenderViewCount>.from(
                        json['animalSelected']['genderViewCounts'].map(
                          (gvc) => AnimalGenderViewCount.fromJson(gvc),
                        ),
                      )
                      : [],
            )
            : null,
    category:
        json['category'] != null
            ? AnimalCategory.values.firstWhere(
              (e) => e.toString() == json['category'],
              orElse: () => AnimalCategory.andere,
            )
            : null,
    description: json['description'],
    locations:
        json['locations'] !=
                null // Updated to handle list of locations
            ? List<LocationModel>.from(
              json['locations'].map((x) => LocationModel.fromJson(x)),
            )
            : null,
    dateTime:
        json['dateTime'] != null
            ? DateTimeModel.fromJson(json['dateTime'])
            : null,
    images:
        json['images'] != null ? ImageListModel.fromJson(json['images']) : null,
  );
}

