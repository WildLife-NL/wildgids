import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/data_managers/profile_api.dart';
import 'flows/belonging_damage_flow.dart' as belonging_damage_flow;
import 'flows/waarneming_flow.dart' as waarneming_flow_flow;
import 'package:flutter/foundation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('bearer_token', dotenv.get('testAuthToken')); 
    await prefs.setStringList('interaction_cache', []);

    final apiClient = ApiClient(dotenv.get('DEV_BASE_URL'));
    final profileApi = ProfileApi(apiClient);
    profileApi.setProfileDataInDeviceStorage();

    // Request location permission
    final permissionStatus = await Permission.location.request();
    if (!permissionStatus.isGranted) {
      if (kDebugMode) {
        print('Warning: Location permission not granted.');
      }
    }
  });

  // Add delay to ensure app initialization
  setUp(() async {
    await Future.delayed(const Duration(seconds: 5));
  });

  // Run tests
  belonging_damage_flow.runTests();
  waarneming_flow_flow.runTests();
}
