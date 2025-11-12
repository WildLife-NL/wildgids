import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/interfaces/data_apis/belonging_api_interface.dart';
import 'package:wildrapport/models/beta_models/belonging_model.dart';

class BelongingApi implements BelongingApiInterface {
  final ApiClient client;
  BelongingApi(this.client);

  @override
  Future<List<Belonging>> getAllBelongings() async {
    http.Response response = await client.get(
      '/belonging/',
      authenticated: true,
    );

    if (response.statusCode == HttpStatus.ok) {
      final json = jsonDecode(response.body) as List;
      return json.map((e) => Belonging.fromJson(e)).toList();
    } else {
        debugPrint("Failed to get belongings!");
        return [];
    }
  }
}
