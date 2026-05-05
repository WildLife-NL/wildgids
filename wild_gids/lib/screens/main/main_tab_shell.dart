import 'package:flutter/material.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/species/species_list_screen.dart';
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

  late final Map<NavTab, Widget> _pages = {
    NavTab.kaart: const KaartOverviewScreen(showBottomNav: false),
    NavTab.soorten: const SpeciesListScreen(showBottomNav: false),
    NavTab.zones: const SpeciesListScreen(showBottomNav: false),
    NavTab.waarneming: const WaarnemmingStartScreen(showBottomNav: false),
    NavTab.logboek: const LogbookScreen(showBottomNav: false),
    NavTab.profile: const ProfileScreen(showBottomNav: false),
    NavTab.instellingen: const ProfileScreen(showBottomNav: false),
  };

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
          child: _pages[_currentTab]!,
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