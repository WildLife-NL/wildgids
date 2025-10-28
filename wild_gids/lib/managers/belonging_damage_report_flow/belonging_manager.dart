import 'package:flutter/material.dart';
import 'package:wildrapport/interfaces/data_apis/belonging_api_interface.dart';
import 'package:wildrapport/interfaces/other/belonging_manager_interface.dart';
import 'package:wildrapport/models/beta_models/belonging_model.dart';

class BelongingManager implements BelongingManagerInterface {
  final BelongingApiInterface belongingApi;

  BelongingManager({required this.belongingApi});

  @override
  Future<List<String>> getAllBelongingsFilteredAndFormatted(
    String category,
  ) async {
    try {
      List<Belonging> belongings = await belongingApi.getAllBelongings();
      List<String> belongingsFormatted = [];
      for (Belonging belonging in belongings) {
        if (belonging.category == category) {
          belongingsFormatted.add(belonging.name);
        }
      }
      return belongingsFormatted;
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
}
