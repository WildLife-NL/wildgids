import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

class ApiClient {
  static const String _tokenKey = 'bearer_token';

  final String baseUrl;

  ApiClient(this.baseUrl);

  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    headers = await _buildHeaders(headers, authenticated);
    debugPrint("GET: $baseUrl/$url");
    return await http.get(Uri.parse('$baseUrl/$url'), headers: headers);
  }

  Future<http.Response> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    headers = await _buildHeaders(headers, authenticated);
    debugPrint("POST: $baseUrl/$url");
    http.Response response = await http.post(
      Uri.parse('$baseUrl/$url'),
      body: jsonEncode(body),
      headers: headers,
    );

    return response;
  }

  Future<http.Response> put(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    headers = await _buildHeaders(headers, authenticated);

    return await http.put(
      Uri.parse('$baseUrl/$url'),
      body: jsonEncode(body),
      headers: headers,
    );
  }

  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    headers = await _buildHeaders(headers, authenticated);

    return await http.delete(Uri.parse('$baseUrl/$url'), headers: headers);
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? headers,
    bool authenticated,
  ) async {
    final Map<String, String> defaultHeaders = {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    if (authenticated) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(_tokenKey);
      defaultHeaders[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    return defaultHeaders;
  }
}
