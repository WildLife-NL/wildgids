  import 'dart:convert';
  import 'dart:io';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';

  import 'package:widgets/data_managers/api_client.dart';
  import 'package:widgets/interfaces/data_apis/profile_api_interface.dart';
  import 'package:widgets/models/beta_models/profile_model.dart';

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

  /// Usage: await updateReportAppTerms(true);
@override
Future<Profile> updateReportAppTerms(bool accepted) async {
  final current = await fetchMyProfile();

  final body = current.toJson()
    ..['reportAppTerms'] = accepted;

  final response = await client.put('/profile/me/', body, authenticated: true);

  if (response.statusCode == HttpStatus.ok) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    final updated = Profile.fromJson(json);
    await _cacheProfile(updated);
    return updated;
  } else {
    throw Exception(
      "Failed to update reportAppTerms (${response.statusCode}): ${response.body}",
    );
  }
}







  }
