import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/services/contact_tracing_coordinator.dart';
import 'package:wildgids/screens/game/challenge_screen.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
//import 'package:wildgids/screens/species/species_list_screen.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';


class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key});

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  NavTab _currentTab = NavTab.kaart;
  NavTab _previousTab = NavTab.kaart;

  Widget _pageForTab(NavTab tab) {
    switch (tab) {
      case NavTab.kaart:
        return const KaartOverviewScreen(showBottomNav: false);
      case NavTab.ontdekken:
      case NavTab.zones:
        return const ChallengeScreen(showAppBar: false, showBottomNav: false);
      case NavTab.waarneming:
        return const WaarnemmingStartScreen(showBottomNav: false);
      case NavTab.logboek:
        return const LogbookScreen(showBottomNav: false);
      case NavTab.profile:
      case NavTab.instellingen:
        return const ProfileScreen(showBottomNav: false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<ContactTracingCoordinator>().initialize());
    });
  }

  void _onTabSelected(NavTab tab) {
    if (tab == _currentTab) return;

    setState(() {
      _previousTab = _currentTab;
      _currentTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final goingRight = _currentTab.index > _previousTab.index;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          final isIncoming = child.key == ValueKey(_currentTab);

          final offset = Tween<Offset>(
            begin: Offset(
              isIncoming ? (goingRight ? 1 : -1) : 0,
              0,
            ),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offset,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentTab),
          child: _pageForTab(_currentTab),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomNavBar(
          currentTab: _currentTab,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}