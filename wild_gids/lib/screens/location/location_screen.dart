import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/reporting/interaction_interface.dart';
import 'package:wildgids/interfaces/location/location_screen_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/beta_models/animal_sighting_report_wrapper.dart';
// Removed collision/damage report models as those flows are deprecated
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/enums/interaction_type.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/models/beta_models/location_model.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/waarneming/animal_list_overview_screen.dart';
// Removed collision details screen import (flow deprecated)
import 'package:wildgids/screens/questionnaire/questionnaire_screen.dart';
import 'package:wildgids/screens/shared/overzicht_screen.dart';
import 'package:wildgids/utils/sighting_api_transformer.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildgids/widgets/location/location_screen_ui_widget.dart';
import 'package:wildgids/utils/toast_notification_handler.dart';

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
      ToastNotificationHandler.sendToastNotification(
        context,
        _pendingSnackBarMessage!,
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
    final animalSightingManager =
        context.read<AnimalSightingReportingInterface>();
    final locationManager = context.read<LocationScreenInterface>();
    final interactionManager = context.read<InteractionInterface>();
    final mapProvider = context.read<MapProvider>();

    try {
      debugPrint(
        '\x1B[35m[LocationScreen] Starting location update process\x1B[0m',
      );

      final locationInfo = await locationManager.getLocationAndDateTime(
        context,
      );
      debugPrint('\x1B[35m[LocationScreen] LocationInfo: $locationInfo\x1B[0m');

      // 1. Require a location source: either user-selected OR current GPS
      final hasUserSelection = locationInfo['selectedLocation'] != null;
      final hasCurrentGps = locationInfo['currentGpsLocation'] != null;
      if (!hasUserSelection && !hasCurrentGps) {
        _pendingSnackBarMessage = 'Locatie niet beschikbaar. Schakel locatie in.';
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handlePendingActions(),
        );
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
        debugPrint(
          '\x1B[35m[LocationScreen] Updated system location: ${systemLocation.latitude}, ${systemLocation.longitude}\x1B[0m',
        );
      }

      if (hasUserSelection) {
        final userLocation = LocationModel(
          latitude: locationInfo['selectedLocation']['latitude'],
          longitude: locationInfo['selectedLocation']['longitude'],
          source: LocationSource.manual,
        );
        animalSightingManager.updateLocation(userLocation);
        debugPrint(
          '\x1B[35m[LocationScreen] Updated user location: ${userLocation.latitude}, ${userLocation.longitude}\x1B[0m',
        );
      } else if (hasCurrentGps) {
        // No manual selection: default manual to current GPS so API has both
        final userLocation = LocationModel(
          latitude: locationInfo['currentGpsLocation']['latitude'],
          longitude: locationInfo['currentGpsLocation']['longitude'],
          source: LocationSource.manual,
        );
        animalSightingManager.updateLocation(userLocation);
        debugPrint(
          '\x1B[35m[LocationScreen] Defaulted manual location to current GPS\x1B[0m',
        );
      }

      // 3. update datetime in the sighting
      if (locationInfo['dateTime'] == null ||
          locationInfo['dateTime']['dateTime'] == null) {
        _pendingSnackBarMessage = 'Selecteer een datum en tijd';
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handlePendingActions(),
        );
        return;
      }

      final dateTimeStr = locationInfo['dateTime']['dateTime'];
      final dateTime = DateTime.parse(dateTimeStr);
      animalSightingManager.updateDateTime(dateTime);
      debugPrint('\x1B[35m[LocationScreen] Updated datetime: $dateTime\x1B[0m');

      // reset map provider state for next run
      mapProvider.resetState();

      // ðŸ”´ 4. CRUCIAL STEP FOR R4:
      // Make sure the grouped animal batches from AnimalCounting
      // are copied into currentSighting.animals so the API transformer
      // can build reportOfSighting.involvedAnimals.
      animalSightingManager.syncObservedAnimalsToSighting();
      debugPrint(
        '\x1B[35m[LocationScreen] Synced observed animals into sighting.animals\x1B[0m',
      );

      // 5. re-read the sighting AFTER sync
      final updatedSighting = animalSightingManager.getCurrentanimalSighting();

      // sanity check: we require datetime and at least one animal
      if (updatedSighting!.dateTime == null ||
          updatedSighting.dateTime!.dateTime == null) {
        _pendingSnackBarMessage = 'Datum en tijd zijn verplicht';
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handlePendingActions(),
        );
        return;
      }

      if (updatedSighting.animals == null || updatedSighting.animals!.isEmpty) {
        _pendingSnackBarMessage = 'Voeg eerst een dier toe aan de lijst';
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handlePendingActions(),
        );
        return;
      }

      // 6. build the payload we are about to send
      final apiFormat = SightingApiTransformer.transformForApi(updatedSighting);
      debugPrint(
        '\x1B[35m[LocationScreen] Final API format (detailed):\x1B[0m',
      );
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
          debugPrint(
            '\x1B[33m[LocationScreen] No questionnaire returned, skipping questionnaire screen\x1B[0m',
          );
          _pendingSnackBarMessage = 'Melding succesvol verstuurd';
          _pendingNavigationScreen = const OverzichtScreen();
          _pendingRemoveUntil = true;
        } else {
          debugPrint(
            '\x1B[34m[LocationScreen] Received valid questionnaire: ${responseModel.questionnaire.name}\x1B[0m',
          );
          _pendingNavigationScreen = QuestionnaireScreen(
            questionnaire: responseModel.questionnaire,
            interactionID: responseModel.interactionID,
          );
          _pendingRemoveUntil = true;
        }

        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handlePendingActions(),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('\x1B[31m[LocationScreen] Error: $e\x1B[0m');
      debugPrint('\x1B[31m[LocationScreen] Stack trace: $stackTrace\x1B[0m');
      _pendingSnackBarMessage = 'Er is een fout opgetreden: $e';
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handlePendingActions(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: null,
              centerText: 'Locatie',
              rightIcon: null,
              showUserIcon: true,
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
          // Always go back to animal list overview for waarneming flow
          final animalSightingManager =
              context.read<AnimalSightingReportingInterface>();
          animalSightingManager.updateDescription('');
          navigationManager.pushReplacementBack(
            context,
            AnimalListOverviewScreen(),
          );
        },
        onNextPressed: _handleNextPressed,
        showNextButton: true,
        showBackButton: true,
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

    // Only waarneming is supported
    final interactionType = InteractionType.waarneming;

    debugPrint(
      '\x1B[36m[LocationScreen] Using interaction type: $interactionType\x1B[0m',
    );

    // For waarneming (sighting), use the existing wrapper
    final reportWrapper = AnimalSightingReportWrapper(currentSighting);
    debugPrint(
      '\x1B[36m[LocationScreen] Built AnimalSightingReportWrapper for waarneming\x1B[0m',
    );

    final InteractionResponse? response = await interactionManager
        .postInteraction(reportWrapper, interactionType);
    if (response != null) {
      if (response.questionnaire.questions != null &&
          response.questionnaire.questions!.isNotEmpty) {
        debugPrint(
          '\x1B[32m[LocationScreen] Questionnaire has ${response.questionnaire.questions!.length} questions\x1B[0m',
        );
      } else {
        debugPrint(
          '\x1B[33m[LocationScreen] Questionnaire has no questions\x1B[0m',
        );
      }
    }
    return response;
  } catch (e) {
    rethrow;
  }
}

// Collision flow removed; only waarneming reporting is supported.

