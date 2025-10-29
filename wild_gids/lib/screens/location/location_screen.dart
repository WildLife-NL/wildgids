import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/interfaces/reporting/interaction_interface.dart';
import 'package:wildrapport/interfaces/location/location_screen_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/managers/map/location_screen_manager.dart';
import 'package:wildrapport/models/beta_models/animal_sighting_report_wrapper.dart';
import 'package:wildrapport/models/beta_models/interaction_response_model.dart';
import 'package:wildrapport/models/enums/date_time_type.dart';
import 'package:wildrapport/models/enums/interaction_type.dart';
import 'package:wildrapport/models/enums/report_type.dart';
import 'package:wildrapport/models/enums/location_source.dart';
import 'package:wildrapport/models/beta_models/location_model.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/screens/waarneming/animal_list_overview_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Locatie',
              rightIcon: Icons.menu,
              onLeftIconPressed: () => context
                  .read<NavigationStateInterface>()
                  .pushReplacementBack(context, const Rapporteren()),
              onRightIconPressed: () {
                /* Handle menu */
              },
            ),
            Expanded(child: const LocationScreenUIWidget()),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: CustomBottomAppBar(
          onBackPressed: () async {
            final locationManager = context.read<LocationScreenInterface>();
            final animalSightingManager = context.read<AnimalSightingReportingInterface>();
            try {
              final locationInfo = await locationManager.getLocationAndDateTime(context);
              if (locationInfo['dateTime'] != null && locationInfo['dateTime']['dateTime'] != null) {
                final dateTimeStr = locationInfo['dateTime']['dateTime'];
                final dateTime = DateTime.parse(dateTimeStr);
                animalSightingManager.updateDateTime(dateTime);
                if (locationManager is LocationScreenManager) {
                  final dateTimeType = locationInfo['dateTime']['type'];
                  if (dateTimeType == 'current') {
                    locationManager.updateDateTime(DateTimeType.current.displayText);
                  } else if (dateTimeType == 'unknown') {
                    locationManager.updateDateTime(DateTimeType.unknown.displayText);
                  } else if (dateTimeType == 'custom') {
                    locationManager.updateDateTime(DateTimeType.custom.displayText, date: dateTime);
                  }
                }
              }
              if (locationInfo['selectedLocation'] != null) {
                final userLocation = LocationModel(
                  latitude: locationInfo['selectedLocation']['latitude'],
                  longitude: locationInfo['selectedLocation']['longitude'],
                  source: LocationSource.manual,
                );
                animalSightingManager.updateLocation(userLocation);
              }
            } catch (e) {
              debugPrint('\x1B[31m[LocationScreen] Error saving state before navigation: $e\x1B[0m');
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<NavigationStateInterface>().pushReplacementBack(
                context,
                AnimalListOverviewScreen(),
              );
            });
          },
onNextPressed: () async {
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
},

          showNextButton: true,
          showBackButton: true,
        ),
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
    
    final InteractionResponse? response = await interactionManager.postInteraction(
      AnimalSightingReportWrapper(currentSighting),
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