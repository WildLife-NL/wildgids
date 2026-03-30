import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';

import 'package:wildgids/screens/shared/overzicht_screen.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/widgets/location/invisible_map_preloader.dart';
import 'package:wildgids/widgets/questionnaire/report_button.dart';
import 'package:wildgids/managers/api_managers/interaction_types_manager.dart';
import 'package:wildgids/models/api_models/interaction_type.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class Rapporteren extends StatefulWidget {
  const Rapporteren({super.key});

  @override
  State<Rapporteren> createState() => _RapporterenState();
}

class _RapporterenState extends State<Rapporteren> {
  String selectedCategory = '';
  List<InteractionType>? _interactionTypes;
  bool _isLoading = true;
  bool _hasLoadedTypes = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedTypes) {
      _hasLoadedTypes = true;
      // Skip directly to waarneming start screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigationManager = context.read<NavigationStateInterface>();
        final appStateProvider = context.read<AppStateProvider>();
        
        // Initialize the report in the app state
        appStateProvider.initializeReport(ReportType.waarneming);
        
        // Navigate directly to waarneming start screen
        navigationManager.pushForward(context, const WaarnemmingStartScreen());
      });
    }
  }

  Future<void> _loadInteractionTypes() async {
    final interactionTypesManager = context.read<InteractionTypesManager>();
    try {
      final types = await interactionTypesManager.ensureFetched();
      debugPrint('[Rapporteren] Loaded ${types.length} interaction types');
      for (final type in types) {
        debugPrint('[Rapporteren]   - ${type.name} (ID: ${type.id})');
      }
      if (mounted) {
        setState(() {
          _interactionTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Rapporteren] Error loading interaction types: $e');
      if (mounted) {
        setState(() {
          _interactionTypes = [];
          _isLoading = false;
        });
      }
    }
  }

  void _handleReportTypeSelection(InteractionType interactionType) {
    final navigationManager = context.read<NavigationStateInterface>();
    final appStateProvider = context.read<AppStateProvider>();

    debugPrint(
      '[Rapporteren] Selected interaction type: ${interactionType.name} (ID: ${interactionType.id})',
    );

    // Only waarneming flow is supported
    final animalSightingManager =
        context.read<AnimalSightingReportingInterface>();
    animalSightingManager.createanimalSighting();
    
    // Navigate to waarneming start screen first
    final Widget nextScreen = const WaarnemmingStartScreen();
    _initializeMapInBackground();

    // Initialize the report in the app state
    appStateProvider.initializeReport(ReportType.waarneming);

    // Use push instead of pushReplacement
    navigationManager.pushForward(context, nextScreen);
  }

  void _initializeMapInBackground() {
    if (!mounted) return;

    final mapProvider = context.read<MapProvider>();
    debugPrint(
      '[Rapporteren] Current map initialization status: ${mapProvider.isInitialized}',
    );

    if (!mapProvider.isInitialized) {
      try {
        const InvisibleMapPreloader();
        debugPrint('[Rapporteren] Invisible map preloader initialized');
      } catch (e) {
        debugPrint(
          '[Rapporteren] Error preloading invisible map: ${e.toString()}',
        );
      }
      debugPrint('[Rapporteren] Starting background map initialization');
      mapProvider
          .initialize()
          .then((_) {
            debugPrint('[Rapporteren] Background map initialization completed');
          })
          .catchError((error) {
            debugPrint(
              '[Rapporteren] Error in background map initialization: $error',
            );
          });
    } else {
      debugPrint('[Rapporteren] Map already initialized, skipping');
    }
  }

  void _handleBackNavigation(BuildContext context) {
    final navigationManager = context.read<NavigationStateInterface>();
    navigationManager.pushAndRemoveUntil(context, const OverzichtScreen());
  }

  @override
  Widget build(BuildContext context) {
    // This screen navigates to WaarnemmingStartScreen immediately
    // Show a simple loading screen while the navigation happens
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

