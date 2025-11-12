import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/widgets/overlay/error_overlay.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/models/enums/filter_type.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:wildrapport/screens/belonging/belonging_location_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
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
  late final BelongingDamageReportProvider _belongingDamageReportProvider;
  late final AnimalManagerInterface _animalManager;
  List<AnimalModel> _animals = [];
  bool _isLoading = true;
  String? _pendingSnackBarMessage;

  @override
  void initState() {
    super.initState();
    _belongingDamageReportProvider = context.read<BelongingDamageReportProvider>();
    _animalManager = context.read<AnimalManagerInterface>();
    _animalManager.addListener(_handleStateChange);
    _loadAnimals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      final animals = await _animalManager.getAnimals();
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

  void _handlePendingSnackBar() {
    if (_pendingSnackBarMessage != null) {
      showDialog(
        context: context,
        builder: (_) => ErrorOverlay(
          messages: [
            _pendingSnackBarMessage!,
            'Corrigeer je invoer en probeer het opnieuw.',
          ],
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
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: widget.appBarTitle,
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                debugPrint('[BelongingAnimalScreen] Back button pressed');
                Navigator.pop(context);
              },
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                children: [
                  // Search box
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
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Filter pills
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
              animals: _animals,
              isLoading: _isLoading,
              scrollController: _scrollController,
              onAnimalSelected: (AnimalModel selectedAnimal) async {
                debugPrint('[BelongingAnimalScreen] Next button pressed');
                final permissionManager = context.read<PermissionInterface>();
                final navigationManager = context.read<NavigationStateInterface>();

                // Check if location permission is already granted
                final hasPermission = await permissionManager.isPermissionGranted(PermissionType.location);
                debugPrint('[BelongingAnimalScreen] Location permission status: $hasPermission');

                if (!hasPermission) {
                  debugPrint('[BelongingAnimalScreen] Requesting location permission');
                  bool permissionGranted = false;
                  if (context.mounted) {
                    permissionGranted = await permissionManager.requestPermission(
                      context,
                      PermissionType.location,
                      showRationale: true,
                    );
                  }
                  debugPrint('[BelongingAnimalScreen] Permission request result: $permissionGranted');
                  if (!permissionGranted) {
                    debugPrint('[BelongingAnimalScreen] Permission denied, setting pending snackbar');
                    _pendingSnackBarMessage = 'Locatie toegang is nodig om door te gaan';
                    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingSnackBar());
                    return;
                  }
                }
                // Navigate to LocationScreen if permission is granted
                debugPrint('[BelongingAnimalScreen]: Navigating to LocationScreen');
                debugPrint('[BelongingAnimalScreen]: Selected animal name: ${selectedAnimal.animalName}');
                debugPrint('[BelongingAnimalScreen]: Selected animal ID: ${selectedAnimal.animalId!}');
                _belongingDamageReportProvider.setSuspectedAnimal(selectedAnimal.animalId!);
                if (context.mounted) {
                  debugPrint("[BelongingAnimalScreen]: to LocationScreen");
                  navigationManager.pushReplacementForward(
                    context,
                    const BelongingLocationScreen(),
                  );
                }
              },
              onRetry: _loadAnimals,
            ),
          ],
        ),
      ),
    );
  }
}
