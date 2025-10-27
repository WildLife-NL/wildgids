import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:widgets/data_managers/api_client.dart';
import 'package:widgets/data_managers/auth_api.dart';
import 'package:widgets/data_managers/profile_api.dart';
import 'package:widgets/data_managers/species_api.dart';
import 'package:widgets/interfaces/other/login_interface.dart';
import 'package:widgets/interfaces/data_apis/profile_api_interface.dart';
import 'package:widgets/interfaces/data_apis/species_api_interface.dart';
import 'package:widgets/interfaces/waarneming_flow/animal_interface.dart';
import 'package:widgets/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:widgets/managers/other/login_manager.dart';
import 'package:widgets/managers/other/filter_manager.dart';
import 'package:widgets/managers/waarneming_flow/animal_manager.dart';
import 'package:widgets/managers/waarneming_flow/animal_sighting_reporting_manager.dart';
import 'package:widgets/config/app_config.dart';
import 'package:widgets/screens/login/login_screen_new.dart';
import 'package:widgets/screens/terms/terms_screen.dart';
import 'package:widgets/screens/shared/category_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final apiClient = ApiClient(dotenv.get('DEV_BASE_URL'));
  final appConfig = AppConfig(apiClient);

  // API instances for login
  final authApi = AuthApi(apiClient);
  final profileApi = ProfileApi(apiClient);
  
  // API instances for waarneming
  final speciesApi = SpeciesApi(apiClient);
  
  // Managers for waarneming flow
  final filterManager = FilterManager();
  final animalManager = AnimalManager(speciesApi, filterManager);
  final animalSightingManager = AnimalSightingReportingManager();

  // Managers for login
  final loginManager = LoginManager(authApi, profileApi);

  // Always start with login screen
  final Widget initialScreen = const LoginScreen();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: appConfig),
        Provider<ApiClient>.value(value: apiClient),
        Provider<LoginInterface>.value(value: loginManager),
        Provider<ProfileApiInterface>.value(value: profileApi),
        
  // Waarneming flow providers
  Provider<SpeciesApiInterface>.value(value: speciesApi),
  // Do not provide FilterManager via Provider to avoid Listenable debug check
  Provider<AnimalManagerInterface>.value(value: animalManager),
        Provider<AnimalSightingReportingInterface>.value(value: animalSightingManager),
      ],
      child: MyApp(
        initialScreen: initialScreen,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({
    super.key,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WildGids',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7FAF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5016),
          surface: const Color(0xFFF7FAF7),
        ),
        fontFamily: 'Arimo',
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF8B7355),
          behavior: SnackBarBehavior.floating,
          contentTextStyle: TextStyle(
            color: Colors.black,
            fontFamily: 'Arimo',
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => initialScreen,
        '/terms': (context) => const TermsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes - waarneming screens
        if (settings.name == '/category') {
          return MaterialPageRoute(
            builder: (context) => const CategoryScreen(),
          );
        }
        return null;
      },
    );
  }
}
