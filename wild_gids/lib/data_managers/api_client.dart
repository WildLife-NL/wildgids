import 'dart:convert';
import 'dart:io';

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
    final uri = _buildUri(url);
    // debugPrint("GET: $uri");
    return await http.get(uri, headers: headers);
  }

  Future<http.Response> post(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    headers = await _buildHeaders(headers, authenticated);
    final uri = _buildUri(url);
    // debugPrint("POST: $uri");
    http.Response response = await http.post(
      uri,
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
    final uri = _buildUri(url);
    // debugPrint("PUT: $uri");
    return await http.put(uri, body: jsonEncode(body), headers: headers);
  }

  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    headers = await _buildHeaders(headers, authenticated);
    final uri = _buildUri(url);
    // debugPrint("DELETE: $uri");
    return await http.delete(uri, headers: headers);
  }

  /// Send a PATCH request with a JSON body.
  Future<http.Response> patch(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool authenticated = true,
  }) async {
    headers = await _buildHeaders(headers, authenticated);
    final uri = _buildUri(url);
    // debugPrint("PATCH: $uri");
    return await http.patch(uri, body: jsonEncode(body), headers: headers);
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
      // Only include Authorization header if we actually have a token.
      // Some endpoints allow anonymous access, and sending "Bearer null"
      // or an empty token may cause unintended 401s.
      if (token != null && token.isNotEmpty) {
        defaultHeaders[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }
    if (headers != null) {
      defaultHeaders.addAll(headers);
    }
    return defaultHeaders;
  }

  /// Build a canonical URI by resolving [url] against the configured baseUrl.
  Uri _buildUri(String url) {
    // Use Uri.resolve to avoid double-slash problems and ensure canonical paths.
    try {
      final base = Uri.parse(baseUrl);
      return base.resolve(url);
    } catch (e) {
      // Fallback: construct via simple concatenation
      return Uri.parse('$baseUrl/$url');
    }
  }
}
