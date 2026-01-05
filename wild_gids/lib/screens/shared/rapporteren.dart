import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/models/enums/report_type.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/providers/map_provider.dart';

import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/screens/waarneming/animals_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/location/invisible_map_preloader.dart';
import 'package:wildrapport/widgets/questionnaire/report_button.dart';
import 'package:wildrapport/managers/api_managers/interaction_types_manager.dart';
import 'package:wildrapport/models/api_models/interaction_type.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

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
      _loadInteractionTypes();
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
    final Widget nextScreen = const AnimalsScreen(appBarTitle: 'Selecteer Dier');
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
    final responsive = context.responsive;
    context.read<NavigationStateInterface>();

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: CustomAppBar(
              leftIcon: Icons.arrow_back_ios_new,
              centerText: 'Rapporteren',
              rightIcon: null,
              showUserIcon: true,
              useFixedText: true,
              onLeftIconPressed: () => _handleBackNavigation(context),
              onRightIconPressed: () {},
              // make title and arrow black and larger for this screen - more on smaller screens
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: responsive.breakpointValue<double>(
                small: 1.4,
                medium: 1.3,
                large: 1.2,
                extraLarge: 1.15,
              ),
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.wp(5),
                  vertical: responsive.hp(1),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _interactionTypes == null ||
                                  _interactionTypes!.isEmpty
                              ? Center(
                                child: Text(
                                  'Geen interactietypen beschikbaar',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(16),
                                  ),
                                ),
                              )
                              : Center(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                      _interactionTypes!
                                        .where((type) {
                                          final typeName = type.name.toLowerCase();
                                          return typeName == 'waarneming' ||
                                            typeName.contains('sighting');
                                        })
                                        .map((type) {
                                          // Map interaction types to appropriate icons
                                          // Only show waarneming icon
                                          final String icon = 'assets/icons/binoculars.png';

                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: responsive.hp(3),
                                            ),
                                            child: SizedBox(
                                              width: responsive.wp(90),
                                              height: responsive.hp(22),
                                              child: ReportButton(
                                                image: icon,
                                                text: type.name,
                                                onPressed:
                                                    () =>
                                                        _handleReportTypeSelection(
                                                          type,
                                                        ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
