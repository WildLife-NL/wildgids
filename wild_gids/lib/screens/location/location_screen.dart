import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/interfaces/reporting/interaction_interface.dart';
import 'package:wildrapport/interfaces/location/location_screen_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/models/beta_models/animal_sighting_report_wrapper.dart';
import 'package:wildrapport/models/beta_models/accident_report_model.dart';
import 'package:wildrapport/models/beta_models/report_location_model.dart';
import 'package:wildrapport/models/beta_models/sighted_animal_model.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import 'package:wildrapport/models/enums/interaction_type.dart';
import 'package:wildrapport/models/enums/report_type.dart';
import 'package:wildrapport/models/enums/location_source.dart';
import 'package:wildrapport/models/beta_models/location_model.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/screens/waarneming/animal_list_overview_screen.dart';
import 'package:wildrapport/screens/waarneming/collision_details_screen.dart';
import 'package:wildrapport/screens/questionnaire/questionnaire_screen.dart';
import 'package:wildrapport/screens/shared/rapporteren.dart';
import 'package:wildrapport/utils/sighting_api_transformer.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/widgets/location/location_screen_ui_widget.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _pendingSnackBarMessage;
  Widget? _pendingNavigationScreen;
  bool _pendingRemoveUntil = false;

  void _handlePendingActions() {
    if (_pendingSnackBarMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pendingSnackBarMessage!),
          backgroundColor: _pendingSnackBarMessage!.contains('fout') ? Colors.red : Colors.orange,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
    if (_pendingNavigationScreen != null) {
      final navManager = context.read<NavigationStateInterface>();
      if (_pendingRemoveUntil) {
        navManager.pushAndRemoveUntil(context, _pendingNavigationScreen!);
      } else {
        navManager.pushReplacementForward(context, _pendingNavigationScreen!);
      }
    }
    _pendingSnackBarMessage = null;
    _pendingNavigationScreen = null;
    _pendingRemoveUntil = false;
  }

  Future<void> _handleNextPressed() async {
  final animalSightingManager = context.read<AnimalSightingReportingInterface>();
  final locationManager = context.read<LocationScreenInterface>();
  final interactionManager = context.read<InteractionInterface>();
  final mapProvider = context.read<MapProvider>();

  try {
    debugPrint('\x1B[35m[LocationScreen] Starting location update process\x1B[0m');

    final locationInfo = await locationManager.getLocationAndDateTime(context);
    debugPrint('\x1B[35m[LocationScreen] LocationInfo: $locationInfo\x1B[0m');

    // 1. must have a chosen place
    if (locationInfo['selectedLocation'] == null) {
      _pendingSnackBarMessage = 'Selecteer eerst een locatie';
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
      return;
    }

    final currentSighting = animalSightingManager.getCurrentanimalSighting();
    if (currentSighting == null) {
      throw StateError('No active animal sighting found');
    }

    // 2. update locations in the sighting
    if (locationInfo['currentGpsLocation'] != null) {
      final systemLocation = LocationModel(
        latitude: locationInfo['currentGpsLocation']['latitude'],
        longitude: locationInfo['currentGpsLocation']['longitude'],
        source: LocationSource.system,
      );
      animalSightingManager.updateLocation(systemLocation);
      debugPrint('\x1B[35m[LocationScreen] Updated system location: ${systemLocation.latitude}, ${systemLocation.longitude}\x1B[0m');
    }

    if (locationInfo['selectedLocation'] != null) {
      final userLocation = LocationModel(
        latitude: locationInfo['selectedLocation']['latitude'],
        longitude: locationInfo['selectedLocation']['longitude'],
        source: LocationSource.manual,
      );
      animalSightingManager.updateLocation(userLocation);
      debugPrint('\x1B[35m[LocationScreen] Updated user location: ${userLocation.latitude}, ${userLocation.longitude}\x1B[0m');
    }

    // 3. update datetime in the sighting
    if (locationInfo['dateTime'] == null || locationInfo['dateTime']['dateTime'] == null) {
      _pendingSnackBarMessage = 'Selecteer een datum en tijd';
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
      return;
    }

    final dateTimeStr = locationInfo['dateTime']['dateTime'];
    final dateTime = DateTime.parse(dateTimeStr);
    animalSightingManager.updateDateTime(dateTime);
    debugPrint('\x1B[35m[LocationScreen] Updated datetime: $dateTime\x1B[0m');

    // reset map provider state for next run
    mapProvider.resetState();

    // 🔴 4. CRUCIAL STEP FOR R4:
    // Make sure the grouped animal batches from AnimalCounting
    // are copied into currentSighting.animals so the API transformer
    // can build reportOfSighting.involvedAnimals.
    animalSightingManager.syncObservedAnimalsToSighting();
    debugPrint('\x1B[35m[LocationScreen] Synced observed animals into sighting.animals\x1B[0m');

    // 5. re-read the sighting AFTER sync
    final updatedSighting = animalSightingManager.getCurrentanimalSighting();

    // sanity check: we require datetime and at least one animal
    if (updatedSighting!.dateTime == null ||
        updatedSighting.dateTime!.dateTime == null) {
      _pendingSnackBarMessage = 'Datum en tijd zijn verplicht';
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
      return;
    }

    if (updatedSighting.animals == null || updatedSighting.animals!.isEmpty) {
      _pendingSnackBarMessage = 'Voeg eerst een dier toe aan de lijst';
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
      return;
    }

    // 6. build the payload we are about to send
    final apiFormat = SightingApiTransformer.transformForApi(updatedSighting);
    debugPrint('\x1B[35m[LocationScreen] Final API format (detailed):\x1B[0m');
    debugPrint(const JsonEncoder.withIndent('  ').convert(apiFormat));

    // 7. send to backend
    final responseModel = await submitReport(
      animalSightingManager,
      interactionManager,
      context,
    );

    // 8. handle backend result
    if (responseModel != null) {
      if (responseModel.questionnaire.questions == null ||
          responseModel.questionnaire.questions!.isEmpty) {
        debugPrint('\x1B[31m[LocationScreen] Received empty questionnaire\x1B[0m');
        _pendingSnackBarMessage = 'Geen vragen beschikbaar voor deze melding';
        _pendingNavigationScreen = const Rapporteren();
        _pendingRemoveUntil = true;
      } else {
        debugPrint('\x1B[34m[LocationScreen] Received valid questionnaire: ${responseModel.questionnaire.name}\x1B[0m');
        _pendingNavigationScreen = QuestionnaireScreen(
          questionnaire: responseModel.questionnaire,
          interactionID: responseModel.interactionID,
        );
        _pendingRemoveUntil = true;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
    }
  } catch (e, stackTrace) {
    debugPrint('\x1B[31m[LocationScreen] Error: $e\x1B[0m');
    debugPrint('\x1B[31m[LocationScreen] Stack trace: $stackTrace\x1B[0m');
    _pendingSnackBarMessage = 'Er is een fout opgetreden: $e';
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingActions());
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Locatie',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                final navigationManager = context.read<NavigationStateInterface>();
                final appStateProvider = context.read<AppStateProvider>();
                final reportType = appStateProvider.currentReportType;
                
                // For collision flow, go back to collision details screen
                if (reportType == ReportType.verkeersongeval) {
                  navigationManager.pushReplacementBack(context, const CollisionDetailsScreen());
                } else {
                  // For other flows, go back to animal list overview
                  navigationManager.pushReplacementBack(context, AnimalListOverviewScreen());
                }
              },
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Expanded(child: const LocationScreenUIWidget()),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: () {
          final navigationManager = context.read<NavigationStateInterface>();
          final appStateProvider = context.read<AppStateProvider>();
          final reportType = appStateProvider.currentReportType;
          
          // For collision flow, go back to collision details screen
          if (reportType == ReportType.verkeersongeval) {
            navigationManager.pushReplacementBack(context, const CollisionDetailsScreen());
          } else {
            // For other flows, go back to animal list overview
            navigationManager.pushReplacementBack(context, AnimalListOverviewScreen());
          }
        },
        onNextPressed: _handleNextPressed,
        showNextButton: true,
        showBackButton: false,
      ),
    );
  }
}

