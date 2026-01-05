import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/other/permission_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/screens/waarneming/animal_counting_screen.dart';
import 'package:wildgids/screens/location/location_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildgids/widgets/animals/animal_list_table.dart';
// Removed AppStateProvider import as collision flow is discontinued

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
              leftIcon: null,
              centerText: 'Waarneming',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                // Clear only remarks field when leaving overview
                _animalListTableKey.currentState?.clearRemarksOnly();
                final navigationManager =
                    context.read<NavigationStateInterface>();
                // Go back to counting without wiping the stack
                navigationManager.pushReplacementBack(
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
          _animalListTableKey.currentState?.clearRemarksOnly();
          // Go back to counting without removing prior routes
          navigationManager.pushReplacementBack(
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
          // App state not needed for flow selection anymore

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
            // Navigate directly to location screen for sightings
            navigationManager.pushReplacementForward(
              context,
              const LocationScreen(),
            );
          }
        },
        showNextButton: true,
        showBackButton: true,
      ),
    );
  }
}

