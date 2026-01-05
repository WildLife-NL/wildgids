import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/utils/responsive_utils.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/screens/profile/edit_profile_screen.dart';
import 'package:wildgids/models/beta_models/profile_model.dart';
import 'package:wildgids/widgets/location/location_sharing_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  Profile? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
    try {
      final profileApi = context.read<ProfileApiInterface>();
      final profile = await profileApi.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _userName = profile.userName;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final appStateProvider = context.watch<AppStateProvider>();
    final locationTrackingEnabled = appStateProvider.isLocationTrackingEnabled;

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.wp(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with back button and title (moved slightly down)
              Padding(
                padding: EdgeInsets.only(top: responsive.hp(1)),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.offWhite,
                      iconSize: responsive.sp(3),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Profiel',
                          style: TextStyle(
                            color: AppColors.offWhite,
                            fontSize: responsive.fontSize(24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // keep space to the right so title is centered
                    SizedBox(width: responsive.wp(12)),
                  ],
                ),
              ),

              SizedBox(height: responsive.spacing(36)),

              // Avatar + name
              Row(
                children: [
                  Container(
                    width: responsive.sp(8),
                    height: responsive.sp(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.offWhite,
                    ),
                    child: Center(
                      child: Icon(Icons.person, size: responsive.sp(5)),
                    ),
                  ),
                  SizedBox(width: responsive.wp(3.5)),
                  Expanded(
                    child: Text(
                      _userName,
                      style: TextStyle(
                        color: AppColors.offWhite,
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: responsive.spacing(24)),

              // Profile info section with inline update action
              _buildProfileInfoSection(context),

              SizedBox(height: responsive.spacing(32)),

              // Location Tracking label
              Center(
                child: Text(
                  'Locatie delen',
                  style: TextStyle(
                    color: AppColors.offWhite,
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: responsive.spacing(12)),

              // On/Off segmented style
              Center(
                child: Container(
                  padding: EdgeInsets.all(responsive.sp(0.5)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(responsive.sp(3)),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await appStateProvider.setLocationTrackingEnabled(
                            true,
                          );
                        },
                        child: Container(
                          width: responsive.wp(25),
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.hp(1),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              responsive.sp(2.5),
                            ),
                            color:
                                locationTrackingEnabled
                                    ? AppColors.offWhite
                                    : Colors.transparent,
                            border: Border.all(
                              color: AppColors.offWhite,
                              width: responsive.sp(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Aan',
                              style: TextStyle(
                                color:
                                    locationTrackingEnabled
                                        ? AppColors.darkGreen
                                        : AppColors.offWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: responsive.wp(2)),
                      GestureDetector(
                        onTap: () async {
                          await appStateProvider.setLocationTrackingEnabled(
                            false,
                          );
                        },
                        child: Container(
                          width: responsive.wp(25),
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.hp(1),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              responsive.sp(2.5),
                            ),
                            color:
                                !locationTrackingEnabled
                                    ? AppColors.offWhite
                                    : Colors.transparent,
                            border: Border.all(
                              color: AppColors.offWhite,
                              width: responsive.sp(0.2),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Uit',
                              style: TextStyle(
                                color:
                                    !locationTrackingEnabled
                                        ? AppColors.darkGreen
                                        : AppColors.offWhite,
                                fontWeight: FontWeight.w600,
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: responsive.spacing(16)),

              // Location sharing status indicator
              Center(
                child: LocationSharingIndicator(
                  showLabel: true,
                  iconSize: 18,
                ),
              ),

              SizedBox(height: responsive.spacing(24)),

              // Scrollable content (without destructive/secondary actions)
              Expanded(
                child: SingleChildScrollView(
                  child: const SizedBox.shrink(),
                ),
              ),

              // Less prominent actions at the bottom
              Padding(
                padding: EdgeInsets.only(
                  left: responsive.wp(4),
                  right: responsive.wp(4),
                  bottom: responsive.hp(2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton(
                      onPressed: () => _confirmLogout(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.offWhite,
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.hp(1.25),
                        ),
                        textStyle: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Afmelden'),
                    ),
                    TextButton(
                      onPressed: () => _confirmDelete(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.hp(1.0),
                        ),
                        textStyle: TextStyle(
                          fontSize: responsive.fontSize(13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Account verwijderen'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoSection(BuildContext context) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.sp(2.5)),
      decoration: BoxDecoration(
        color: AppColors.lightMintGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.sp(3)),
        border: Border.all(color: AppColors.offWhite.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profielgegevens',
                  style: TextStyle(
                    color: AppColors.offWhite,
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _handleEditProfile(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightMintGreen,
                  textStyle: TextStyle(fontSize: responsive.fontSize(14)),
                ),
                child: const Text('Bijwerken'),
              )
            ],
          ),
          SizedBox(height: responsive.spacing(12)),
          if (_loadingProfile)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  context,
                  label: 'Naam',
                  value: _profile?.userName ?? _userName,
                ),
                _infoRow(
                  context,
                  label: 'Eâ€‘mail',
                  value: _profile?.email,
                ),
                if ((_profile?.postcode ?? '').isNotEmpty)
                  _infoRow(
                    context,
                    label: 'Postcode',
                    value: _profile!.postcode,
                  ),
                if ((_profile?.gender ?? '').isNotEmpty)
                  _infoRow(
                    context,
                    label: 'Geslacht',
                    value: _profile!.gender,
                  ),
                if ((_profile?.dateOfBirth ?? '').isNotEmpty)
                  _infoRow(
                    context,
                    label: 'Geboortedatum',
                    value: _profile!.dateOfBirth,
                  ),
                if ((_profile?.description ?? '').isNotEmpty)
                  _infoRow(
                    context,
                    label: 'Beschrijving',
                    value: _profile!.description,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, {required String label, String? value}) {
    final responsive = context.responsive;
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.hp(0.8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: responsive.wp(30),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.offWhite.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.offWhite,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditProfile(BuildContext context) async {
    try {
      final profileApi = context.read<ProfileApiInterface>();
      final currentProfile = await profileApi.fetchMyProfile();
      if (!mounted) return;
      final updatedProfile = await Navigator.of(context).push<Profile>(
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(
            initialProfile: currentProfile,
          ),
        ),
      );
      if (updatedProfile != null && mounted) {
        setState(() {
          _profile = updatedProfile;
          _userName = updatedProfile.userName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profiel bijgewerkt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij laden profiel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmLogout(BuildContext context) {
    final responsive = context.responsive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Afmelden?',
          style: TextStyle(fontSize: responsive.fontSize(18)),
        ),
        content: Text(
          'Wilt u uitloggen?',
          style: TextStyle(fontSize: responsive.fontSize(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuleren', style: TextStyle(fontSize: responsive.fontSize(14))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final appStateProvider = context.read<AppStateProvider>();
              await appStateProvider.logout();
            },
            child: Text('Afmelden', style: TextStyle(fontSize: responsive.fontSize(14))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final responsive = context.responsive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Account verwijderen?',
          style: TextStyle(fontSize: responsive.fontSize(18)),
        ),
        content: Text(
          'Dit zal uw account en alle bijbehorende gegevens permanent verwijderen. Deze actie kan niet ongedaan worden gemaakt.',
          style: TextStyle(fontSize: responsive.fontSize(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annuleren', style: TextStyle(fontSize: responsive.fontSize(14))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account wordt verwijderd...'),
                  duration: Duration(seconds: 2),
                ),
              );
              try {
                final profileApi = context.read<ProfileApiInterface>();
                final appStateProvider = context.read<AppStateProvider>();
                await profileApi.deleteMyProfile();
                await appStateProvider.deleteProfile();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fout bij verwijderen: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Verwijderen', style: TextStyle(fontSize: responsive.fontSize(14), color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _filledButton(
    BuildContext context,
    String text, {
    required VoidCallback onPressed,
  }) {
    final responsive = context.responsive;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
          // default background: light mint; on hover/pressed: light green
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered) ||
                states.contains(MaterialState.pressed)) {
              return AppColors.lightGreen; // 0xFF1F4A14
            }
            return AppColors.lightMintGreen; // 0xFFF1F5F2
          }),
          // default text: black; on hover/pressed: offWhite
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered) ||
                states.contains(MaterialState.pressed)) {
              return AppColors.offWhite;
            }
            return AppColors.black;
          }),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(vertical: responsive.hp(1.75)),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(responsive.sp(3)),
            ),
          ),
          textStyle: MaterialStateProperty.all(
            TextStyle(fontSize: responsive.fontSize(16)),
          ),
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

  Widget _outlinedButton(
    BuildContext context,
    String text, {
    required VoidCallback onPressed,
  }) {
    final responsive = context.responsive;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered) ||
                states.contains(MaterialState.pressed)) {
              return AppColors.lightGreen;
            }
            return AppColors.lightMintGreen;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered) ||
                states.contains(MaterialState.pressed)) {
              return AppColors.offWhite;
            }
            return AppColors.black;
          }),
          side: MaterialStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(MaterialState.hovered) ||
                states.contains(MaterialState.pressed)) {
              return BorderSide(
                color: AppColors.lightGreen,
                width: responsive.sp(0.2),
              );
            }
            return BorderSide(
              color: AppColors.lightMintGreen,
              width: responsive.sp(0.2),
            );
          }),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(vertical: responsive.hp(1.75)),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(responsive.sp(3)),
            ),
          ),
          textStyle: MaterialStateProperty.all(
            TextStyle(fontSize: responsive.fontSize(16)),
          ),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}

