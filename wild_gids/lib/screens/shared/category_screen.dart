import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widgets/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:widgets/widgets/shared_ui_widgets/app_bar.dart';
import 'package:widgets/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:widgets/widgets/location/selection_button_group.dart';
import 'package:widgets/screens/waarneming/animals_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late final AnimalSightingReportingInterface _animalSightingManager;
  bool _isLoading = false;
  final purpleLog = '\x1B[35m';
  final resetLog = '\x1B[0m';

  @override
  void initState() {
    super.initState();
    debugPrint('$purpleLog[CategoryScreen] Initializing screen$resetLog');
    _animalSightingManager = context.read<AnimalSightingReportingInterface>();

    var currentState = _animalSightingManager.getCurrentanimalSighting();
    if (currentState == null) {
      debugPrint(
        '$purpleLog[CategoryScreen] No existing sighting, creating a new one$resetLog',
      );
      currentState = _animalSightingManager.createanimalSighting();
    }
    debugPrint(
      '$purpleLog[CategoryScreen] Initial animal sighting state: ${currentState.toJson()}$resetLog',
    );
  }

  void _handleBackNavigation() {
    if (!mounted) return;

    // Clear the animal sighting data
    _animalSightingManager.clearCurrentanimalSighting();

    // Navigate back to login/home
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _handleStatusSelection(BuildContext context, String status) {
    if (!mounted) return;
    try {
      setState(() => _isLoading = true);

      final selectedCategory = _animalSightingManager.convertStringToCategory(
        status,
      );
      _animalSightingManager.updateCategory(selectedCategory);

      if (mounted) {
        // Navigate to AnimalsScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AnimalsScreen(appBarTitle: 'Selecteer Dier'),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '$purpleLog[CategoryScreen] Error updating category: $e$resetLog',
      );
      if (mounted) {
        // Check if still mounted before showing snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Er is een fout opgetreden bij het bijwerken van de categorie',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Hide loading indicator
      }
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
                  leftIcon: Icons.arrow_back_ios,
                  centerText: 'animalSightingen',
                  rightIcon: Icons.menu,
                  onLeftIconPressed: _handleBackNavigation,
                  onRightIconPressed: () {
                    debugPrint(
                      '$purpleLog[CategoryScreen] Menu button pressed$resetLog',
                    );
                  },
                ),
                SelectionButtonGroup(
                  buttons: const [
                    (
                      text: 'Evenhoevigen',
                      icon: null,
                      imagePath: 'assets/icons/category/evenhoevigen.png',
                    ),
                    (
                      text: 'Knaagdieren',
                      icon: null,
                      imagePath: 'assets/icons/category/knaagdieren.png',
                    ),
                    (
                      text: 'Roofdieren',
                      icon: null,
                      imagePath: 'assets/icons/category/roofdieren.png',
                    ),
                    (text: 'Andere', icon: Icons.more_horiz, imagePath: null),
                  ],
                  onStatusSelected:
                      (status) => _handleStatusSelection(context, status),
                  title: 'Selecteer Categorie',
                ),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: _handleBackNavigation,
        onNextPressed: () {},
        showNextButton: false,
      ),
    );
  }
}
