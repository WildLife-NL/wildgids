import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/auth_api_interface.dart';
import 'package:wildgids/models/api_models/user.dart';

class AuthApi implements AuthApiInterface {
  final ApiClient client;
  AuthApi(this.client);

  @override
  Future<Map<String, dynamic>> authenticate(
    String displayNameApp,
    String email,
  ) async {
    http.Response response = await client.post('auth/', {
      "displayNameApp": displayNameApp,
      "email": email,
    }, authenticated: false);

    Map<String, dynamic>? json;
    try {
      json = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      debugPrint('Auth api: $json');
    } catch (_) {}
    debugPrint("statusCode: ${response.statusCode}");
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
      final token = json!["token"];
      debugPrint("[AuthApi] Token received from backend: $token");
      await prefs.setString('bearer_token', token);
      debugPrint("[AuthApi] Token saved to SharedPreferences");
      // Verify it was saved
      final savedToken = prefs.getString('bearer_token');
      debugPrint("[AuthApi] Verification - token in storage: ${savedToken == token ? "✓ MATCHES" : "✗ MISMATCH"}");
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

