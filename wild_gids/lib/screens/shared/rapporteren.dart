import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgets/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:widgets/interfaces/state/navigation_state_interface.dart';
import 'package:widgets/models/enums/report_type.dart';
import 'package:widgets/providers/app_state_provider.dart';
import 'package:widgets/providers/map_provider.dart';
import 'package:widgets/screens/waarneming/animals_screen.dart';
import 'package:widgets/screens/shared/category_screen.dart';
import 'package:widgets/screens/shared/overzicht_screen.dart';
import 'package:widgets/screens/belonging/belonging_damages_screen.dart';
import 'package:widgets/widgets/shared_ui_widgets/app_bar.dart';
import 'package:widgets/widgets/location/invisible_map_preloader.dart';
import 'package:widgets/widgets/questionnaire/report_button.dart';

class Rapporteren extends StatefulWidget {
  const Rapporteren({super.key});

  @override
  State<Rapporteren> createState() => _RapporterenState();
}

class _RapporterenState extends State<Rapporteren> {
  String selectedCategory = '';

  void _handleReportTypeSelection(String reportType) {
    final navigationManager = context.read<NavigationStateInterface>();
    final appStateProvider = context.read<AppStateProvider>();

    Widget nextScreen;
    ReportType selectedReportType;

    switch (reportType) {
      case 'animalSightingen':
        debugPrint('[Rapporteren] Animal sighting selected, initializing map');
        selectedReportType = ReportType.waarneming;
        // Create animal sighting report and save it in provider
        final animalSightingManager =
            context.read<AnimalSightingReportingInterface>();
        animalSightingManager.createanimalSighting();
        // Skip condition screen and go directly to category screen
        nextScreen = const CategoryScreen();
        _initializeMapInBackground();
        break;
      case 'Gewasschade':
        debugPrint('[Rapporteren] Gewasschade selected, initializing map');
        selectedReportType = ReportType.gewasschade;
        nextScreen = BelongingDamagesScreen();
        _initializeMapInBackground();
        break;
      case 'Verkeersongeval':
        debugPrint('[Rapporteren] Verkeersongeval selected, initializing map');
        selectedReportType = ReportType.verkeersongeval;
        // Create animal sighting report and save it in provider
        final animalSightingManagerVerkeer =
            context.read<AnimalSightingReportingInterface>();
        animalSightingManagerVerkeer.createanimalSighting();
        // Skip condition screen and go directly to category screen
        nextScreen = const CategoryScreen();
        _initializeMapInBackground();
        break;
      case 'Diergezondheid':
        debugPrint('[Rapporteren] Diergezondheid selected, initializing map');
        selectedReportType = ReportType.verkeersongeval;
        nextScreen = AnimalsScreen(appBarTitle: reportType);
        _initializeMapInBackground();
        break;
      default:
        throw Exception('Unknown report type: $reportType');
    }

    // Initialize the report in the app state
    appStateProvider.initializeReport(selectedReportType);

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
    final screenSize = MediaQuery.of(context).size;
    final double verticalPadding = screenSize.height * 0.01;
    final double horizontalPadding = screenSize.width * 0.05;
    context.read<NavigationStateInterface>();

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Rapporteren',
              rightIcon: Icons.menu,
              onLeftIconPressed: () => _handleBackNavigation(context),
              onRightIconPressed: () {},
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ReportButton(
                              image: 'assets/icons/rapporteren/crop_icon.png',
                              text: 'Gewasschade',
                              onPressed:
                                  () =>
                                      _handleReportTypeSelection('Gewasschade'),
                            ),
                          ),
                          SizedBox(width: screenSize.width * 0.02),
                          Expanded(
                            child: ReportButton(
                              image: 'assets/icons/rapporteren/health_icon.png',
                              text: 'Diergezondheid',
                              onPressed:
                                  () => _handleReportTypeSelection(
                                    'Diergezondheid',
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenSize.height * 0.02),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ReportButton(
                              image:
                                  'assets/icons/rapporteren/sighting_icon.png',
                              text: 'Waarnemingen',
                              onPressed:
                                  () => _handleReportTypeSelection(
                                    'animalSightingen',
                                  ),
                            ),
                          ),
                          SizedBox(width: screenSize.width * 0.02),
                          Expanded(
                            child: ReportButton(
                              image:
                                  'assets/icons/rapporteren/accident_icon.png',
                              text: 'Verkeersongeval',
                              onPressed:
                                  () => _handleReportTypeSelection(
                                    'Verkeersongeval',
                                  ),
                            ),
                          ),
                        ],
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
