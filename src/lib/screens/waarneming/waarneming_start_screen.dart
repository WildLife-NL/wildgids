import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/screens/game/challenge_screen.dart';
import 'package:wildgids/screens/waarneming/location_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/config/app_config.dart';
import 'package:wildgids/data_managers/my_interaction_api.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
//import 'package:wildgids/screens/species/species_list_screen.dart';

class WaarnemmingStartScreen extends StatefulWidget {
   final bool showBottomNav; 
  const WaarnemmingStartScreen({super.key,
   this.showBottomNav = true,
  });
  

  @override
  State<WaarnemmingStartScreen> createState() => _WaarnemmingStartScreenState();
}

class _WaarnemmingStartScreenState extends State<WaarnemmingStartScreen> {
  List<MyInteraction> _recentApiSightings = const [];
  bool _loadingRecentSightings = true;
  final Map<String, String> _locationLabelByInteractionId = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<AppStateProvider>();
      app.initializeReport(ReportType.waarneming);
      unawaited(app.updateLocationCache());
    });
    _loadRecentSightings();
  }

  Future<void> _loadRecentSightings() async {
    try {
      final api = MyInteractionApi(AppConfig.shared.apiClient);
      final all = await api.getMyInteractions();
      final now = DateTime.now();
      final sightingsOnly =
          all.where((i) => i.reportOfSighting != null).toList()
            ..sort((a, b) => b.moment.compareTo(a.moment));
      final todayOnly =
          sightingsOnly
              .where(
                (i) =>
                    i.moment.toLocal().year == now.year &&
                    i.moment.toLocal().month == now.month &&
                    i.moment.toLocal().day == now.day,
              )
              .toList();

      if (!mounted) return;
      setState(() {
        _recentApiSightings = todayOnly.take(3).toList();
        _loadingRecentSightings = false;
      });
      _resolveMissingLocationNames(_recentApiSightings);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recentApiSightings = const [];
        _loadingRecentSightings = false;
      });
    }
  }

  Future<void> _resolveMissingLocationNames(List<MyInteraction> sightings) async {
    final resolver = LocationMapManager();
    for (final sighting in sightings) {
      if (_locationLabelByInteractionId.containsKey(sighting.id)) continue;
      if (sighting.place.cityName.isNotEmpty || sighting.place.streetName.isNotEmpty) {
        continue;
      }

      try {
        final position = Position(
          longitude: sighting.place.longitude,
          latitude: sighting.place.latitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        final address = await resolver.getAddressFromPosition(position);
        if (!mounted) return;
        if (address.trim().isEmpty) continue;
        setState(() {
          _locationLabelByInteractionId[sighting.id] = _extractLikelyCity(address);
        });
      } catch (_) {
        // Keep coordinate fallback when reverse geocoding fails.
      }
    }
  }

  String _extractLikelyCity(String address) {
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return parts[parts.length - 2];
    }
    return address;
  }
void _onTabSelected(NavTab tab) {
  final nav = context.read<NavigationStateInterface>();

  switch (tab) {
    case NavTab.zones:
    case NavTab.ontdekken:
      nav.pushReplacementForward(context, const ChallengeScreen());
      break;

    case NavTab.waarneming:
      return; // already here

    case NavTab.kaart:
      nav.pushReplacementForward(context, const KaartOverviewScreen());
      break;

    case NavTab.logboek:
      nav.pushReplacementForward(context, const LogbookScreen());
      break;

    case NavTab.profile:
    case NavTab.instellingen:
      nav.pushReplacementForward(context, const ProfileScreen());
      break;
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      bottomNavigationBar: widget.showBottomNav
    ? SafeArea(
        top: false,
        child: CustomNavBar(
          currentTab: NavTab.waarneming,
          onTabSelected: _onTabSelected,
        ),
      )
    : null,
      body: SafeArea(
        bottom: false, // So content doesn't overlap nav bar
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16.0), // less top padding
                child: Text(
                  'Meld uw waarneming',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                ),
              ),
              // Map section with binoculars overlay and start button
              Padding(
                padding: const EdgeInsets.only(
                  top: 24.0, // less top padding
                  left: 16.0,
                  right: 16.0,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Map background image - full height
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color.fromARGB(60, 0, 0, 0), width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/map-pic.png',
                          height: 320,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Start button - positioned directly below binoculars
                    Positioned(
                      top: 170,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            final navigationManager =
                                context.read<NavigationStateInterface>();
                            debugPrint('[Waarneming] Start new sighting');
                            navigationManager.pushForward(
                              context,
                              const LocationSelectionScreen(),
                            );
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width - 50,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color.fromARGB(95, 0, 0, 0),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Start',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nieuwe Waarneming Starten',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Binoculars icon in dark circle - rendered on top of button
                    Positioned(
                      top: 80,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFF333333),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/binoculars-filled.svg',
                            width: 48,
                            height: 48,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Recent sightings section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recente waarnemingen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRecentSightingsList(context),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSightingsList(BuildContext context) {
    if (_loadingRecentSightings) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final recentSightings = _recentApiSightings;

    if (recentSightings.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'Nog geen recente waarnemingen',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(recentSightings.length, (index) {
          final MyInteraction sighting = recentSightings[index];
          final animalName = sighting.species.commonName.isNotEmpty
              ? sighting.species.commonName
              : 'Onbekend dier';
          final resolvedImagePath =
              SpeciesImageResolver.drawingForCommonName(animalName);
          final dayLabel = _buildDayLabel(sighting);
          final locationLabel = _buildLocationLabel(sighting);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  debugPrint('[Waarneming] Tapped sighting: $animalName');
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            resolvedImagePath != null
                                ? Image.asset(
                                  resolvedImagePath,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.pets, size: 24),
                                    );
                                  },
                                )
                                : Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.pets, size: 24),
                                ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayLabel,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              animalName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 11,
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
          );
        }),
    );
  }

  String _buildDayLabel(MyInteraction sighting) {
    final dt = sighting.moment.toLocal();
    final now = DateTime.now();
    final days = now.difference(dt).inDays;
    if (days <= 0) return 'Vandaag';
    if (days == 1) return 'Gisteren';
    return '$days dagen geleden';
  }

  String _buildLocationLabel(MyInteraction sighting) {
    if (sighting.place.cityName.isNotEmpty) {
      return sighting.place.cityName;
    }
    if (sighting.place.streetName.isNotEmpty) {
      return sighting.place.streetName;
    }
    final resolved = _locationLabelByInteractionId[sighting.id];
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }
    return '${sighting.place.latitude.toStringAsFixed(2)}, ${sighting.place.longitude.toStringAsFixed(2)}';
  }
}
