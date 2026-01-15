import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';

import 'package:wildgids/screens/shared/overzicht_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildgids/widgets/location/invisible_map_preloader.dart'; // âœ… import preloader
import 'package:wildgids/widgets/location/selection_button_group.dart';

class AnimalConditionScreen extends StatefulWidget {
  const AnimalConditionScreen({super.key});

  @override
  State<AnimalConditionScreen> createState() => _AnimalConditionScreenState();
}

class _AnimalConditionScreenState extends State<AnimalConditionScreen> {
  bool isLoading = false;

  void _handleStatusSelection(BuildContext context, String status) {
    final greenLog = '\x1B[32m';
    final resetLog = '\x1B[0m';

    setState(() {
      isLoading = true;
    });

    debugPrint(
      '$greenLog[AnimalConditionScreen] Handling status selection: $status$resetLog',
    );

    try {
      // Skip condition update since we removed that functionality
      debugPrint(
        '$greenLog[AnimalConditionScreen] Selected condition: $status (not applied)$resetLog',
      );

      final navigationManager = context.read<NavigationStateInterface>();
      // Navigate back to previous screen
      navigationManager.pushReplacementBack(
        context,
        const AnimalConditionScreen(),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint(
        '$greenLog[AnimalConditionScreen] Error during navigation: $e$resetLog',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Er is een fout opgetreden bij het navigeren'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                CustomAppBar(
                  leftIcon: null,
                  centerText: "Selecteer de conditie van het dier",
                  rightIcon: Icons.menu,
                  onLeftIconPressed: () {
                    // Handle back navigation
                  },
                  onRightIconPressed: () {
                    // Handle menu
                  },
                ),
                SelectionButtonGroup(
                  buttons: const [
                    (text: 'Gezond', icon: Icons.check_circle, imagePath: null),
                    (text: 'Ziek', icon: Icons.sick, imagePath: null),
                    (text: 'Dood', icon: Icons.dangerous, imagePath: null),
                    (text: 'Andere', icon: Icons.more_horiz, imagePath: null),
                  ],
                  onStatusSelected:
                      (status) => _handleStatusSelection(context, status),
                  title: 'Selecteer de conditie van het dier',
                ),
              ],
            ),
          ),
          const InvisibleMapPreloader(), // Add map preloader widget
          if (isLoading) // Use a properly defined variable
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: () {
          // Handle back navigation
          final navigationManager = context.read<NavigationStateInterface>();
          navigationManager.pushReplacementBack(
            context,
            const OverzichtScreen(),
          ); // Adjust destination as needed
        },
        onNextPressed: null,
        showNextButton: false,
        showBackButton: true,
      ),
    );
  }
}

