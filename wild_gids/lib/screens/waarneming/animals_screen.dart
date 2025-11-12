import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';

import 'package:wildrapport/screens/waarneming/animal_counting_screen.dart';
import 'package:wildrapport/screens/shared/category_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/models/enums/filter_type.dart';
import 'package:wildrapport/widgets/animals/scrollable_animal_grid.dart';

class AnimalsScreen extends StatefulWidget {
  final String appBarTitle;

  const AnimalsScreen({super.key, required this.appBarTitle});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimalManagerInterface _animalManager;
  late final AnimalSightingReportingInterface _animalSightingManager;
  late final NavigationStateInterface _navigationManager;
  late final AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  List<AnimalModel>? _animals;
  String? _error;
  bool _isLoading = true;
  // dropdown expansion state no longer used (custom UI)

  @override
  void initState() {
    super.initState();
    debugPrint('[AnimalsScreen] Initializing screen');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Set a default duration
    );
    _animalManager = context.read<AnimalManagerInterface>();
    _animalSightingManager = context.read<AnimalSightingReportingInterface>();
    _navigationManager = context.read<NavigationStateInterface>();
    _animalManager.addListener(_handleStateChange);
    _validateAndLoad();
  }

  void _validateAndLoad() {
    if (!_animalSightingManager.validateActiveAnimalSighting()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geen actieve animalSighting gevonden'),
            backgroundColor: Colors.red,
          ),
        );
      });
      return;
    }
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    debugPrint('[AnimalsScreen] Starting to load animals');
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final selectedCategory = _animalSightingManager.getCurrentanimalSighting()?.category;
      debugPrint('[AnimalsScreen] Selected category used for query: $selectedCategory');

      final animals = await _animalManager.getAnimalsByCategory(
        category: selectedCategory,
      );


      debugPrint(
        '[AnimalsScreen] Successfully loaded ${animals.length} animals',
      );

      if (mounted) {
        setState(() {
          _animals = animals;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[AnimalsScreen] ERROR: Failed to load animals');
      debugPrint('[AnimalsScreen] Error details: $e');
      debugPrint('[AnimalsScreen] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    debugPrint('[AnimalsScreen] Disposing screen');
    _scrollController.dispose();
    _animationController.dispose();
    _animalManager.removeListener(_handleStateChange);
    super.dispose();
  }

  void _handleStateChange() {
    if (mounted) {
      _loadAnimals();
    }
  }

  // _toggleExpanded removed — dropdown replaced by custom filter UI

  void _handleAnimalSelection(AnimalModel selectedAnimal) {
    _animalSightingManager.processAnimalSelection(
      selectedAnimal,
      _animalManager,
    );

    _navigationManager.pushForward(context, AnimalCountingScreen());
  }

  void _handleBackNavigation() {
    debugPrint('[AnimalsScreen] Back button pressed');
    // Do not dispose the navigation manager here — keep shared state alive for previous flow
    _navigationManager.pushReplacementBack(context, const CategoryScreen());
  }

  @override
  Widget build(BuildContext context) {
  // dropdownInterface removed - using custom search/filter UI instead

    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: widget.appBarTitle,
              // no right icon here so the user/profile icon is shown like Rapporteren
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: _handleBackNavigation,
              // match Rapporteren app bar styling exactly
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Padding(
              // increase vertical padding to move elements slightly down
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                children: [
                  // Search box (larger) — use same mint background as page, no shadow
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.lightMintGreen,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.darkGreen, width: 1.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.darkGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'zoeken',
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (val) {
                              _animalManager.updateSearchTerm(val);
                              // trigger immediate UI refresh
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Filter pills (moved down, slightly larger)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _animalManager.updateFilter(FilterType.mostViewed.displayText);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _animalManager.getSelectedFilter() == FilterType.mostViewed.displayText
                                  ? AppColors.darkGreen
                                  : AppColors.lightMintGreen,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: AppColors.darkGreen, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                'Meest gezien',
                                style: TextStyle(
                                  color: _animalManager.getSelectedFilter() == FilterType.mostViewed.displayText
                                      ? Colors.white
                                      : AppColors.darkGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _animalManager.updateFilter(FilterType.alphabetical.displayText);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _animalManager.getSelectedFilter() == FilterType.alphabetical.displayText
                                  ? AppColors.darkGreen
                                  : AppColors.lightMintGreen,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: AppColors.darkGreen, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                'A-Z',
                                style: TextStyle(
                                  color: _animalManager.getSelectedFilter() == FilterType.alphabetical.displayText
                                      ? Colors.white
                                      : AppColors.darkGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ScrollableAnimalGrid(
              animals: _animals, // Pass directly without the ?? []
              isLoading: _isLoading,
              error: _error,
              scrollController: _scrollController,
              onAnimalSelected: _handleAnimalSelection,
              onRetry: _loadAnimals,
            ),
          ],
        ),
      ),
    );
  }
}
