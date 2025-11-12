import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/screens/waarneming/animal_counting_screen.dart';
import 'package:wildrapport/screens/waarneming/collision_details_screen.dart';
import 'package:wildrapport/screens/location/location_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/widgets/animals/animal_list_table.dart';
import 'package:wildrapport/providers/app_state_provider.dart';
import 'package:wildrapport/models/enums/report_type.dart';

class AnimalListOverviewScreen extends StatelessWidget {
  AnimalListOverviewScreen({super.key});

  final _animalListTableKey = GlobalKey<AnimalListTableState>();

  @override
  Widget build(BuildContext context) {
    final animalSightingManager =
        context.read<AnimalSightingReportingInterface>();
    animalSightingManager.getCurrentanimalSighting();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Waarneming',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                final navigationManager =
                    context.read<NavigationStateInterface>();
                navigationManager.pushAndRemoveUntil(
                  context,
                  const AnimalCountingScreen(),
                );
              },
              // Match the other screens: black icons/text and slightly larger font/icon scales
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            const SizedBox(height: 34),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Het overzicht',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _animalListTableKey.currentState?.toggleEditMode();
                          },
                          child: Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: AnimalListTable(key: _animalListTableKey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: () {
          final navigationManager = context.read<NavigationStateInterface>();
          navigationManager.pushAndRemoveUntil(
            context,
            const AnimalCountingScreen(),
          );
        },
        onNextPressed: () async {
          // Save any pending changes before navigation
          _animalListTableKey.currentState?.saveChanges();

          final permissionManager = context.read<PermissionInterface>();
          final navigationManager = context.read<NavigationStateInterface>();
          final animalSightingManager =
              context.read<AnimalSightingReportingInterface>();
          final appStateProvider = context.read<AppStateProvider>();

          // Get the description from AnimalListTable
          final description =
              _animalListTableKey.currentState?.getDescription() ?? '';
          animalSightingManager.updateDescription(description);

          final currentSighting =
              animalSightingManager.getCurrentanimalSighting();
          debugPrint(
            '[AnimalListOverviewScreen] Current animal sighting state: ${currentSighting?.toJson()}',
          );

          final hasPermission = await permissionManager.isPermissionGranted(
            PermissionType.location,
          );
          debugPrint(
            '[AnimalListOverviewScreen] Location permission status: $hasPermission',
          );

          if (context.mounted) {
            // Check if this is a collision report (verkeersongeval)
            final isCollision = appStateProvider.currentReportType == ReportType.verkeersongeval;
            debugPrint(
              '[AnimalListOverviewScreen] Report type: ${appStateProvider.currentReportType}, isCollision: $isCollision',
            );

            if (isCollision) {
              // Navigate to collision details screen for traffic accidents
              navigationManager.pushReplacementForward(
                context,
                const CollisionDetailsScreen(),
              );
            } else {
              // Navigate directly to location screen for regular sightings
              navigationManager.pushReplacementForward(
                context,
                const LocationScreen(),
              );
            }
          }
        },
        showBackButton: false,
        showNextButton: true,
      ),
    );
  }
}