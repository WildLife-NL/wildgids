import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/screens/waarneming/animal_list_overview_screen.dart';
import 'package:wildrapport/screens/waarneming/animals_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/widgets/animals/animal_counting.dart';

class AnimalCountingScreen extends StatefulWidget {
  const AnimalCountingScreen({super.key});

  @override
  State<AnimalCountingScreen> createState() => _AnimalCountingScreenState();
}

class _AnimalCountingScreenState extends State<AnimalCountingScreen> {
  bool _hasAddedItems = false;

  @override
  void initState() {
    super.initState();
    // Check if there are already animals in the list when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForExistingAnimals();
    });
  }

  void _checkForExistingAnimals() {
    final animalSightingManager =
        context.read<AnimalSightingReportingInterface>();
    final currentSighting = animalSightingManager.getCurrentanimalSighting();

    // Consider entries already added to the sighting OR counts on the currently selected animal
    final hasFinalizedAnimals =
        (currentSighting?.animals?.isNotEmpty ?? false);

    final hasCountsOnSelected = currentSighting?.animalSelected != null &&
        currentSighting!.animalSelected!.genderViewCounts.any(
          (gvc) =>
              gvc.viewCount.pasGeborenAmount > 0 ||
              gvc.viewCount.onvolwassenAmount > 0 ||
              gvc.viewCount.volwassenAmount > 0 ||
              gvc.viewCount.unknownAmount > 0,
        );

    if (hasFinalizedAnimals || hasCountsOnSelected) {
      setState(() {
        _hasAddedItems = true;
      });
    }
  }

  void _handleBackNavigation(BuildContext context) {
    // Go back to animals screen, keeping all added animals
    final navigationManager = context.read<NavigationStateInterface>();
    navigationManager.pushReplacementBack(
      context,
      const AnimalsScreen(appBarTitle: 'Selecteer Dier'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: null,
              centerText: 'Telling toevoegen',
              // Show the profile/user icon on the right (like other screens)
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () => _handleBackNavigation(context),
              // Match the other screens: black icons/text and slightly larger font/icon scales
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            // Add extra spacing between the app bar and the category selectors
            const SizedBox(height: 34),
            Expanded(
              child: Center(
                child: AnimalCounting(
                  onAddToList: () {
                    setState(() {
                      _hasAddedItems = true;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: () => _handleBackNavigation(context),
        onNextPressed: () {
          final navigationManager = context.read<NavigationStateInterface>();
          navigationManager.pushReplacementForward(
            context,
            // Ensure remarks start empty when entering overview
            AnimalListOverviewScreen(),
          );
        },
        // Allow going back to species selection at all times
        showNextButton: _hasAddedItems,
        showBackButton: true,
      ),
    );
  }
}
