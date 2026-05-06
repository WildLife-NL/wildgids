import 'dart:math' as math;

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
  bool _loadingProfile = true;
  bool _notificationsEnabled = true;
  String _appVersionLabel = '';

  static const _pageBg = Color(0xFFEFF2EF);
  static const _primaryGreen = Color(0xFF103D1E);
  static const _textPrimary = Color(0xFF111827);
  static const _borderDefault = Color(0xFFE0E0E0);
  static const _cardBackground = Color(0xFFF5F6F4);

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
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
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

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = info.buildNumber;

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
        _appVersionLabel = 'App Version: V${info.version}+${info.buildNumber}';
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
    final app = context.watch<AppStateProvider>();
    final fs = responsive.fontSize;

    final email = _profile?.email ?? '—';
    final effectiveVersion =
        _appVersionLabel.isNotEmpty ? _appVersionLabel : 'App Version: laden...';

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPad = responsive.wp(3.5).clamp(10.0, 18.0);
            final cardW = math.min(540.0, constraints.maxWidth - horizontalPad * 2);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 4),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardW),
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                        color: _borderDefault,
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 14),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Card(
                              color: _cardBackground,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: _borderDefault,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 1),
                                              Text(
                                                _userName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: fs(18),
                                                  fontWeight: FontWeight.w700,
                                                  color: _textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _loadingProfile ? '…' : email,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: fs(11),
                                                  color: Colors.grey.shade600,
                                                  height: 1.25,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    FilledButton(
                                      onPressed: _loadingProfile ? null : _handleEditProfile,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _cardBackground,
                                        foregroundColor: Colors.grey.shade900,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(26),
                                          side: const BorderSide(
                                            color: _borderDefault,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Profiel Bewerken',
                                        style: TextStyle(fontSize: fs(15)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              'Voorkeuren',
                              style: TextStyle(
                                fontSize: fs(12),
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    title: Text(
                                      'Locatie delen',
                                      style: TextStyle(
                                        fontSize: fs(15),
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                    value: app.isLocationTrackingEnabled,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: _primaryGreen,
                                    onChanged: (enabled) async {
                                      await app.setLocationTrackingEnabled(enabled);
                                      if (!mounted) return;
                                      setState(() {});
                                    },
                                  ),
                                  Divider(height: 1, color: Colors.grey.shade300),
                                  SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    title: Text(
                                      'Meldingen',
                                      style: TextStyle(
                                        fontSize: fs(15),
                                        color: _textPrimary,
                                      ),
                                    ),
                                    value: _notificationsEnabled,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: _primaryGreen,
                                    onChanged: (enabled) async {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('notifications_enabled', enabled);
                                      if (!mounted) return;
                                      setState(() {
                                        _notificationsEnabled = enabled;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Card(
                              color: _cardBackground,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      effectiveVersion,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: fs(11),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    FilledButton(
                                      onPressed: _confirmLogout,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.grey.shade900,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        minimumSize: const Size.fromHeight(48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(26),
                                          side: const BorderSide(
                                            color: _borderDefault,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Uitloggen',
                                        style: TextStyle(fontSize: fs(15)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Account verwijderen',
                                  style: TextStyle(
                                    fontSize: fs(16),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Je gegevens gaan permanent verloren; dit kan niet ongedaan worden.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: fs(12),
                                    color: Colors.grey.shade600,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FilledButton(
                                  onPressed: _confirmDelete,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(136, 255, 230, 232),
                                    foregroundColor:
                                        const Color.fromARGB(255, 209, 118, 118),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                  ),
                                  child: Text(
                                    'Account verwijderen',
                                    style: TextStyle(
                                      fontSize: fs(14),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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

  void _confirmLogout() {
    final responsive = context.responsive;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFD4AF37),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Weet je het zeker?',
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Je wordt uitgelogd en moet opnieuw inloggen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.fontSize(13),
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Annuleren',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        if (!mounted) return;
                        final appStateProvider = context.read<AppStateProvider>();
                        await appStateProvider.logout();
                      },
                      child: Text(
                        'Ja, Uitloggen',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    final responsive = context.responsive;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Weet je het zeker?',
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Je gegevens gaan permanent verloren; dit kan niet ongedaan worden.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: responsive.fontSize(13),
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Annuleren',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.red.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
                      child: Text(
                        'Ja, Verwijderen',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}