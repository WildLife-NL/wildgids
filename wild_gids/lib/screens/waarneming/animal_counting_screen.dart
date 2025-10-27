import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgets/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:widgets/screens/waarneming/animal_list_overview_screen.dart';
import 'package:widgets/screens/waarneming/animals_screen.dart';
import 'package:widgets/widgets/shared_ui_widgets/app_bar.dart';
import 'package:widgets/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:widgets/widgets/animals/animal_counting.dart';

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

    // If there are animals in the list, set _hasAddedItems to true
    if (currentSighting?.animalSelected != null &&
        currentSighting!.animalSelected!.genderViewCounts.any(
          (gvc) =>
              gvc.viewCount.pasGeborenAmount > 0 ||
              gvc.viewCount.onvolwassenAmount > 0 ||
              gvc.viewCount.volwassenAmount > 0 ||
              gvc.viewCount.unknownAmount > 0,
        )) {
      setState(() {
        _hasAddedItems = true;
      });
    }
  }

  void _handleBackNavigation(BuildContext context) {
    if (_hasAddedItems) {
      // Show confirmation dialog if items have been added
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Waarschuwing'),
              content: const Text(
                'Teruggaan zal de toegevoegde dieren verwijderen. Weet je zeker dat je terug wilt gaan?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  child: const Text('Annuleren'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog

                    // Reset the animal counting data
                    final animalSightingManager =
                        context.read<AnimalSightingReportingInterface>();

                    // Create a new animal sighting with empty animals list
                    animalSightingManager.createanimalSighting();

                    // Navigate back to the animal screen by popping until we reach it
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const AnimalsScreen(
                              appBarTitle: 'Selecteer Dier',
                            ),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Ja, ga terug'),
                ),
              ],
            ),
      );
    } else {
      // If no items added, just go back without confirmation
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Telling toevoegen',
              rightIcon: Icons.menu,
              onLeftIconPressed: () => _handleBackNavigation(context),
              onRightIconPressed: () {},
            ),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnimalListOverviewScreen(),
            ),
          );
        },
        showNextButton: _hasAddedItems,
      ),
    );
  }
}
