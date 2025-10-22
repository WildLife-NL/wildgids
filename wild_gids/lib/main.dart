import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login/login_screen_new.dart';
import 'screens/terms/terms_screen.dart';
import 'managers/other/login_manager.dart';
import 'interfaces/other/login_interface.dart';
import 'interfaces/data_apis/profile_api_interface.dart';
import 'data_managers/auth_api.dart';
import 'data_managers/profile_api.dart';
import 'data_managers/api_client.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  final apiClient = ApiClient(dotenv.get('DEV_BASE_URL'));
  final appConfig = AppConfig(apiClient);
  
  final authApi = AuthApi(apiClient);
  final profileApi = ProfileApi(apiClient);
  final loginManager = LoginManager(authApi, profileApi);
  
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('bearer_token');
  
  final Widget initialScreen = token != null 
      ? const LoginScreen()  // Will check terms status and redirect
      : const LoginScreen();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: appConfig),
        Provider<ApiClient>.value(value: apiClient),
        Provider<LoginInterface>.value(value: loginManager),
        Provider<ProfileApiInterface>.value(value: profileApi),
      ],
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  
  const MyApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WildGids',
      initialRoute: '/',
      routes: {
        '/': (context) => initialScreen,
        '/terms': (context) => const TermsScreen(),
      },
    );
  }
}