Future<InteractionResponse?> submitReport(
  AnimalSightingReportingInterface animalSightingManager,
  InteractionInterface interactionManager,
  BuildContext context,
) async {
  try {
    final currentSighting = animalSightingManager.getCurrentanimalSighting();
    if (currentSighting == null) {
      throw StateError('No active animal sighting found');
    }
    
    // Get the current report type from app state
    final appStateProvider = context.read<AppStateProvider>();
    final reportType = appStateProvider.currentReportType;
    
    // Map ReportType to InteractionType
    final interactionType = switch (reportType) {
      ReportType.waarneming => InteractionType.waarneming,
      ReportType.gewasschade => InteractionType.gewasschade,
      ReportType.verkeersongeval => InteractionType.verkeersongeval,
      null => InteractionType.waarneming, // Default fallback
    };
    
    debugPrint('\x1B[36m[LocationScreen] Using report type: $reportType -> interaction type: $interactionType\x1B[0m');
    
    // Build the appropriate report wrapper based on report type
    final dynamic reportWrapper;
    if (interactionType == InteractionType.verkeersongeval) {
      // For vehicle collision, we need to build an AccidentReport
      reportWrapper = _buildAccidentReportFromSighting(currentSighting);
      debugPrint('\x1B[36m[LocationScreen] Built AccidentReport for verkeersongeval\x1B[0m');
    } else {
      // For waarneming (sighting), use the existing wrapper
      reportWrapper = AnimalSightingReportWrapper(currentSighting);
      debugPrint('\x1B[36m[LocationScreen] Built AnimalSightingReportWrapper for waarneming\x1B[0m');
    }
    
    final InteractionResponse? response = await interactionManager.postInteraction(
      reportWrapper,
      interactionType,
    );
    if (response != null) {
      if (response.questionnaire.questions != null && response.questionnaire.questions!.isNotEmpty) {
        debugPrint('\x1B[32m[LocationScreen] Questionnaire has ${response.questionnaire.questions!.length} questions\x1B[0m');
      } else {
        debugPrint('\x1B[33m[LocationScreen] Questionnaire has no questions\x1B[0m');
      }
    }
    return response;
  } catch (e) {
    rethrow;
  }
}

