import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/models/beta_models/profile_model.dart';

class ProfileApi implements ProfileApiInterface {
  final ApiClient client;
  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';
  ProfileApi(this.client);

  // @override
  // Future<void> setProfileDataInDeviceStorage() async {
  //   http.Response response = await client.get(
  //     '/profile/me/',
  //     authenticated: true,
  //   );

  //   Map<String, dynamic>? json;

  //   if (response.statusCode == HttpStatus.ok) {
  //     json = jsonDecode(response.body);
  //     await _setTheProfileData(Profile.fromJson(json!));
  //   } else {
  //     throw Exception(json ?? "$redLog Failed to get profile data!");
  //   }
  // }

  /// (Kept) Load /profile/me and cache essentials locally.
  @override
  Future<void> setProfileDataInDeviceStorage() async {
    final http.Response response = await client.get(
      '/profile/me/',
      authenticated: true,
    );

    if (response.statusCode == HttpStatus.ok) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final profile = Profile.fromJson(json);
      await _cacheProfile(profile);
    } else {
      throw Exception(
        "$redLog Failed to get profile data (${response.statusCode}): ${response.body}",
      );
    }
  }

  /// CENTRALIZED local cache (only caches keys you actually use).
  Future<void> _cacheProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userID', profile.userID);
    await prefs.setString('email', profile.email);
    await prefs.setString('userName', profile.userName);

    if (profile.gender != null) {
      await prefs.setString('gender', profile.gender!);
    }
    if (profile.postcode != null) {
      await prefs.setString('postcode', profile.postcode!);
    }
    if (profile.reportAppTerms != null) {
      await prefs.setBool('reportAppTerms', profile.reportAppTerms!);
    }
  }

  /// NEW: Fetch the full profile (used to check reportAppTerms).
  @override
  Future<Profile> fetchMyProfile() async {
    final http.Response response = await client.get(
      '/profile/me/',
      authenticated: true,
    );

    if (response.statusCode == HttpStatus.ok) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final profile = Profile.fromJson(json);
      await _cacheProfile(profile); // keep local cache in sync
      return profile;
    } else {
      throw Exception(
        "$redLog Failed to fetch profile (${response.statusCode}): ${response.body}",
      );
    }
  }

  @override
  Future<Profile> updateReportAppTerms(bool accepted) async {
    // Send a minimal request to update only the terms flag. Using a minimal
    // payload avoids schema/validation issues that can occur when PUT-ing the
    // entire profile object (which may contain server-managed or null fields).
    final body = {'reportAppTerms': accepted};

    debugPrint('[ProfileApi] PATCH /profile/me/ body: ${jsonEncode(body)}');

    // Use PATCH for partial update; if server doesn't accept PATCH, fall back to PUT.
    http.Response response;
    try {
      response = await client.patch('/profile/me/', body, authenticated: true);
    } catch (e) {
      debugPrint('[ProfileApi] PATCH failed, falling back to PUT: $e');
      // fallback: try PUT with minimal body
      response = await client.put('/profile/me/', body, authenticated: true);
    }

    debugPrint(
      '[ProfileApi] Response (${response.statusCode}): ${response.body}',
    );

    if (response.statusCode == HttpStatus.ok) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final updated = Profile.fromJson(json);
      await _cacheProfile(updated);
      return updated;
    } else if (response.statusCode == HttpStatus.unprocessableEntity ||
        response.statusCode == HttpStatus.methodNotAllowed) {
      // If the server rejects partial body (422 or 405), fetch the current full
      // profile, update the flag, and PUT the complete resource.
      debugPrint(
        '[ProfileApi] Server returned ${response.statusCode}; attempting full-profile PUT',
      );
      try {
        final current = await fetchMyProfile();
        final fullBody = current.toJson()..['reportAppTerms'] = accepted;
        debugPrint(
          '[ProfileApi] PUT /profile/me/ fullBody: ${jsonEncode(fullBody)}',
        );
        final putResponse = await client.put(
          '/profile/me/',
          fullBody,
          authenticated: true,
        );
        debugPrint(
          '[ProfileApi] PUT Response (${putResponse.statusCode}): ${putResponse.body}',
        );
        if (putResponse.statusCode == HttpStatus.ok) {
          final Map<String, dynamic> json = jsonDecode(putResponse.body);
          final updated = Profile.fromJson(json);
          await _cacheProfile(updated);
          return updated;
        } else {
          throw Exception(
            'Failed to update reportAppTerms via full PUT (${putResponse.statusCode}): ${putResponse.body}',
          );
        }
      } catch (e) {
        throw Exception(
          'Failed to update reportAppTerms (after full-profile PUT): $e',
        );
      }
    }

    throw Exception(
      "Failed to update reportAppTerms (${response.statusCode}): ${response.body}",
    );
  }

  @override
  Future<void> deleteMyProfile() async {
    debugPrint('[ProfileApi] DELETE /profile/me/');

    final http.Response response = await client.delete(
      '/profile/me/',
      authenticated: true,
    );

    debugPrint('[ProfileApi] DELETE Response (${response.statusCode})');

    if (response.statusCode == HttpStatus.noContent) {
      // 204 No Content - Success
      debugPrint('$greenLog Profile successfully deleted!');
    } else if (response.statusCode == HttpStatus.ok) {
      // Some APIs return 200 OK instead of 204
      debugPrint('$greenLog Profile successfully deleted (200 OK)!');
    } else {
      throw Exception(
        "$redLog Failed to delete profile (${response.statusCode}): ${response.body}",
      );
    }
  }

  @override
  Future<Profile> updateMyProfile(Profile updatedProfile) async {
    final body = {
      'name': updatedProfile.userName,
      'email': updatedProfile.email,
      'gender': updatedProfile.gender,
      'postcode': updatedProfile.postcode,
      'reportAppTerms': updatedProfile.reportAppTerms ?? false,
      'recreationAppTerms': updatedProfile.recreationAppTerms ?? false,
      if (updatedProfile.dateOfBirth != null)
        'dateOfBirth': updatedProfile.dateOfBirth,
      if (updatedProfile.description != null)
        'description': updatedProfile.description,
    };

    debugPrint('[ProfileApi] PUT /profile/me/ body: ${jsonEncode(body)}');

    final http.Response response = await client.put(
      '/profile/me/',
      body,
      authenticated: true,
    );

    debugPrint(
      '[ProfileApi] PUT Response (${response.statusCode}): ${response.body}',
    );

    if (response.statusCode == HttpStatus.ok) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final updated = Profile.fromJson(json);
      await _cacheProfile(updated);
      return updated;
    } else {
      throw Exception(
        "$redLog Failed to update profile (${response.statusCode}): ${response.body}",
      );
    }
  }
}

