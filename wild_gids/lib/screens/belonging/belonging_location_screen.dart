import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/location/location_screen_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/screens/questionnaire/questionnaire_screen.dart';
import 'package:wildrapport/screens/shared/rapporteren.dart';
import 'package:wildrapport/utils/toast_notification_handler.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/widgets/location/location_screen_ui_widget.dart';
import 'package:wildrapport/widgets/location/permission_gate.dart';

class BelongingLocationScreen extends StatefulWidget {
  const BelongingLocationScreen({super.key});

  @override
  State<BelongingLocationScreen> createState() => _BelongingLocationScreenState();
}

class _BelongingLocationScreenState extends State<BelongingLocationScreen> {
  late final BelongingDamageReportInterface _belongingManager;
  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';
  final blueLog = '\x1B[34m';
  final purpleLog = '\x1B[35m';
  late final BelongingDamageReportProvider belongingProvider;
  late final MapProvider mapProvider;
  bool _isInitialized = false;
  String? _pendingSnackBarMessage;
  Widget? _pendingNavigationScreen;

  NavigationStateInterface get navigationManager => context.read<NavigationStateInterface>();

  @override
  void initState() {
    super.initState();
    debugPrint("$yellowLog[BelongingLocationScreen] 🔄 initState called\x1B[0m");
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    if (!mounted) return;

    debugPrint("$yellowLog[BelongingLocationScreen] 🔄 Initializing screen\x1B[0m");

    try {
      _belongingManager = context.read<BelongingDamageReportInterface>();
      belongingProvider = context.read<BelongingDamageReportProvider>();
      mapProvider = context.read<MapProvider>();

      if (!mapProvider.isInitialized) {
        debugPrint("$yellowLog[BelongingLocationScreen] 🔄 Initializing map provider\x1B[0m");
        await mapProvider.initialize();
      } else {
        debugPrint("$greenLog[BelongingLocationScreen] ✅ Map provider already initialized\x1B[0m");
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        debugPrint("$greenLog[BelongingLocationScreen] ✅ Screen initialized successfully\x1B[0m");
      }
    } catch (e) {
      debugPrint("$redLog[BelongingLocationScreen] ❌ Error initializing screen: $e\x1B[0m");
    }
  }

  void _handlePendingActions() {
    if (_pendingSnackBarMessage != null) {
      ToastNotificationHandler.sendToastNotification(context, _pendingSnackBarMessage!);
    }
    if (_pendingNavigationScreen != null) {
      // Use pushAndRemoveUntil to clear the navigation stack before showing questionnaire or overview
      navigationManager.pushAndRemoveUntil(context, _pendingNavigationScreen!);
    }
    _pendingSnackBarMessage = null;
    _pendingNavigationScreen = null;
  }

  void _handleNextPressed() async {
    debugPrint("$yellowLog[BelongingLocationScreen] 🔄 Next button pressed\x1B[0m");

    // Cache providers before async calls
    final mapProvider = context.read<MapProvider>();
    final locationManager = context.read<LocationScreenInterface>();
    final belongingManager = _belongingManager;

    // Force reinitialize map provider if needed
    if (!_isInitialized) {
      await _initializeScreen();
      if (!_isInitialized) {
        _pendingSnackBarMessage = 'Scherm niet geïnitialiseerd';
        WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
        return;
      }
    }

    // Fetch location
    Map<String, dynamic>? locationInfo;
    if (context.mounted) {
      debugPrint("$blueLog[BelongingLocationScreen] 📍 Fetching location with valid context\x1B[0m");
      try {
        // ignore: use_build_context_synchronously
        locationInfo = await locationManager.getLocationAndDateTime(context);
      } catch (e) {
        debugPrint("$redLog[BelongingLocationScreen] ❌ Error fetching location: $e\x1B[0m");
        _pendingSnackBarMessage = 'Kan locatie niet ophalen';
        WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
        return;
      }
    } else {
      debugPrint("$redLog[BelongingLocationScreen] ⚠️ Widget unmounted, skipping location fetch\x1B[0m");
      _pendingSnackBarMessage = 'Scherm niet langer beschikbaar';
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
      return;
    }

    debugPrint("\n$blueLog[BelongingLocationScreen] 📍 Location and DateTime Info:\x1B[0m");
    debugPrint("$blueLog[BelongingLocationScreen] Current GPS Location: ${locationInfo['currentGpsLocation']}\x1B[0m");
    debugPrint("$blueLog[BelongingLocationScreen] Selected Location: ${locationInfo['selectedLocation']}\x1B[0m");

    if (locationInfo['selectedLocation'] == null) {
      debugPrint("$redLog[BelongingLocationScreen] ⚠️ No selected location found\x1B[0m");
      _pendingSnackBarMessage = 'Selecteer een locatie';
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
      return;
    }

    // Update locations in possesion manager
    if (locationInfo['selectedLocation'] != null) {
      final selectedLocation = locationInfo['selectedLocation'];
      final reportLocation = ReportLocation(
        latitude: selectedLocation['latitude'],
        longtitude: selectedLocation['longitude'],
      );
      belongingManager.updateUserLocation(reportLocation);
      debugPrint("$greenLog[BelongingLocationScreen] ✅ Updated user location\x1B[0m");
    }

    if (locationInfo['currentGpsLocation'] != null) {
      final currentLocation = locationInfo['currentGpsLocation'];
      final systemLocation = ReportLocation(
        latitude: currentLocation['latitude'],
        longtitude: currentLocation['longitude'],
      );
      belongingManager.updateSystemLocation(systemLocation);
      debugPrint("$greenLog[BelongingLocationScreen] ✅ Updated system location\x1B[0m");
    }

    InteractionResponse? interactionResponseModel;
    try {
      interactionResponseModel = await belongingManager.postInteraction();
    } catch (e) {
      debugPrint("$redLog[BelongingLocationScreen] ❌ Error posting interaction: $e\x1B[0m");
      interactionResponseModel = null;
    }

    _pendingSnackBarMessage = interactionResponseModel == null
        ? "Geen toegang tot internet, interactie opgeslagen in opslag van uw toestel"
        : "interactie succesvol verstuurd";
    _pendingNavigationScreen = interactionResponseModel != null
        ? QuestionnaireScreen(
            questionnaire: interactionResponseModel.questionnaire,
            interactionID: interactionResponseModel.interactionID,
          )
        : const OverzichtScreen();

    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());

    mapProvider.resetState();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                leftIcon: Icons.arrow_back_ios,
                centerText: 'Locatie',
                rightIcon: Icons.menu,
                onLeftIconPressed: () {
                  belongingProvider.clearStateOfValues();
                  navigationManager.pushReplacementForward(
                    context,
                    const Rapporteren(),
                  );
                },
                onRightIconPressed: () {
                  /* Handle menu */
                },
              ),
              Expanded(
                child: _isInitialized
                    ? const LocationScreenUIWidget()
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomAppBar(
          onBackPressed: () => navigationManager.pushReplacementBack(
            context,
            const Rapporteren(),
          ),
          onNextPressed: _handleNextPressed,
          showNextButton: true,
          showBackButton: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Remove any map-related disposal
    super.dispose();
  }
}