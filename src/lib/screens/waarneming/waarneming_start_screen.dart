import 'package:wildgids/widgets/guide/animal_name.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wildgids/widgets/guide/animal_artwork.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:wildgids/screens/shared/interaction_detail_screen.dart';
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
  const WaarnemmingStartScreen({super.key, this.showBottomNav = true});

  @override
  State<WaarnemmingStartScreen> createState() => _WaarnemmingStartScreenState();
}

class _WaarnemmingStartScreenState extends State<WaarnemmingStartScreen> {
  List<MyInteraction> _recentApiSightings = const [];
  bool _loadingRecentSightings = true;
  bool _recentSightingsFailed = false;
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
      final sightingsOnly =
          all.where((i) => i.reportOfSighting != null).toList()
            ..sort((a, b) => b.moment.compareTo(a.moment));
      if (!mounted) return;
      setState(() {
        _recentApiSightings = sightingsOnly.take(3).toList();
        _recentSightingsFailed = false;
        _loadingRecentSightings = false;
      });
      _resolveMissingLocationNames(_recentApiSightings);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recentApiSightings = const [];
        _recentSightingsFailed = true;
        _loadingRecentSightings = false;
      });
    }
  }

  Future<void> _resolveMissingLocationNames(
    List<MyInteraction> sightings,
  ) async {
    final resolver = LocationMapManager();
    for (final sighting in sightings) {
      if (_locationLabelByInteractionId.containsKey(sighting.id)) continue;
      if (sighting.place.cityName.isNotEmpty ||
          sighting.place.streetName.isNotEmpty) {
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
          _locationLabelByInteractionId[sighting.id] = _extractLikelyCity(
            address,
          );
        });
      } catch (_) {
        // Keep coordinate fallback when reverse geocoding fails.
      }
    }
  }

  String _extractLikelyCity(String address) {
    final parts =
        address
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

  void _startSighting() {
    context.read<NavigationStateInterface>().pushForward(
      context,
      const LocationSelectionScreen(),
    );
  }

  void _openDiary() {
    context.read<NavigationStateInterface>().pushForward(
      context,
      const LogbookScreen(openRecentSightings: true),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ChallengeScreen.pageBackground,
    bottomNavigationBar:
        widget.showBottomNav
            ? SafeArea(
              top: false,
              child: CustomNavBar(
                currentTab: NavTab.waarneming,
                onTabSelected: _onTabSelected,
              ),
            )
            : null,
    body: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const GuideBrand(),
                const SizedBox(height: 28),
                const Text(
                  'Wat heb je gezien?',
                  style: TextStyle(
                    fontSize: 36,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: ChallengeScreen.deepGreen,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: AnimalArtwork(
                    imagePath: SpeciesImageResolver.drawingForCommonName(
                      'damhert',
                    ),
                    zoom: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _startSighting,
                  style: GuideStyle.primaryButton,
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Waarneming vastleggen',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Laatst gezien',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ChallengeScreen.deepGreen,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecentSightingsList(context),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _openDiary,
                    style: TextButton.styleFrom(
                      foregroundColor: ChallengeScreen.deepGreen,
                      minimumSize: const Size(48, 48),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_stories_outlined),
                        SizedBox(width: 10),
                        Expanded(child: Text('Bekijk je wildlife diary')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildRecentSightingsList(BuildContext context) {
    if (_loadingRecentSightings) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final recentSightings = _recentApiSightings;

    if (_recentSightingsFailed || recentSightings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ChallengeScreen.softGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _recentSightingsFailed
                  ? 'Je waarnemingen konden niet worden geladen.'
                  : 'Je eerste ontmoeting begint hier.',
              style: const TextStyle(
                color: ChallengeScreen.deepGreen,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _recentSightingsFailed
                  ? 'Probeer het opnieuw. Je kunt wel een nieuwe waarneming vastleggen.'
                  : 'Heb je een dier gezien? Leg het vast en vind het hier terug.',
              style: const TextStyle(
                color: ChallengeScreen.mutedText,
                height: 1.5,
              ),
            ),
            if (_recentSightingsFailed)
              TextButton(
                onPressed: () {
                  setState(() => _loadingRecentSightings = true);
                  _loadRecentSightings();
                },
                child: const Text('Opnieuw proberen'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(recentSightings.length, (index) {
        final MyInteraction sighting = recentSightings[index];
        final animalName =
            sighting.species.commonName.isNotEmpty
                ? sighting.species.commonName
                : 'Onbekend dier';
        final resolvedImagePath = SpeciesImageResolver.drawingForCommonName(
          animalName,
        );
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => InteractionDetailScreen(interaction: sighting),
                  ),
                );
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
                                width: 76,
                                height: 76,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 76,
                                    height: 76,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.pets, size: 24),
                                  );
                                },
                              )
                              : Container(
                                width: 76,
                                height: 76,
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
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: ChallengeScreen.mutedText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimalName(
                            animalName,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: ChallengeScreen.deepGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 13,
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
    final days =
        DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;
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
