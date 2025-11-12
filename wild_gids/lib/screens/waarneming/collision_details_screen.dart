import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildrapport/screens/location/location_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/constants/app_colors.dart';

class CollisionDetailsScreen extends StatefulWidget {
  const CollisionDetailsScreen({super.key});

  @override
  State<CollisionDetailsScreen> createState() => _CollisionDetailsScreenState();
}

class _CollisionDetailsScreenState extends State<CollisionDetailsScreen> {
  final TextEditingController _damageController = TextEditingController();
  String? _selectedIntensity;
  String? _selectedUrgency;

  @override
  void dispose() {
    _damageController.dispose();
    super.dispose();
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
              centerText: 'Verkeersongeval Details',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                Navigator.of(context).pop();
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
                    Text(
                      'Aanvullende informatie',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Damage in euros input field
                            Text(
                              'Schade in euros',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _damageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Voer bedrag in',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.darkGreen,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.darkGreen,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.darkGreen,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Intensity of accident
                            Text(
                              'Intensiteit van ongeval',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSelectionButton(
                                    label: 'Hoog',
                                    isSelected: _selectedIntensity == 'high',
                                    onTap: () {
                                      setState(() {
                                        _selectedIntensity = 'high';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSelectionButton(
                                    label: 'Gemiddeld',
                                    isSelected: _selectedIntensity == 'medium',
                                    onTap: () {
                                      setState(() {
                                        _selectedIntensity = 'medium';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSelectionButton(
                                    label: 'Laag',
                                    isSelected: _selectedIntensity == 'low',
                                    onTap: () {
                                      setState(() {
                                        _selectedIntensity = 'low';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Urgency of accident
                            Text(
                              'Urgentie van ongeval',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSelectionButton(
                                    label: 'Hoog',
                                    isSelected: _selectedUrgency == 'high',
                                    onTap: () {
                                      setState(() {
                                        _selectedUrgency = 'high';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSelectionButton(
                                    label: 'Gemiddeld',
                                    isSelected: _selectedUrgency == 'medium',
                                    onTap: () {
                                      setState(() {
                                        _selectedUrgency = 'medium';
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSelectionButton(
                                    label: 'Laag',
                                    isSelected: _selectedUrgency == 'low',
                                    onTap: () {
                                      setState(() {
                                        _selectedUrgency = 'low';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Accident details text input
                            Text(
                              'Ongeval details',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Beschrijf het ongeval...',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.darkGreen,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.darkGreen,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.darkGreen,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomAppBar(
        onBackPressed: () {},
        onNextPressed: () async {
          final permissionManager = context.read<PermissionInterface>();
          final navigationManager = context.read<NavigationStateInterface>();
          final animalSightingManager =
              context.read<AnimalSightingReportingInterface>();

          final currentSighting =
              animalSightingManager.getCurrentanimalSighting();
          debugPrint(
            '[CollisionDetailsScreen] Current animal sighting state: ${currentSighting?.toJson()}',
          );

          final hasPermission = await permissionManager.isPermissionGranted(
            PermissionType.location,
          );
          debugPrint(
            '[CollisionDetailsScreen] Location permission status: $hasPermission',
          );

          if (context.mounted) {
            navigationManager.pushReplacementForward(
              context,
              const LocationScreen(),
            );
          }
        },
        showBackButton: false,
        showNextButton: true,
      ),
    );
  }

  Widget _buildSelectionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.darkGreen,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.darkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
