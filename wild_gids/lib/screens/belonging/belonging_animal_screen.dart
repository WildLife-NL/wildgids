import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/filters/dropdown_interface.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/models/enums/dropdown_type.dart';
import 'package:wildrapport/models/animal_waarneming_models/animal_model.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:wildrapport/screens/belonging/belonging_location_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
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
  bool _isExpanded = false;
  List<AnimalModel> _animals = [];
  bool _isLoading = true;
  String? _pendingSnackBarMessage;

  @override
  void initState() {
    super.initState();
    _belongingDamageReportProvider = context.read<BelongingDamageReportProvider>();
    _loadAnimals();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimals() async {
    final animalManager = context.read<AnimalManagerInterface>();

    setState(() {
      _isLoading = true;
    });

    try {
      final animals = await animalManager.getAnimals();
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

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
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
    final dropdownInterface = context.read<DropdownInterface>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: widget.appBarTitle,
              rightIcon: Icons.menu,
              onLeftIconPressed: () {
                debugPrint('[BelongingAnimalScreen] Back button pressed');
                Navigator.pop(context);
              },
              onRightIconPressed: () {
                debugPrint('[BelongingAnimalScreen] Menu button pressed');
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: dropdownInterface.buildDropdown(
                type: DropdownType.filter,
                selectedValue: context.read<AnimalManagerInterface>().getSelectedFilter(),
                isExpanded: _isExpanded,
                onExpandChanged: (_) => _toggleExpanded(),
                onOptionSelected: (value) {
                  context.read<AnimalManagerInterface>().updateFilter(value);
                  _loadAnimals();
                },
                context: context,
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