import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/managers/state_managers/navigation_state_manager.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_sighting_model.dart';
import 'package:wildgids/models/beta_models/interaction_response_model.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/models/walk_recording.dart';
import 'package:wildgids/providers/walk_recorder.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/waarneming/location_selection_screen.dart';

class WalkSightingSession {
  WalkSightingSession({
    required this.walkId,
    required this.recorder,
    required this.close,
  });
  final String walkId;
  final WalkRecorder recorder;
  final VoidCallback close;

  Future<void> submitted(
    AnimalSightingModel sighting,
    InteractionResponse response,
  ) async {
    final locations = sighting.locations;
    if (locations == null || locations.isEmpty) return;
    final location = locations.lastWhere(
      (l) => l.source == LocationSource.manual,
      orElse: () => locations.first,
    );
    if (location.latitude == null || location.longitude == null) return;
    await recorder.addSighting(
      WalkSighting(
        id: response.interactionID,
        name: sighting.animalSelected?.animalName ?? 'Waarneming',
        point: WalkPoint(
          location.latitude!,
          location.longitude!,
          sighting.dateTime?.dateTime ?? DateTime.now(),
        ),
      ),
      walkId: walkId,
    );
  }
}

/// Keeps the existing multi-screen report and questionnaire flow above the map.
class WalkSightingFlow extends StatefulWidget {
  const WalkSightingFlow({
    super.key,
    required this.walkId,
    required this.position,
    required this.startedAt,
  });
  final String walkId;
  final WalkPoint? position;
  final DateTime startedAt;
  @override
  State<WalkSightingFlow> createState() => _WalkSightingFlowState();
}

class _WalkSightingFlowState extends State<WalkSightingFlow> {
  final _navigator = GlobalKey<NavigatorState>();
  late final WalkSightingSession _session;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _session = WalkSightingSession(
      walkId: widget.walkId,
      recorder: context.read<WalkRecorder>(),
      close: _close,
    );
  }

  void _close() {
    if (!mounted || _closing) return;
    _closing = true;
    context
        .read<AnimalSightingReportingInterface>()
        .clearCurrentanimalSighting();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<WalkSightingSession>.value(value: _session),
      Provider<NavigationStateInterface>(
        create: (_) => _WalkSightingNavigation(_close),
      ),
    ],
    child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_navigator.currentState?.canPop() ?? false) {
          _navigator.currentState!.pop();
        } else {
          _close();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ListenableBuilder(
                listenable: _session.recorder,
                builder:
                    (context, _) => Material(
                      color: const Color(0xFFEAF3EC),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          _session.recorder.recording
                              ? Icons.fiber_manual_record
                              : Icons.pause,
                          color: const Color(0xFF00634D),
                          size: 18,
                        ),
                        title: Text(
                          _session.recorder.recording
                              ? 'Wandeling wordt opgenomen'
                              : 'Wandeling gepauzeerd',
                        ),
                        trailing: IconButton(
                          tooltip: 'Terug naar wandeling',
                          onPressed: _close,
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
              ),
              Expanded(
                child: Navigator(
                  key: _navigator,
                  onGenerateRoute:
                      (_) => MaterialPageRoute(
                        builder:
                            (_) => LocationSelectionScreen(
                              initialLocation: widget.position?.latLng,
                              initialDateTime: widget.startedAt,
                              onCancel: _close,
                              freezeInitialLocation: true,
                            ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _WalkSightingNavigation extends NavigationStateManager {
  _WalkSightingNavigation(this.close);
  final VoidCallback close;
  @override
  void resetToHome(BuildContext context) => close();
  @override
  void pushAndRemoveUntil(BuildContext context, Widget screen) {
    if (screen is KaartOverviewScreen) {
      close();
    } else {
      super.pushAndRemoveUntil(context, screen);
    }
  }
}
