import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/data_managers/response_api.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/auth_api.dart';
import 'package:wildgids/data_managers/interaction_api.dart';
import 'package:wildgids/data_managers/profile_api.dart';
import 'package:wildgids/data_managers/questionaire_api.dart';
import 'package:wildgids/data_managers/species_api.dart';
import 'package:wildgids/data_managers/vicinity_api.dart';
import 'package:wildgids/data_managers/tracking_api.dart';
import 'package:wildgids/managers/api_managers/tracking_cache_manager.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/data_apis/auth_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/interaction_api_interface.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/interfaces/filters/dropdown_interface.dart';
import 'package:wildgids/interfaces/filters/filter_interface.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/location/location_screen_interface.dart';
import 'package:wildgids/interfaces/other/login_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/other/overzicht_interface.dart';
import 'package:wildgids/interfaces/other/permission_interface.dart';
import 'package:wildgids/interfaces/reporting/questionnaire_interface.dart';
import 'package:wildgids/interfaces/reporting/response_interface.dart';
import 'package:wildgids/interfaces/data_apis/response_api_interface.dart';
import 'package:wildgids/managers/waarneming_flow/animal_manager.dart';
import 'package:wildgids/managers/waarneming_flow/animal_sighting_reporting_manager.dart';
import 'package:wildgids/managers/api_managers/interaction_manager.dart';
import 'package:wildgids/managers/api_managers/response_manager.dart';
import 'package:wildgids/managers/filtering_system/dropdown_manager.dart';
import 'package:wildgids/managers/map/location_screen_manager.dart';
import 'package:wildgids/managers/other/login_manager.dart';
import 'package:wildgids/managers/state_managers/navigation_state_manager.dart';
import 'package:wildgids/managers/other/overzicht_manager.dart';
import 'package:wildgids/managers/permission/permission_manager.dart';
import 'package:wildgids/managers/other/questionnaire_manager.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/constants/app_text_theme.dart';
import 'package:wildgids/managers/filtering_system/filter_manager.dart';
import 'package:wildgids/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/providers/response_provider.dart';
import 'package:wildgids/screens/login/login_screen.dart';
import 'package:wildgids/screens/gate/location_gate_screen.dart';
import 'package:wildgids/screens/shared/overzicht_screen.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';

import 'package:wildgids/data_managers/interaction_types_api.dart';
import 'package:wildgids/managers/api_managers/interaction_types_manager.dart';

import 'package:wildgids/providers/conveyance_provider.dart';
import 'package:wildgids/data_managers/conveyance_api.dart';

import 'package:wildgids/utils/token_validator.dart';
import 'package:wildgids/utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final appStateProvider = AppStateProvider();
  final prefs = await SharedPreferences.getInstance();
  final permissionManager = PermissionManager();

  // Load location tracking preference
  await appStateProvider.loadLocationTrackingPreference();

  await dotenv.load(fileName: ".env");

  // Initialize local notifications
  await NotificationService.instance.init();

  final apiClient = ApiClient(dotenv.get('DEV_BASE_URL'));
  final appConfig = AppConfig(apiClient);

  final authApi = AuthApi(apiClient);
  final profileApi = ProfileApi(apiClient);
  final speciesApi = SpeciesApi(apiClient);
  final interactionApi = InteractionApi(apiClient);
  final questionnaireAPI = QuestionaireApi(apiClient);
  final responseAPI = ResponseApi(apiClient);
  final vicinityApi = VicinityApi(apiClient);

  final loginManager = LoginManager(authApi, profileApi);
  final filterManager = FilterManager();
  final animalManager = AnimalManager(speciesApi, filterManager);
  final mapProvider = MapProvider();
  final responseProvider = ResponseProvider();

  final conveyanceApi = ConveyanceApi(apiClient);
  final conveyanceProvider = ConveyanceProvider(conveyanceApi);

  mapProvider.setVicinityApi(vicinityApi);

  // Interaction types: fetch/display names for UI
  final interactionTypesApi = InteractionTypesApi(apiClient);
  final interactionTypesManager = InteractionTypesManager(interactionTypesApi);

  final trackingApi = TrackingApi(apiClient);
  final trackingCacheManager = TrackingCacheManager(trackingApi: trackingApi);
  trackingCacheManager.init();
  mapProvider.setTrackingCacheManager(trackingCacheManager);

  final interactionManager = InteractionManager(interactionAPI: interactionApi);
  interactionManager.init();

  final responseManager = ResponseManager(
    responseAPI: responseAPI,
    responseProvider: responseProvider,
  );
  responseManager.init();


  final questionnaireManager = QuestionnaireManager(questionnaireAPI);

  final animalSightingReportingManager = AnimalSightingReportingManager();

  final locationScreenManager = LocationScreenManager();

  prefs.setStringList('interaction_cache', []);

  final bool hasValidToken = await TokenValidator.hasValidToken();
    final Widget _nextScreen =
      hasValidToken ? const OverzichtScreen() : const LoginScreen();
    final Widget initialScreen = LocationGateScreen(next: _nextScreen);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
        ChangeNotifierProvider<MapProvider>.value(value: mapProvider),
        ChangeNotifierProvider<ResponseProvider>.value(value: responseProvider),
        ChangeNotifierProvider<ConveyanceProvider>.value(
          value: conveyanceProvider,
        ),
        Provider<AppConfig>.value(value: appConfig),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthApiInterface>.value(value: authApi),
        Provider<ProfileApiInterface>.value(value: profileApi),
        Provider<SpeciesApiInterface>.value(value: speciesApi),
        Provider<InteractionApiInterface>.value(value: interactionApi),
        Provider<InteractionInterface>.value(value: interactionManager),
        Provider<InteractionTypesManager>.value(value: interactionTypesManager),
        Provider<LoginInterface>.value(value: loginManager),
        Provider<AnimalRepositoryInterface>.value(value: animalManager),
        Provider<AnimalManagerInterface>.value(value: animalManager),
        Provider<FilterInterface>.value(value: filterManager),
        Provider<OverzichtInterface>.value(value: OverzichtManager()),
        Provider<ResponseInterface>.value(value: responseManager),
        Provider<ResponseApiInterface>.value(value: responseAPI),
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
        debugShowCheckedModeBanner: false,
        navigatorKey: context.read<AppStateProvider>().navigatorKey,
        title: 'Wild Gids',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.lightMintGreen,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.darkGreen,
            surface: AppColors.lightMintGreen,
          ),
          textTheme: AppTextTheme.textTheme,
          fontFamily: 'Roboto',
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: AppColors.brown300,
            behavior: SnackBarBehavior.floating,
            contentTextStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Roboto',
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
        home: initialScreen,
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

