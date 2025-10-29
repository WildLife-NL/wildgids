import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/data_managers/belonging_api.dart';
import 'package:wildrapport/data_managers/response_api.dart';
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/data_managers/auth_api.dart';
import 'package:wildrapport/data_managers/interaction_api.dart';
import 'package:wildrapport/data_managers/profile_api.dart';
import 'package:wildrapport/data_managers/questionaire_api.dart';
import 'package:wildrapport/data_managers/species_api.dart';
import 'package:wildrapport/data_managers/animals_api.dart';
import 'package:wildrapport/data_managers/detections_api.dart';
import 'package:wildrapport/data_managers/tracking_api.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/interfaces/data_apis/auth_api_interface.dart';
import 'package:wildrapport/interfaces/data_apis/belonging_api_interface.dart';
import 'package:wildrapport/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildrapport/interfaces/data_apis/species_api_interface.dart';
import 'package:wildrapport/interfaces/filters/dropdown_interface.dart';
import 'package:wildrapport/interfaces/filters/filter_interface.dart';
import 'package:wildrapport/interfaces/reporting/interaction_interface.dart';
import 'package:wildrapport/interfaces/location/location_screen_interface.dart';
import 'package:wildrapport/interfaces/other/login_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/interfaces/other/overzicht_interface.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildrapport/interfaces/reporting/questionnaire_interface.dart';
import 'package:wildrapport/interfaces/reporting/response_interface.dart';
import 'package:wildrapport/managers/waarneming_flow/animal_manager.dart';
import 'package:wildrapport/managers/waarneming_flow/animal_sighting_reporting_manager.dart';
import 'package:wildrapport/managers/api_managers/interaction_manager.dart';
import 'package:wildrapport/managers/api_managers/response_manager.dart';
import 'package:wildrapport/managers/filtering_system/dropdown_manager.dart';
import 'package:wildrapport/managers/map/location_screen_manager.dart';
import 'package:wildrapport/managers/other/login_manager.dart';
import 'package:wildrapport/managers/state_managers/navigation_state_manager.dart';
import 'package:wildrapport/managers/other/overzicht_manager.dart';
import 'package:wildrapport/managers/permission/permission_manager.dart';
import 'package:wildrapport/managers/belonging_damage_report_flow/belonging_damage_report_manager.dart';
import 'package:wildrapport/managers/other/questionnaire_manager.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';
import 'package:wildrapport/managers/filtering_system/filter_manager.dart';
import 'package:wildrapport/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:wildrapport/providers/response_provider.dart';
import 'package:wildrapport/screens/login/login_screen.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildrapport/data_managers/interaction_query_api.dart';
import 'package:wildrapport/managers/api_managers/interaction_query_manager.dart';
import 'package:wildrapport/managers/api_managers/animal_pins_manager.dart';
import 'package:wildrapport/managers/api_managers/detection_pins_manager.dart';

import 'package:wildrapport/utils/token_validator.dart';

