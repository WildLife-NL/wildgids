import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';

import 'package:wildgids/screens/waarneming/animal_counting_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/widgets/animals/scrollable_animal_grid.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<String> _categories = const [];
  String _selectedCategory = 'Alle';

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
    // Ensure search is reset when (re)entering this screen
    _searchController.text = '';
    _searchController.addListener(() => setState(() {}));
    _animalManager.updateSearchTerm('');
    _animalManager.addListener(_handleStateChange);
    _validateAndLoad();
    _loadCategories();
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

      final animals = await _animalManager.getAnimalsByBackendCategory(
        category: _selectedCategory == 'Alle' ? null : _selectedCategory,
      );

      // Filter out the placeholder/unknown entry from the selection list
      final filtered = animals.where((a) {
        final name = a.animalName.trim().toLowerCase();
        final id = (a.animalId ?? '').trim().toLowerCase();
        return name != 'onbekend' && id != 'unknown';
      }).toList();

      debugPrint(
        '[AnimalsScreen] Successfully loaded ${animals.length} animals (showing ${filtered.length} after filtering unknown)',
      );

      if (mounted) {
        setState(() {
          _animals = filtered;
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
    _searchController.dispose();
    // Remove listener BEFORE clearing search term to prevent setState on disposed widget
    _animalManager.removeListener(_handleStateChange);
    // Clear any lingering search term so future visits show all animals
    _animalManager.updateSearchTerm('');
    super.dispose();
  }

  void _handleStateChange() {
    if (mounted) {
      _loadAnimals();
    }
  }

  // _toggleExpanded removed â€” dropdown replaced by custom filter UI

  void _handleAnimalSelection(AnimalModel selectedAnimal) {
    _animalSightingManager.processAnimalSelection(
      selectedAnimal,
      _animalManager,
    );

    _navigationManager.pushForward(context, AnimalCountingScreen());
  }

  void _handleBackNavigation() {
    debugPrint('[AnimalsScreen] Back button pressed');
    // Reset search before navigating back
    _animalManager.updateSearchTerm('');
    // Prefer popping; if stack was cleared, reset to home to avoid a blank screen
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      _navigationManager.resetToHome(context);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _animalManager.getBackendCategories();
      if (!mounted) return;
      setState(() {
        _categories = ['Alle', ...cats];
      });
    } catch (e) {
      // Keep empty list on failure
    }
  }

  @override
  Widget build(BuildContext context) {
    // dropdownInterface removed - using custom search/filter UI instead

    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: null,
              centerText: widget.appBarTitle,
              // no right icon here so the user/profile icon is shown like Rapporteren
              rightIcon: null,
              showUserIcon: true,
              useFixedText: true,
              onLeftIconPressed: _handleBackNavigation,
              // match Rapporteren app bar styling exactly
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  // Category filter dropdown (compact)
                  Container(
                    height: 44,
                    constraints: const BoxConstraints(
                      minWidth: 140,
                      maxWidth: 220,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.darkGreen,
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isDense: true,
                        iconSize: 18,
                        value: _selectedCategory,
                        items:
                            _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Tooltip(
                                      message: c,
                                      waitDuration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      child: Text(
                                        c,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        selectedItemBuilder:
                            (ctx) =>
                                _categories
                                    .map(
                                      (c) => Align(
                                        alignment: Alignment.centerLeft,
                                        child: Tooltip(
                                          message: c,
                                          waitDuration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          child: Text(
                                            c,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                        onChanged: (val) async {
                          if (val == null) return;
                          setState(() => _selectedCategory = val);
                          await _loadAnimals();
                        },
                        isExpanded: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Search box (compact) â€” fits same row
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lightMintGreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.darkGreen,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.darkGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Zoeken',
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                suffixIcon:
                                    (_searchController.text.isNotEmpty)
                                        ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            color: AppColors.darkGreen,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            _animalManager.updateSearchTerm('');
                                            setState(() {});
                                          },
                                        )
                                        : null,
                              ),
                              onChanged: (val) {
                                _animalManager.updateSearchTerm(val);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ScrollableAnimalGrid(
                animals: _animals, // Pass directly without the ?? []
                isLoading: _isLoading,
                error: _error,
                scrollController: _scrollController,
                onAnimalSelected: _handleAnimalSelection,
                onRetry: _loadAnimals,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: _handleBackNavigation,
        onNextPressed: null,
        showNextButton: false,
        showBackButton: true,
      ),
    );
  }
}

