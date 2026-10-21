import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/screens/species/species_list_screen.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';

class ChallengeScreen extends StatefulWidget {
  final bool showAppBar;
  final bool showBottomNav;

  const ChallengeScreen({
    super.key,
    this.showAppBar = true,
    this.showBottomNav = true,
  });

  static const Color deepGreen = Color(0xFF003B2B);
  static const Color mutedText = Color(0xFF667064);
  static const Color softGreen = Color(0xFFEAF0E3);
  static const Color pageBackground = AppColors.offWhite;
  static const Color fieldBorder = Color(0xFFE7E2D8);

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  static const _eindhovenLatitude = 51.4416;
  static const _eindhovenLongitude = 5.4697;
  static _WeatherCache? _cachedWeather;

  final _locationManager = LocationMapManager();
  String _displayName = '';
  String _locationLabel = 'Locatie bepalen...';
  _WeatherInfo _weather = _WeatherInfo.loading();
  bool _isLoadingLocation = true;
  bool _showLoading = false;
  String? _weatherNote;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && _weather.isLoading) {
        setState(() => _showLoading = true);
      }
    });
    _loadProfileName();
    _loadLocation();
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName')?.trim();
    if (!mounted) return;
    setState(() => _displayName = userName ?? '');
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    final mapProvider = context.read<MapProvider>();
    try {
      final permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 3),
      );
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Locatietoegang niet toegestaan');
      }
      Position? position = mapProvider.currentPosition;
      position ??= await Geolocator.getLastKnownPosition().timeout(
        const Duration(seconds: 3),
      );
      position ??= await _locationManager.determinePosition().timeout(
        const Duration(seconds: 6),
      );
      if (position == null) {
        throw Exception('Geen locatie beschikbaar');
      }

      final latitude = position.latitude;
      final longitude = position.longitude;
      var label =
          '${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)}';
      try {
        final address = await _locationManager
            .getAddressFromPosition(position)
            .timeout(const Duration(seconds: 3));
        if (address.trim().isNotEmpty &&
            address != 'Adres niet beschikbaar' &&
            address != 'Address not found') {
          label = _shortLocation(address);
          await mapProvider.updatePosition(position, address);
        }
      } catch (_) {
        await mapProvider.updatePosition(position, label);
      }

      if (!mounted) return;
      setState(() {
        _locationLabel = label;
        _isLoadingLocation = false;
      });
      await _loadWeather(latitude, longitude);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationLabel = 'Eindhoven (standaardlocatie)';
        _isLoadingLocation = false;
      });
      await _loadWeather(_eindhovenLatitude, _eindhovenLongitude);
    }
  }

  Future<void> _loadWeather(double latitude, double longitude) async {
    final locationKey =
        '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
    final cached = _cachedWeather;
    final age =
        cached == null ? null : DateTime.now().difference(cached.fetchedAt);
    final usableCache =
        cached != null &&
        cached.locationKey == locationKey &&
        age! >= Duration.zero &&
        age < const Duration(hours: 1);
    if (usableCache && mounted) {
      setState(() => _weather = cached.weather);
      if (age < const Duration(minutes: 10)) return;
    }
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current': 'temperature_2m,weather_code,is_day',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) throw Exception(response.body);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>;
      final temperature = (current['temperature_2m'] as num).round();
      final weatherCode = (current['weather_code'] as num).toInt();
      final isDay = (current['is_day'] as num?)?.toInt() != 0;
      final nextWeather = _WeatherInfo.fromCode(
        temperature: temperature,
        code: weatherCode,
        isDay: isDay,
      );
      _cachedWeather = _WeatherCache(locationKey, nextWeather, DateTime.now());
      if (!mounted) return;
      setState(() {
        _weather = nextWeather;
        _weatherNote = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (usableCache) {
          _weatherNote = 'Laatst opgehaald; bijwerken mislukt';
        } else {
          _weather = _WeatherInfo.unavailable();
        }
      });
    }
  }

  String _shortLocation(String address) {
    final parts =
        address
            .split(',')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    return address;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Goedemorgen';
    if (hour < 18) return 'Goedemiddag';
    return 'Goedenavond';
  }

  void _navigateToSpeciesList() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (_, _, _) => SpeciesListScreen(showBottomNav: widget.showBottomNav),
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, animation, _, child) {
          final tween = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToReport() {
    context.read<NavigationStateInterface>().pushReplacementForward(
      context,
      const WaarnemmingStartScreen(),
    );
  }

  void _onTabSelected(NavTab tab) {
    if (tab == NavTab.ontdekken || tab == NavTab.zones) return;
    final nav = context.read<NavigationStateInterface>();
    switch (tab) {
      case NavTab.kaart:
        nav.pushReplacementForward(context, const KaartOverviewScreen());
        break;
      case NavTab.waarneming:
        nav.pushReplacementForward(context, const WaarnemmingStartScreen());
        break;
      case NavTab.logboek:
        nav.pushReplacementForward(context, const LogbookScreen());
        break;
      case NavTab.profile:
      case NavTab.instellingen:
        nav.pushReplacementForward(context, const ProfileScreen());
        break;
      case NavTab.ontdekken:
      case NavTab.zones:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChallengeScreen.pageBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            22,
            widget.showAppBar ? 18 : 22,
            22,
            widget.showBottomNav ? 120 : 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(greeting: _greeting, name: _displayName),
              const SizedBox(height: 18),
              _WeatherLocationPanel(
                weather: _weather,
                locationLabel: _locationLabel,
                isLoadingLocation: _isLoadingLocation,
                showLoading: _showLoading,
                note: _weatherNote,
              ),
              const SizedBox(height: 12),
              const _AttentionCard(),
              const SizedBox(height: 18),
              _HomeActionPanels(
                onReportTap: _navigateToReport,
                onLearnTap: _navigateToSpeciesList,
              ),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Statistieken'),
              const SizedBox(height: 12),
              const _StatsGrid(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Recente badges'),
              const SizedBox(height: 12),
              const _BadgeRow(),
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Actieve uitdagingen'),
              const SizedBox(height: 12),
              const _ChallengeCard(
                icon: Icons.forest_outlined,
                title: 'Spot 3 bosdieren',
                subtitle: 'Nog 1 dier te gaan',
                progress: 0.66,
                value: '2/3',
                xp: '+50 XP',
              ),
              const _ChallengeCard(
                icon: Icons.wb_sunny_outlined,
                title: 'Ochtend ontdekker',
                subtitle: 'Doe een waarneming voor 09:00',
                progress: 0,
                value: '0/1',
                xp: '+30 XP',
              ),
              const _ChallengeCard(
                icon: Icons.place_outlined,
                title: 'Nieuwe plek',
                subtitle: 'Bezoek een nieuwe locatie',
                progress: 1,
                value: '1/1',
                xp: '+40 XP',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav
              ? SafeArea(
                top: false,
                child: CustomNavBar(
                  currentTab: NavTab.ontdekken,
                  onTabSelected: _onTabSelected,
                ),
              )
              : null,
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? greeting : '$greeting,',
                style: const TextStyle(
                  color: ChallengeScreen.mutedText,
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (name.isNotEmpty)
                Text(
                  name,
                  style: const TextStyle(
                    color: ChallengeScreen.deepGreen,
                    fontSize: 38,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherCache {
  const _WeatherCache(this.locationKey, this.weather, this.fetchedAt);

  final String locationKey;
  final _WeatherInfo weather;
  final DateTime fetchedAt;
}

class _WeatherInfo {
  const _WeatherInfo({
    required this.temperatureLabel,
    required this.description,
    required this.icon,
    required this.condition,
    required this.isLoading,
  });

  final String temperatureLabel;
  final String description;
  final IconData icon;
  final _WeatherCondition condition;
  final bool isLoading;

  factory _WeatherInfo.loading() => const _WeatherInfo(
    temperatureLabel: '--',
    description: 'Weer ophalen...',
    icon: Icons.cloud_queue_rounded,
    condition: _WeatherCondition.cloud,
    isLoading: true,
  );

  factory _WeatherInfo.unavailable() => const _WeatherInfo(
    temperatureLabel: '--',
    description: 'Weer niet beschikbaar',
    icon: Icons.cloud_off_outlined,
    condition: _WeatherCondition.cloud,
    isLoading: false,
  );

  factory _WeatherInfo.fromCode({
    required int temperature,
    required int code,
    required bool isDay,
  }) {
    if (code == 0) {
      return _WeatherInfo(
        temperatureLabel: '$temperature°',
        description: isDay ? 'Zonnig' : 'Helder',
        icon: isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
        condition: _WeatherCondition.sun,
        isLoading: false,
      );
    }
    if ([1, 2, 3].contains(code)) {
      return _WeatherInfo(
        temperatureLabel: '$temperature°',
        description: 'Bewolkt',
        icon: Icons.cloud_rounded,
        condition: _WeatherCondition.cloud,
        isLoading: false,
      );
    }
    if ([45, 48].contains(code)) {
      return _WeatherInfo(
        temperatureLabel: '$temperature°',
        description: 'Mistig',
        icon: Icons.foggy,
        condition: _WeatherCondition.fog,
        isLoading: false,
      );
    }
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return _WeatherInfo(
        temperatureLabel: '$temperature°',
        description: 'Regenachtig',
        icon: Icons.water_drop_rounded,
        condition: _WeatherCondition.rain,
        isLoading: false,
      );
    }
    if (code >= 71 && code <= 77) {
      return _WeatherInfo(
        temperatureLabel: '$temperature°',
        description: 'Sneeuw',
        icon: Icons.ac_unit_rounded,
        condition: _WeatherCondition.snow,
        isLoading: false,
      );
    }
    if (code >= 95) {
      return _WeatherInfo(
        temperatureLabel: '$temperature°',
        description: 'Onweer',
        icon: Icons.thunderstorm_rounded,
        condition: _WeatherCondition.storm,
        isLoading: false,
      );
    }
    return _WeatherInfo(
      temperatureLabel: '$temperature°',
      description: 'Wisselvallig',
      icon: Icons.cloud_queue_rounded,
      condition: _WeatherCondition.cloud,
      isLoading: false,
    );
  }
}

enum _WeatherCondition { sun, cloud, rain, fog, snow, storm }

class _WeatherLocationPanel extends StatelessWidget {
  const _WeatherLocationPanel({
    required this.weather,
    required this.locationLabel,
    required this.isLoadingLocation,
    required this.showLoading,
    this.note,
  });

  final _WeatherInfo weather;
  final String locationLabel;
  final bool isLoadingLocation;
  final bool showLoading;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final palette = _weatherPalette(weather.condition);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 132),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.base,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: palette.gradient),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _WeatherSceneryPainter(palette.accent)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child:
                      weather.isLoading && showLoading
                          ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                          : Icon(weather.icon, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text(
                            weather.temperatureLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              height: 0.95,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            weather.isLoading && !showLoading
                                ? 'Weer'
                                : weather.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (isLoadingLocation && showLoading)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              locationLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            note!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _WeatherPalette _weatherPalette(_WeatherCondition condition) {
    switch (condition) {
      case _WeatherCondition.sun:
        return const _WeatherPalette(
          gradient: LinearGradient(
            colors: [Color(0xFF3C82B7), Color(0xFF5D8FA0), Color(0xFFDDA961)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          base: Color(0xFF3C82B7),
          accent: Color(0xFFDDA961),
          shadow: Color(0xFF5D8FA0),
        );
      case _WeatherCondition.rain:
      case _WeatherCondition.storm:
        return const _WeatherPalette(
          gradient: LinearGradient(
            colors: [Color(0xFF465D68), Color(0xFF24343D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          base: Color(0xFF465D68),
          accent: Color(0xFF8AA0A8),
          shadow: Color(0xFF516A78),
        );
      case _WeatherCondition.snow:
      case _WeatherCondition.fog:
        return const _WeatherPalette(
          gradient: LinearGradient(
            colors: [Color(0xFF8BA1A7), Color(0xFF516A70)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          base: Color(0xFF8BA1A7),
          accent: Color(0xFFC4D1D3),
          shadow: Color(0xFF8FA6AD),
        );
      case _WeatherCondition.cloud:
        return const _WeatherPalette(
          gradient: LinearGradient(
            colors: [Color(0xFF6D8794), Color(0xFF36525C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          base: Color(0xFF6D8794),
          accent: Color(0xFFAFC1C6),
          shadow: Color(0xFF7D97A5),
        );
    }
  }
}

class _WeatherPalette {
  const _WeatherPalette({
    required this.gradient,
    required this.base,
    required this.accent,
    required this.shadow,
  });

  final LinearGradient gradient;
  final Color base;
  final Color accent;
  final Color shadow;
}

class _WeatherSceneryPainter extends CustomPainter {
  const _WeatherSceneryPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final sunPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              accent.withValues(alpha: 0.36),
              accent.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.78, size.height * 0.36),
              radius: size.width * 0.35,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.36),
      size.width * 0.35,
      sunPaint,
    );

    final horizonPaint =
        Paint()..color = const Color(0xFF123B31).withValues(alpha: 0.22);
    final horizon =
        Path()
          ..moveTo(0, size.height)
          ..lineTo(0, size.height * 0.82)
          ..cubicTo(
            size.width * 0.18,
            size.height * 0.70,
            size.width * 0.35,
            size.height * 0.86,
            size.width * 0.52,
            size.height * 0.76,
          )
          ..cubicTo(
            size.width * 0.72,
            size.height * 0.64,
            size.width * 0.86,
            size.height * 0.80,
            size.width,
            size.height * 0.70,
          )
          ..lineTo(size.width, size.height)
          ..close();
    canvas.drawPath(horizon, horizonPaint);
  }

  @override
  bool shouldRepaint(covariant _WeatherSceneryPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1D8A8)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7B7),
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFF8B5A00),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let op',
                  style: TextStyle(
                    color: ChallengeScreen.deepGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Het wandelpad bij Genneper Parken is tijdelijk afgesloten.',
                  style: TextStyle(
                    color: ChallengeScreen.mutedText,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionPanels extends StatelessWidget {
  const _HomeActionPanels({
    required this.onReportTap,
    required this.onLearnTap,
  });

  final VoidCallback onReportTap;
  final VoidCallback onLearnTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(18) > 24;
        final tiles = [
          _QuickActionTile(
            icon: Icons.visibility_outlined,
            title: 'Waarneming',
            assetPath: 'assets/real_animal_pics_no_bg/real_eekhoorn.png',
            onTap: onReportTap,
          ),
          _QuickActionTile(
            icon: Icons.school_outlined,
            title: 'Leer over dieren',
            assetPath: 'assets/real_animal_pics_no_bg/real_egel.png',
            onTap: onLearnTap,
          ),
        ];
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [tiles[0], const SizedBox(height: 12), tiles[1]],
          );
        }
        return Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 12),
            Expanded(child: tiles[1]),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.assetPath,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        height:
            154 +
            (MediaQuery.textScalerOf(context).scale(18) - 18).clamp(
                  0,
                  double.infinity,
                ) *
                2.1,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFBFCF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ChallengeScreen.fieldBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              const Positioned(
                left: -12,
                bottom: -16,
                child: _SoftLeaves(size: 88, opacity: 0.20),
              ),
              const Positioned(
                right: -16,
                bottom: -18,
                child: _SoftLeaves(size: 92, opacity: 0.22, mirror: true),
              ),
              Positioned(
                right: -10,
                bottom: -4,
                child: Image.asset(
                  assetPath,
                  height: 78,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(0.72),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: ChallengeScreen.softGreen,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Icon(
                            icon,
                            color: ChallengeScreen.deepGreen,
                            size: 26,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: ChallengeScreen.deepGreen,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ChallengeScreen.deepGreen,
                        fontSize: 18,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftLeaves extends StatelessWidget {
  const _SoftLeaves({
    required this.size,
    required this.opacity,
    this.mirror = false,
  });

  final double size;
  final double opacity;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final leaves = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: size * 0.08,
            bottom: size * 0.06,
            child: _SoftLeaf(
              width: size * 0.20,
              height: size * 0.70,
              angle: -0.55,
              opacity: opacity,
            ),
          ),
          Positioned(
            left: size * 0.32,
            bottom: 0,
            child: _SoftLeaf(
              width: size * 0.24,
              height: size * 0.84,
              angle: 0.18,
              opacity: opacity,
            ),
          ),
          Positioned(
            left: size * 0.58,
            bottom: size * 0.03,
            child: _SoftLeaf(
              width: size * 0.20,
              height: size * 0.62,
              angle: 0.58,
              opacity: opacity,
            ),
          ),
        ],
      ),
    );

    if (!mirror) return leaves;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(-1, 1, 1),
      child: leaves,
    );
  }
}

class _SoftLeaf extends StatelessWidget {
  const _SoftLeaf({
    required this.width,
    required this.height,
    required this.angle,
    required this.opacity,
  });

  final double width;
  final double height;
  final double angle;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF7BA987).withValues(alpha: opacity),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(width),
            topRight: Radius.circular(width),
            bottomLeft: Radius.circular(width * 0.22),
            bottomRight: Radius.circular(width * 0.22),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: ChallengeScreen.deepGreen,
        letterSpacing: 0,
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    const cards = [
      _StatCard(
        icon: Icons.visibility_outlined,
        value: '27',
        label: 'Waarnemingen',
      ),
      _StatCard(
        icon: Icons.pets_outlined,
        value: '14',
        label: 'Soorten gezien',
      ),
      _StatCard(icon: Icons.place_outlined, value: '8', label: 'Locaties'),
      _StatCard(
        icon: Icons.workspace_premium_outlined,
        value: '6',
        label: 'Badges',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(12) > 16;
        final width =
            stack ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFCFDF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChallengeScreen.fieldBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            const Positioned(
              left: -12,
              bottom: -24,
              child: _SoftLeaves(size: 70, opacity: 0.16),
            ),
            const Positioned(
              right: -16,
              bottom: -24,
              child: _SoftLeaves(size: 68, opacity: 0.12, mirror: true),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ChallengeScreen.softGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      color: ChallengeScreen.deepGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            color: ChallengeScreen.deepGreen,
                            fontSize: 22,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          style: const TextStyle(
                            color: ChallengeScreen.mutedText,
                            fontSize: 12,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChallengeScreen.fieldBorder),
      ),
      child: const Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 12,
        children: [
          _BadgeItem(icon: Icons.forest_outlined, label: 'Bos'),
          _BadgeItem(icon: Icons.pets_outlined, label: 'Dieren'),
          _BadgeItem(icon: Icons.camera_alt_outlined, label: 'Foto'),
          _BadgeItem(icon: Icons.lock_outline, label: 'Locked', locked: true),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.icon,
    required this.label,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.42 : 1,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  locked ? const Color(0xFFF1F1EF) : ChallengeScreen.softGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: locked ? Colors.grey.shade500 : ChallengeScreen.deepGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: ChallengeScreen.deepGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.value,
    required this.xp,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final String value;
  final String xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChallengeScreen.fieldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ChallengeScreen.softGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ChallengeScreen.deepGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ChallengeScreen.deepGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      xp,
                      style: const TextStyle(
                        color: ChallengeScreen.deepGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ChallengeScreen.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: ChallengeScreen.softGreen,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            ChallengeScreen.deepGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      value,
                      style: const TextStyle(
                        color: ChallengeScreen.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