Future<Widget> getHomepageBasedOnLoginStatus() async {
  final hasValidToken = await TokenValidator.hasValidToken();
  return hasValidToken ? const OverzichtScreen() : const LoginScreen();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appStateProvider = AppStateProvider();
  final prefs = await SharedPreferences.getInstance();
  final permissionManager = PermissionManager();

  await dotenv.load(fileName: ".env");

  final apiClient = ApiClient(dotenv.get('DEV_BASE_URL'));
  final appConfig = AppConfig(apiClient);

  final geoApiClient = ApiClient(
    'https://test-api-geo-prd-wildlifenl.apps.cl01.cp.its.uu.nl',
  );

  final authApi = AuthApi(apiClient);
  final profileApi = ProfileApi(apiClient);
  final speciesApi = SpeciesApi(apiClient);
  final interactionApi = InteractionApi(apiClient);
  final questionnaireAPI = QuestionaireApi(apiClient);
  final responseAPI = ResponseApi(apiClient);
  final belongingApi = BelongingApi(apiClient);
  final animalsApi = AnimalsApi(apiClient);
  final detectionsApi = DetectionsApi(apiClient);

  final animalPinsManager = AnimalPinsManager(animalsApi);
  final detectionPinsManager = DetectionPinsManager(detectionsApi);
  final loginManager = LoginManager(authApi, profileApi);
  final filterManager = FilterManager();
  final animalManager = AnimalManager(speciesApi, filterManager);
  final belongingDamageFormProvider = BelongingDamageReportProvider();
  final mapProvider = MapProvider();
  final responseProvider = ResponseProvider();

  final interactionQueryApi = InteractionQueryApi(geoApiClient);
  final interactionQueryManager = InteractionQueryManager(interactionQueryApi);
  mapProvider.setInteractionsManager(interactionQueryManager);
  mapProvider.setDetectionPinsManager(detectionPinsManager);
  mapProvider.setAnimalPinsManager(animalPinsManager);

  final trackingApi = TrackingApi(apiClient);
mapProvider.setTrackingApi(trackingApi);


  final interactionManager = InteractionManager(interactionAPI: interactionApi);
  interactionManager.init();

  final responseManager = ResponseManager(
    responseAPI: responseAPI,
    responseProvider: responseProvider,
  );
  responseManager.init();

  final belongingManager = BelongingDamageReportManager(
    interactionAPI: interactionApi,
    belongingAPI: belongingApi,
    formProvider: belongingDamageFormProvider,
    mapProvider: mapProvider,
    interactionManager: interactionManager,
  );
  belongingManager.init();

  final questionnaireManager = QuestionnaireManager(questionnaireAPI);

  final animalSightingReportingManager = AnimalSightingReportingManager();

  final locationScreenManager = LocationScreenManager();

  prefs.setStringList('interaction_cache', []);
  
  final bool hasValidToken = await TokenValidator.hasValidToken();
  final Widget initialScreen = hasValidToken 
      ? const OverzichtScreen() 
      : const LoginScreen();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
        ChangeNotifierProvider<BelongingDamageReportProvider>.value(
          value: belongingDamageFormProvider,
        ),
        ChangeNotifierProvider<MapProvider>.value(value: mapProvider),
        ChangeNotifierProvider<ResponseProvider>.value(value: responseProvider),
        Provider<AppConfig>.value(value: appConfig),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthApiInterface>.value(value: authApi),
        Provider<ProfileApiInterface>.value(value: profileApi),
        Provider<SpeciesApiInterface>.value(value: speciesApi),
        Provider<InteractionApiInterface>.value(value: interactionApi),
        Provider<BelongingApiInterface>.value(value: belongingApi),
        Provider<InteractionInterface>.value(value: interactionManager),
        Provider<LoginInterface>.value(value: loginManager),
        Provider<AnimalRepositoryInterface>.value(value: animalManager),
        Provider<AnimalManagerInterface>.value(value: animalManager),
        Provider<FilterInterface>.value(value: filterManager),
        Provider<OverzichtInterface>.value(value: OverzichtManager()),
        Provider<BelongingDamageReportInterface>.value(value: belongingManager),
        Provider<ResponseInterface>.value(value: responseManager),
        Provider<DropdownInterface>.value(
          value: DropdownManager(filterManager),
        ),
        Provider<QuestionnaireInterface>.value(value: questionnaireManager),
        Provider<ResponseManager>.value(value: responseManager),
        Provider<AnimalSightingReportingInterface>(
          create: (context) => animalSightingReportingManager,
        ),
        Provider<NavigationStateInterface>(
          create: (context) => NavigationStateManager(),
        ),
        Provider<LocationScreenInterface>(create: (_) => locationScreenManager),
        Provider<PermissionInterface>(create: (_) => permissionManager),
      ],
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}

class UserService {}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return _MediaQueryWrapper(
      child: MaterialApp(
        navigatorKey: context.read<AppStateProvider>().navigatorKey,
        title: 'Wild Rapport',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.lightMintGreen,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.darkGreen,
            surface: AppColors.lightMintGreen,
          ),
          textTheme: AppTextTheme.textTheme,
          fontFamily: 'Arimo',
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: AppColors.brown300,
            behavior: SnackBarBehavior.floating,
            contentTextStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Arimo',
            ),
          ),
        ),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.textScalerOf(context).scale(1.0).clamp(0.8, 1.4),
              ),
            ),
            child: child!,
          );
        },
        home: FutureBuilder<Widget>(
          future: getHomepageBasedOnLoginStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text('Something went wrong')),
              );
            } else {
              return snapshot.data!;
            }
          },
        ),
      ),
    );
  }
}

class _MediaQueryWrapper extends StatelessWidget {
  final Widget child;

  const _MediaQueryWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final baseTextScale = (screenSize.width / 375).clamp(0.8, 1.2);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          baseTextScale *
              MediaQuery.textScalerOf(context).scale(1.0).clamp(0.8, 1.4),
        ),
        viewInsets: MediaQuery.of(context).viewInsets.copyWith(
          bottom: MediaQuery.of(context).viewInsets.bottom * 0.8,
        ),
      ),
      child: child,
    );
  }
}
