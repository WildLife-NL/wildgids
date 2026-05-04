import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/utils/responsive_utils.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/profile/edit_profile_screen.dart';
import 'package:wildgids/screens/shared/rapporteren.dart';
import 'package:wildgids/screens/species/species_list_screen.dart';
import 'package:wildgids/models/beta_models/profile_model.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  Profile? _profile;
  bool _notificationsEnabled = true;
  String _appVersionLabel = '';

  void _onTabSelected(NavTab tab) {
    final navigationManager = context.read<NavigationStateInterface>();
    switch (tab) {
      case NavTab.zones:
        navigationManager.pushReplacementForward(context, const SpeciesListScreen());
        break;
      case NavTab.rapporten:
        navigationManager.pushReplacementForward(context, const Rapporteren());
        break;
      case NavTab.kaart:
        navigationManager.pushReplacementForward(context, const KaartOverviewScreen());
        break;
      case NavTab.logboek:
        navigationManager.pushReplacementForward(context, const LogbookScreen());
        break;
      case NavTab.profile:
        return;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppVersion();
  }

  Future<void> _loadUserData() async {
    final profileApi = context.read<ProfileApiInterface>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
    try {
      final profile = await profileApi.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _userName = profile.userName;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = info.buildNumber;
      // Format YYYYMMDD build numbers as VYY.MM.DD (e.g. 20260325 -> V26.03.25)
      if (build.length >= 8 && RegExp(r'^\d{8}$').hasMatch(build)) {
        final yy = build.substring(2, 4);
        final mm = build.substring(4, 6);
        final dd = build.substring(6, 8);
        if (!mounted) return;
        setState(() {
          _appVersionLabel = 'App Version: V$yy.$mm.$dd';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _appVersionLabel = 'App Version: ${info.version}+${info.buildNumber}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appVersionLabel = 'App Version: onbekend';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    context.watch<AppStateProvider>();
    final effectiveVersion =
        _appVersionLabel.isNotEmpty ? _appVersionLabel : 'App Version: laden...';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 98),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 2),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F1F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 36, color: Colors.black45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize(30),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _profile?.email ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    color: const Color(0xFF8D8D8D),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPrimaryButton(
                  label: 'Profiel Bewerken',
                  onTap: _handleEditProfile,
                ),
                const SizedBox(height: 12),
                Text(
                  'Voorkeuren',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                  ),
                  child: Column(
                    children: [
                      _settingsRow(
                        label: 'Locatie delen',
                        value: true,
                        onChanged: null,
                      ),
                      const Divider(height: 1, color: Color(0xFFE7E7E7)),
                      _settingsRow(
                        label: 'Meldingen',
                        value: _notificationsEnabled,
                        onChanged: (value) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('notifications_enabled', value);
                          if (!mounted) return;
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  effectiveVersion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    color: const Color(0xFF8D8D8D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPrimaryButton(
                  label: 'Uitloggen',
                  onTap: _confirmLogout,
                ),
                const SizedBox(height: 12),
                Text(
                  'Account verwijderen',
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Je gegevens gaan permanent verloren; dit kan niet ongedaan worden.',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    color: const Color(0xFF7F7F7F),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: _confirmDelete,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF2F2),
                      foregroundColor: const Color(0xFFBE3030),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Account verwijderen',
                      style: TextStyle(
                        fontSize: responsive.fontSize(17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomNavBar(
          currentTab: NavTab.profile,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    final responsive = context.responsive;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF103D1E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _settingsRow({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final responsive = context.responsive;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF103D1E),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
              return Colors.transparent;
            }),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditProfile() async {
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

  void _confirmLogout() {
    final responsive = context.responsive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Uitloggen?',
          style: TextStyle(fontSize: responsive.fontSize(18)),
        ),
        content: Text(
          'Wilt u uitloggen?',
          style: TextStyle(fontSize: responsive.fontSize(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Annuleren',
              style: TextStyle(fontSize: responsive.fontSize(14)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!mounted) return;
              final appStateProvider = context.read<AppStateProvider>();
              await appStateProvider.logout();
            },
            child: Text(
              'Uitloggen',
              style: TextStyle(fontSize: responsive.fontSize(14)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
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
            child: Text(
              'Annuleren',
              style: TextStyle(fontSize: responsive.fontSize(14)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (!mounted) return;
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
            child: Text(
              'Verwijderen',
              style: TextStyle(
                color: Colors.red,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

