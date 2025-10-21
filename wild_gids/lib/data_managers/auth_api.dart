import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:widgets/data_managers/api_client.dart';
import 'package:widgets/interfaces/data_apis/auth_api_interface.dart';
import 'package:widgets/models/api_models/user.dart';

class AuthApi implements AuthApiInterface {
  final ApiClient client;
  AuthApi(this.client);

  @override
  Future<Map<String, dynamic>> authenticate(
    String displayNameApp,
    String email,
  ) async {
    final payload = {
      "displayNameApp": "WildlifeNL", // Always use correct app name
      "email": email,
    };
    debugPrint('POST /auth/ payload: ' + payload.toString());
    http.Response response = await client.post('auth/', payload, authenticated: false);
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');

    Map<String, dynamic>? json;
    try {
      json = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      debugPrint('Auth api: $json');
    } catch (e) {
      debugPrint('JSON decode error: $e');
    }
    if (response.statusCode == HttpStatus.ok) {
      return json ?? {};
    } else {
      throw Exception(json ?? "Failed to login");
    }
  }

  @override
  Future<User> authorize(String email, String code) async {
    debugPrint("Starting Authorization");
    http.Response response = await client.put('auth/', {
      "code": code,
      "email": email,
    }, authenticated: false);
    debugPrint("Response code: ${response.statusCode}");

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(response.body);
      debugPrint('V1 Auth api: $json');
    } catch (error) {
      debugPrint("Error: $error");
    }

    if (response.statusCode == HttpStatus.ok) {
      debugPrint("Code Succesfully Verified!");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('bearer_token', json!["token"]);
      debugPrint("Code stored in shared prefrences");
      debugPrint(json.toString());
      User user = User.fromJson(json);
      return user;
    } else {
      debugPrint("Could not verify code!");
      throw Exception(json!["detail"]);
    }
  }
}
