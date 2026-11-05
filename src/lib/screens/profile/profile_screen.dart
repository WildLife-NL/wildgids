import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/models/beta_models/profile_model.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/game/challenge_screen.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';
import 'package:wildgids/screens/profile/bluetooth_contact_settings_screen.dart';
import 'package:wildgids/screens/profile/edit_profile_screen.dart';
import 'package:wildgids/services/contact_tracing_coordinator.dart';
import 'package:wildgids/utils/notification_service.dart';
import 'package:wildgids/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onBackPressed,
    this.showBottomNav = true,
  });

  final VoidCallback? onBackPressed;
  final bool showBottomNav;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Laden...';
  Profile? _profile;
  bool _loadingProfile = true;
  String _version = '';
  bool _bluetoothActivating = false;
  String? _expandedSection;

  static const _green = Color(0xFF003B2B);
  static const _muted = Color(0xFF667064);
  static const _border = Color(0xFFE7E2D8);
  static const _softGreen = Color(0xFFEAF0E3);
  static const _danger = Color(0xFFA33636);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = _buildDateFromBuildNumber(info.buildNumber);
    });
  }

  String _buildDateFromBuildNumber(String buildNumber) {
    final digitsOnly = buildNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 8) {
      final year = digitsOnly.substring(0, 4);
      final month = digitsOnly.substring(4, 6);
      final day = digitsOnly.substring(6, 8);
      return '$year-$month-$day';
    }
    if (digitsOnly.length == 6) {
      final year = '20${digitsOnly.substring(0, 2)}';
      final month = digitsOnly.substring(2, 4);
      final day = digitsOnly.substring(4, 6);
      return '$year-$month-$day';
    }
    return buildNumber;
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'Gebruiker';
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

  String _bluetoothContactSubtitle(ContactTracingCoordinator tracing) {
    if (_bluetoothActivating || tracing.backgroundScanning) {
      return 'Scannen naar collars…';
    }
    if (tracing.backgroundEnabled) {
      final msg = tracing.statusMessage;
      // Only show positive/neutral runtime states here.
      if (msg.startsWith('Contact:') || msg.startsWith('Actief contact:')) {
        return msg;
      }
      return 'Achtergrond elke ${tracing.backgroundIntervalSeconds} s · melding bij dier';
    }
    return 'Scant collars en start contact automatisch';
  }

  Future<void> _changeNotifications(bool enabled) async {
    final app = context.read<AppStateProvider>();
    await app.setNotificationsEnabled(enabled);
    if (!mounted) return;
    if (enabled) {
      await NotificationService.instance.requestAndroidNotificationPermission();
    }
    if (!mounted) return;
    final state = context.read<AppStateProvider>();
    context.read<MapProvider>().setVicinityNotificationsEnabled(
      state.isLocationTrackingEnabled && state.notificationsEnabled,
    );
  }

  Future<void> _changeBluetooth(bool enabled) async {
    final contactTracing = context.read<ContactTracingCoordinator>();
    if (enabled) {
      setState(() => _bluetoothActivating = true);
      await NotificationService.instance.requestAndroidNotificationPermission();
    }
    if (!mounted) return;
    final contactEnded = await contactTracing.setBackgroundEnabled(enabled);
    if (!mounted) return;
    if (enabled) {
      await contactTracing.triggerBackgroundScanNow(force: true);
    }
    if (!mounted) return;
    setState(() => _bluetoothActivating = false);
    if (!enabled && contactEnded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth uit — contact beëindigd'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final tracing = context.watch<ContactTracingCoordinator>();
    final scanning = _bluetoothActivating || tracing.backgroundScanning;
    final email = _profile?.email ?? '—';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const ValueKey('profile-scroll'),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/logo-wildlife.svg',
                        width: 40,
                        height: 40,
                        excludeFromSemantics: true,
                        colorFilter: const ColorFilter.mode(
                          _green,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Mijn profiel',
                          style: TextStyle(
                            color: _green,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Column(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: _softGreen,
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: _green,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _userName,
                        key: const ValueKey('profile-name'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 22,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _loadingProfile ? 'Profiel laden...' : email,
                        key: const ValueKey('profile-email'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('profile-edit'),
                    onPressed: _loadingProfile ? null : _handleEditProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Profiel bewerken'),
                  ),
                  const SizedBox(height: 28),
                  _ProfileSectionToggle(
                    key: const ValueKey('profile-preferences-section'),
                    title: 'Voorkeuren',
                    icon: Icons.tune_rounded,
                    expanded: _expandedSection == 'preferences',
                    onTap:
                        () => setState(
                          () =>
                              _expandedSection =
                                  _expandedSection == 'preferences'
                                      ? null
                                      : 'preferences',
                        ),
                  ),
                  if (_expandedSection == 'preferences') ...[
                    const SizedBox(height: 8),
                    const _ProfileSettingRow(
                      icon: Icons.location_on_outlined,
                      title: 'Locatie delen',
                      subtitle: Text('Altijd ingeschakeld'),
                      trailing: Icon(
                        Icons.check_circle_outline,
                        color: _green,
                        size: 24,
                      ),
                    ),
                    const Divider(height: 1, color: _border),
                    _ProfileSettingRow(
                      icon: Icons.notifications_outlined,
                      title: 'Meldingen',
                      trailing: Switch(
                        key: const ValueKey('profile-notifications'),
                        value: app.notificationsEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: _green,
                        onChanged: _changeNotifications,
                      ),
                    ),
                    const Divider(height: 1, color: _border),
                    _ProfileSettingRow(
                      icon: Icons.bluetooth_rounded,
                      title: 'Bluetooth contacttracing',
                      subtitle: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (scanning) ...[
                            const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(_bluetoothContactSubtitle(tracing)),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        key: const ValueKey('profile-bluetooth'),
                        value: tracing.backgroundEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: _green,
                        onChanged: scanning ? null : _changeBluetooth,
                      ),
                    ),
                    if (tracing.backgroundEnabled)
                      ListTile(
                        key: const ValueKey('profile-bluetooth-settings'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.tune_rounded, color: _green),
                        title: const Text(
                          'Interval & status',
                          style: TextStyle(
                            color: _green,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: _green,
                        ),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        const BluetoothContactSettingsScreen(),
                              ),
                            ),
                      ),
                    const Divider(height: 1, color: _border),
                  ],
                  const SizedBox(height: 12),
                  _ProfileSectionToggle(
                    key: const ValueKey('profile-account-section'),
                    title: 'Account',
                    icon: Icons.manage_accounts_outlined,
                    expanded: _expandedSection == 'account',
                    onTap:
                        () => setState(
                          () =>
                              _expandedSection =
                                  _expandedSection == 'account'
                                      ? null
                                      : 'account',
                        ),
                  ),
                  if (_expandedSection == 'account') ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('profile-logout'),
                      onPressed: _confirmLogout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: const BorderSide(color: Color(0xFFC9DABA)),
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('Uitloggen'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      key: const ValueKey('profile-delete'),
                      onPressed: _confirmDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: _danger,
                        backgroundColor: const Color(0xFFFFF0ED),
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text('Account verwijderen'),
                    ),
                  ],
                  if (_version.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Appversie: V$_version',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav
              ? SafeArea(
                top: false,
                child: CustomNavBar(
                  currentTab: NavTab.profile,
                  onTabSelected: _onTabSelected,
                ),
              )
              : null,
    );
  }

  void _onTabSelected(NavTab tab) {
    final navigationManager = context.read<NavigationStateInterface>();
    switch (tab) {
      case NavTab.ontdekken:
      case NavTab.zones:
        navigationManager.pushReplacementForward(
          context,
          const ChallengeScreen(),
        );
        break;
      case NavTab.waarneming:
        navigationManager.pushReplacementForward(
          context,
          const WaarnemmingStartScreen(),
        );
        break;
      case NavTab.kaart:
        navigationManager.pushReplacementForward(
          context,
          const KaartOverviewScreen(),
        );
        break;
      case NavTab.logboek:
        navigationManager.pushReplacementForward(
          context,
          const LogbookScreen(),
        );
        break;
      case NavTab.instellingen:
      case NavTab.profile:
        return;
    }
  }

  Future<void> _handleEditProfile() async {
    try {
      final profileApi = context.read<ProfileApiInterface>();
      final currentProfile = await profileApi.fetchMyProfile();
      if (!mounted) return;
      final updatedProfile = await Navigator.of(context).push<Profile>(
        MaterialPageRoute(
          builder:
              (context) => EditProfileScreen(initialProfile: currentProfile),
        ),
      );
      if (!mounted) return;
      if (updatedProfile != null) {
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
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.offWhite,
            scrollable: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            icon: const Icon(Icons.logout_rounded, color: _green, size: 28),
            title: const Text(
              'Weet je het zeker?',
              style: TextStyle(
                color: _green,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Je wordt uitgelogd en moet opnieuw inloggen.',
              style: TextStyle(color: _muted, fontSize: 16, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuleren', style: TextStyle(color: _green)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  final appStateProvider = context.read<AppStateProvider>();
                  await appStateProvider.logout();
                },
                child: const Text('Ja, Uitloggen'),
              ),
            ],
          ),
    );
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.offWhite,
            scrollable: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: _danger,
              size: 28,
            ),
            title: const Text(
              'Weet je het zeker?',
              style: TextStyle(
                color: _green,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Je gegevens gaan permanent verloren; dit kan niet ongedaan worden.',
              style: TextStyle(color: _muted, fontSize: 16, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuleren', style: TextStyle(color: _green)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final profileApi = context.read<ProfileApiInterface>();
                  final appStateProvider = context.read<AppStateProvider>();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Account wordt verwijderd...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  try {
                    await profileApi.deleteMyProfile();
                    await appStateProvider.deleteProfile();
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Fout bij verwijderen: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Ja, Verwijderen'),
              ),
            ],
          ),
    );
  }
}

class _ProfileSectionToggle extends StatelessWidget {
  const _ProfileSectionToggle({
    super.key,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    expanded: expanded,
    child: Material(
      color: const Color(0xFFEAF0E3),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: _ProfileScreenState._green),
        title: Text(
          title,
          style: const TextStyle(
            color: _ProfileScreenState._green,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          color: _ProfileScreenState._green,
        ),
        onTap: onTap,
      ),
    ),
  );
}

class _ProfileSettingRow extends StatelessWidget {
  const _ProfileSettingRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final Widget trailing;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(icon, color: _ProfileScreenState._green, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ProfileScreenState._green,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 5),
                    DefaultTextStyle(
                      style: const TextStyle(
                        color: _ProfileScreenState._muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    ),
  );
}