AccidentReport _buildAccidentReportFromSighting(dynamic sighting) {
  // Extract locations
  final systemLocation = sighting.locations!.firstWhere(
    (loc) => loc.source == LocationSource.system,
    orElse: () => throw StateError('System location is required'),
  );
  final manualLocation = sighting.locations!.firstWhere(
    (loc) => loc.source == LocationSource.manual,
    orElse: () => throw StateError('Manual location is required'),
  );

  // Convert locations to ReportLocation format
  final systemReportLocation = ReportLocation(
    latitude: systemLocation.latitude,
    longtitude: systemLocation.longitude,
  );
  final manualReportLocation = ReportLocation(
    latitude: manualLocation.latitude,
    longtitude: manualLocation.longitude,
  );

  // Transform animals to SightedAnimal format (same logic as SightingApiTransformer)
  final List<SightedAnimal> sightedAnimals = [];
  for (final animal in sighting.animals!) {
    final condition = animal.condition?.toString().split('.').last ?? 'other';
    final mappedCondition = _mapCondition(condition);

    for (final genderView in animal.genderViewCounts) {
      final genderString = genderView.gender.toString().split('.').last;
      final sex = _mapSex(genderString);

      void addEntries(int amount, String ageKey) {
        if (amount > 0) {
          final lifeStage = _mapLifeStage(ageKey);
          for (int i = 0; i < amount; i++) {
            sightedAnimals.add(
              SightedAnimal(
                condition: mappedCondition,
                lifeStage: lifeStage,
                sex: sex,
              ),
            );
          }
        }
      }

      addEntries(genderView.viewCount.pasGeborenAmount, 'pasGeborenAmount');
      addEntries(genderView.viewCount.onvolwassenAmount, 'onvolwassenAmount');
      addEntries(genderView.viewCount.volwassenAmount, 'volwassenAmount');
      addEntries(genderView.viewCount.unknownAmount, 'unknownAmount');
    }
  }

  return AccidentReport(
    description: sighting.description ?? '',
    damages: '0', // Default damage value - will be converted to 0 (number) in toJson()
    animals: sightedAnimals,
    suspectedSpeciesID: sighting.animalSelected?.animalId,
    userSelectedLocation: manualReportLocation,
    systemLocation: systemReportLocation,
    userSelectedDateTime: sighting.dateTime?.dateTime,
    systemDateTime: sighting.dateTime?.dateTime ?? DateTime.now(),
    intensity: 'medium', // Default to medium intensity
    urgency: 'medium', // Default to medium urgency
  );
}

String _mapCondition(String condition) {
  switch (condition.toLowerCase()) {
    case 'gezond':
      return 'healthy';
    case 'ziek':
      return 'impaired';
    case 'dood':
      return 'dead';
    default:
      return 'other';
  }
}

String _mapSex(String genderEnum) {
  switch (genderEnum.toLowerCase()) {
    case 'vrouwelijk':
      return 'female';
    case 'mannelijk':
      return 'male';
    case 'onbekend':
    default:
      return 'unknown';
  }
}

String _mapLifeStage(String ageKey) {
  switch (ageKey) {
    case 'pasGeborenAmount':
      return 'infant';
    case 'onvolwassenAmount':
      return 'adolescent';
    case 'volwassenAmount':
      return 'adult';
    case 'unknownAmount':
    default:
      return 'unknown';
  }
}
