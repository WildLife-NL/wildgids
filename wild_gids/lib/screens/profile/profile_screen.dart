import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/providers/app_state_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool notificationsOn = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with back button and title (moved slightly down)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.offWhite,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            color: AppColors.offWhite,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // keep space to the right so title is centered
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Avatar + name
              Row(
                children: [
                  Container(
                    width: screenSize.width * 0.20,
                    height: screenSize.width * 0.20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.offWhite,
                    ),
                    child: const Center(child: Icon(Icons.person, size: 40)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Naam Achternaam, Researcher',
                      style: TextStyle(
                        color: AppColors.offWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Notifications label
              Center(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppColors.offWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // On/Off segmented style
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => notificationsOn = true),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: notificationsOn ? AppColors.offWhite : Colors.transparent,
                            border: Border.all(color: AppColors.offWhite),
                          ),
                          child: Center(
                            child: Text(
                              'On',
                              style: TextStyle(
                                color: notificationsOn ? AppColors.darkGreen : AppColors.offWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => notificationsOn = false),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: !notificationsOn ? AppColors.offWhite : Colors.transparent,
                            border: Border.all(color: AppColors.offWhite),
                          ),
                          child: Center(
                            child: Text(
                              'Off',
                              style: TextStyle(
                                color: !notificationsOn ? AppColors.darkGreen : AppColors.offWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 62),

              // Buttons list
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Delete account - outlined
                      _outlinedButton('Delete account', onPressed: () {
                        // placeholder
                      }),

                      const SizedBox(height: 12),

                      // Log out - filled white
                      _filledButton('Log Out', onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log out?'),
                            content: const Text('Do you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  final appStateProvider = context.read<AppStateProvider>();
                                  await appStateProvider.logout();
                                },
                                child: const Text('Log out'),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      // Update Info
                      _filledButton('Update Info', onPressed: () {}),
                      const SizedBox(height: 12),

                      // Taal
                      _filledButton('Taal', onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filledButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
          // default background: light mint; on hover/pressed: light green
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
              return AppColors.lightGreen; // 0xFF1F4A14
            }
            return AppColors.lightMintGreen; // 0xFFF1F5F2
          }),
          // default text: black; on hover/pressed: offWhite
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
              return AppColors.offWhite;
            }
            return AppColors.black;
          }),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
          // small elevation to match flat look; keep default elevation on press
          elevation: MaterialStateProperty.resolveWith<double?>((states) {
            if (states.contains(MaterialState.pressed)) return 2.0;
            return 0.0;
          }),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  Widget _outlinedButton(String text, {required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
              return AppColors.lightGreen;
            }
            return AppColors.lightMintGreen;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
              return AppColors.offWhite;
            }
            return AppColors.black;
          }),
          side: MaterialStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
              return BorderSide(color: AppColors.lightGreen);
            }
            return BorderSide(color: AppColors.lightMintGreen);
          }),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
