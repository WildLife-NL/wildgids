import 'dart:math' as math;

import 'package:flutter/material.dart';
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
import 'package:wildgids/utils/responsive_utils.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/utils/text_display_utils.dart';

/// Profielscherm: witte kaart, voorkeuren (locatie + meldingen), uitloggen, account verwijderen.
/// Geen aparte titelbalk bovenaan — alleen inhoud + eventueel systeem safe area.
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
  String _userName = 'Loading...';
  Profile? _profile;
  bool _loadingProfile = true;
  String _version = '';
  bool _bluetoothActivating = false;

  static const _pageBg = Color(0xFFEFF2EF);

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

  String _bluetoothContactSubtitle(ContactTracingCoordinator tracing) {
    if (_bluetoothActivating || tracing.backgroundScanning) {
      final msg = tracing.statusMessage;
      if (msg.contains('Scannen') || msg.contains('collar')) {
        return msg;
      }
      return 'Scannen naar collars…';
    }
    if (tracing.backgroundEnabled) {
      final msg = tracing.statusMessage;
      if (msg.isNotEmpty &&
          msg != 'Uit' &&
          !msg.startsWith('Achtergrondscan elke')) {
        return msg;
      }
      return 'Achtergrond elke ${tracing.backgroundIntervalSeconds} s · melding bij dier';
    }
    return 'Scant collars en start contact automatisch';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final app = context.watch<AppStateProvider>();
    final contactTracing = context.watch<ContactTracingCoordinator>();

    final email = _profile?.email ?? '—';

    final fs = responsive.fontSize;

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
                        side: BorderSide(
                          color: AppColors.borderDefault,
                          width: 1,
                        ),
                      ),
                      child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 14),
                          // Profile Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Card(
                              color: const Color(0xFFF5F6F4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: AppColors.borderDefault,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color: AppColors.darkCharcoal,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
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
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Tooltip(
                                              message: email,
                                              waitDuration:
                                                  const Duration(milliseconds: 400),
                                              child: Text(
                                                _loadingProfile
                                                    ? '…'
                                                    : truncateEmail(email),
                                                maxLines: 1,
                                                softWrap: false,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: fs(11),
                                                  color: Colors.grey.shade600,
                                                  height: 1.25,
                                                ),
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
                                      backgroundColor: AppColors.cardBackground,
                                      foregroundColor: Colors.grey.shade900,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                        side: BorderSide(
                                          color: AppColors.borderDefault,
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
                                  ListTile(
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
                                    subtitle: Text(
                                      'Altijd ingeschakeld',
                                      style: TextStyle(
                                        fontSize: fs(13),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryGreen,
                                      size: fs(22),
                                    ),
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
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    value: app.notificationsEnabled,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.primaryGreen,
                                    onChanged: (enabled) async {
                                      await app.setNotificationsEnabled(enabled);
                                      if (!context.mounted) return;
                                      if (enabled) {
                                        await NotificationService.instance
                                            .requestAndroidNotificationPermission();
                                      }
                                      if (!context.mounted) return;
                                      final state =
                                          context.read<AppStateProvider>();
                                      context
                                          .read<MapProvider>()
                                          .setVicinityNotificationsEnabled(
                                            state.isLocationTrackingEnabled &&
                                                state.notificationsEnabled,
                                          );
                                    },
                                  ),
                                  Divider(height: 1, color: Colors.grey.shade300),
                                  SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 4,
                                    ),
                                    secondary: Icon(
                                      Icons.bluetooth_rounded,
                                      color: AppColors.primaryGreen,
                                    ),
                                    title: Text(
                                      'Bluetooth contacttracing',
                                      style: TextStyle(
                                        fontSize: fs(15),
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        if (_bluetoothActivating ||
                                            contactTracing.backgroundScanning) ...[
                                          SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primaryGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Text(
                                            _bluetoothContactSubtitle(
                                              contactTracing,
                                            ),
                                            style: TextStyle(
                                              fontSize: fs(12),
                                              color: (_bluetoothActivating ||
                                                      contactTracing
                                                          .backgroundScanning)
                                                  ? AppColors.primaryGreen
                                                  : Colors.grey.shade600,
                                              fontWeight:
                                                  (_bluetoothActivating ||
                                                          contactTracing
                                                              .backgroundScanning)
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    value: contactTracing.backgroundEnabled,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.primaryGreen,
                                    onChanged: (_bluetoothActivating ||
                                            contactTracing.backgroundScanning)
                                        ? null
                                        : (enabled) async {
                                      if (enabled) {
                                        setState(() => _bluetoothActivating = true);
                                        await NotificationService.instance
                                            .requestAndroidNotificationPermission();
                                      }
                                      if (!context.mounted) return;
                                      final contactEnded =
                                          await contactTracing.setBackgroundEnabled(
                                        enabled,
                                      );
                                      if (!context.mounted) return;
                                      if (enabled) {
                                        await contactTracing
                                            .triggerBackgroundScanNow(
                                          force: true,
                                        );
                                      }
                                      if (!context.mounted) return;
                                      setState(() => _bluetoothActivating = false);
                                      if (!enabled && contactEnded) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Bluetooth uit — contact beëindigd',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  if (contactTracing.backgroundEnabled)
                                    ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 0,
                                      ),
                                      title: Text(
                                        'Interval & status',
                                        style: TextStyle(
                                          fontSize: fs(14),
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey.shade500,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const BluetoothContactSettingsScreen(),
                                          ),
                                        );
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
                              color: const Color(0xFFF5F6F4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      _version.isEmpty ? '' : 'App Version: V$_version',
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
                                          side: BorderSide(
                                            color: AppColors.borderDefault,
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
                              mainAxisSize: MainAxisSize.min,
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
                                    backgroundColor: const Color.fromARGB(136, 255, 230, 232),
                                    foregroundColor: const Color.fromARGB(255, 209, 118, 118),
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
                          const SizedBox(height: 20),
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
      bottomNavigationBar: widget.showBottomNav
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
        navigationManager.pushReplacementForward(context, const ChallengeScreen());
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
        navigationManager.pushReplacementForward(context, const LogbookScreen());
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
          builder: (context) => EditProfileScreen(
            initialProfile: currentProfile,
          ),
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
                          color: const Color.fromARGB(255, 0, 0, 0),
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
                          color: const Color.fromARGB(255, 0, 0, 0),
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

