import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:wildrapport/screens/belonging/belonging_damages_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/widgets/animals/scrollable_animal_grid.dart';

class BelongingAnimalScreen extends StatefulWidget {
  final String appBarTitle;

  const BelongingAnimalScreen({super.key, required this.appBarTitle});

  @override
  State<BelongingAnimalScreen> createState() => _BelongingAnimalScreenState();
}

class _BelongingAnimalScreenState extends State<BelongingAnimalScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late final BelongingDamageReportProvider _belongingDamageReportProvider;
  late final AnimalManagerInterface _animalManager;
  List<AnimalModel> _animals = [];
  bool _isLoading = true;
  String? _pendingSnackBarMessage;
  List<String> _categories = const [];
  String _selectedCategory = 'Alle';

  @override
  void initState() {
    super.initState();
    _belongingDamageReportProvider =
        context.read<BelongingDamageReportProvider>();
    _animalManager = context.read<AnimalManagerInterface>();
    // Ensure search is reset when (re)entering this screen
    _searchController.text = '';
    _searchController.addListener(() => setState(() {}));
    _animalManager.updateSearchTerm('');
    _animalManager.addListener(_handleStateChange);
    _loadAnimals();
    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Clear any lingering search to avoid sticky filtered lists on next visit
    _animalManager.updateSearchTerm('');
    _searchController.dispose();
    _animalManager.removeListener(_handleStateChange);
    super.dispose();
  }

  void _handleStateChange() {
    if (mounted) {
      _loadAnimals();
    }
  }

  Future<void> _loadAnimals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final animals = await _animalManager.getAnimalsByBackendCategory(
        category: _selectedCategory == 'Alle' ? null : _selectedCategory,
      );
      setState(() {
        _animals = animals;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[BelongingAnimalScreen] Error loading animals: $e');
      setState(() {
        _isLoading = false;
      });
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

  void _handlePendingSnackBar() {
    if (_pendingSnackBarMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pendingSnackBarMessage!),
          backgroundColor: Colors.red,
        ),
      );
      _pendingSnackBarMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: null,
              centerText: widget.appBarTitle,
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                debugPrint('[BelongingAnimalScreen] Back button pressed');
                // Reset search before navigating back
                _animalManager.updateSearchTerm('');
                Navigator.pop(context);
              },
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
                  // Category filter dropdown (compact) to match AnimalsScreen
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
                        items: _categories
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
                        selectedItemBuilder: (ctx) => _categories
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
                  // Search box (compact) to match AnimalsScreen
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
                                suffixIcon: (_searchController.text.isNotEmpty)
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
                animals: _animals,
                isLoading: _isLoading,
                scrollController: _scrollController,
                onAnimalSelected: (AnimalModel selectedAnimal) async {
                  debugPrint('[BelongingAnimalScreen] Next button pressed');
                  final permissionManager = context.read<PermissionInterface>();
                  final navigationManager =
                      context.read<NavigationStateInterface>();

                  // Check if location permission is already granted
                  final hasPermission = await permissionManager
                      .isPermissionGranted(PermissionType.location);
                  debugPrint(
                    '[BelongingAnimalScreen] Location permission status: $hasPermission',
                  );

                  if (!hasPermission) {
                    debugPrint(
                      '[BelongingAnimalScreen] Requesting location permission',
                    );
                    bool permissionGranted = false;
                    if (context.mounted) {
                      permissionGranted = await permissionManager
                          .requestPermission(
                            context,
                            PermissionType.location,
                            showRationale: true,
                          );
                    }
                    debugPrint(
                      '[BelongingAnimalScreen] Permission request result: $permissionGranted',
                    );
                    if (!permissionGranted) {
                      debugPrint(
                        '[BelongingAnimalScreen] Permission denied, setting pending snackbar',
                      );
                      _pendingSnackBarMessage =
                          'Locatie toegang is nodig om door te gaan';
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _handlePendingSnackBar(),
                      );
                      return;
                    }
                  }
                  // Navigate to LocationScreen if permission is granted
                  debugPrint(
                    '[BelongingAnimalScreen]: Navigating to LocationScreen',
                  );
                  debugPrint(
                    '[BelongingAnimalScreen]: Selected animal name: ${selectedAnimal.animalName}',
                  );
                  debugPrint(
                    '[BelongingAnimalScreen]: Selected animal ID: ${selectedAnimal.animalId!}',
                  );
                  _belongingDamageReportProvider.setSuspectedAnimal(
                    selectedAnimal.animalId!,
                  );
                  if (context.mounted) {
                    debugPrint("[BelongingAnimalScreen]: to DamagesScreen");
                    navigationManager.pushReplacementForward(
                      context,
                      const BelongingDamagesScreen(),
                    );
                  }
                },
                onRetry: _loadAnimals,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: () {
          debugPrint('[BelongingAnimalScreen] Back button pressed');
          _animalManager.updateSearchTerm('');
          Navigator.pop(context);
        },
        onNextPressed: null,
        showNextButton: false,
        showBackButton: true,
      ),
    );
  }
}
