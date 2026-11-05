import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/living_labs_api.dart';
import 'package:wildgids/models/ui_models/weather_living_lab.dart';
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
  static const _preferredLabKey = 'home_preferred_living_lab';

  final _locationManager = LocationMapManager();
  List<WeatherLivingLab> _labs = const [];
  WeatherLivingLab? _selectedLab;
  bool _isLoadingLabs = false;
  String? _labsError;
  SharedPreferences? _preferences;
  String? _preferredLabId;
  Position? _userPosition;
  String _displayName = '';
  _WeatherInfo _weather = _WeatherInfo.loading();
  bool _isLoadingLocation = true;
  bool _showLoading = false;
  String? _weatherNote;
  Timer? _loadingTimer;
  int _weatherRequest = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileName();
    _initializeLivingLab();
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

  Future<void> _initializeLivingLab() async {
    if (_isLoadingLabs) return;
    setState(() {
      _isLoadingLabs = true;
      _labsError = null;
    });
    final api = LivingLabsApi(context.read<ApiClient>());
    final preferences = await SharedPreferences.getInstance();
    List<WeatherLivingLab> labs;
    String? error;
    try {
      labs = await api.getAll();
    } catch (_) {
      labs = await api.readCache();
      error =
          labs.isEmpty
              ? 'Living labs konden niet worden geladen.'
              : 'Opgeslagen living labs; bijwerken mislukt.';
    }
    if (!mounted) return;
    // Migrate the two old local IDs once; the selectable list is backend-owned.
    final savedId = switch (preferences.getString(_preferredLabKey)) {
      'np-zuid-kennemerland' => 'e376995e-5a79-413c-8906-4640dfc2f472',
      'grenspark-kempenbroek' => '72797cde-25d9-4a36-8b77-7f8d50691ac7',
      final id => id,
    };
    setState(() {
      _preferences = preferences;
      _labs = labs;
      _isLoadingLabs = false;
      _labsError = error;
      _preferredLabId = _labs.any((lab) => lab.id == savedId) ? savedId : null;
      _selectedLab =
          _labs.isEmpty
              ? null
              : _labs.firstWhere(
                (lab) => lab.id == _preferredLabId,
                orElse: () => _labs.first,
              );
    });
    if (_preferredLabId != null) {
      await preferences.setString(_preferredLabKey, _preferredLabId!);
    }
    if (!mounted || _labs.isEmpty) return;
    // A saved choice can show weather while distance is being determined.
    if (_preferredLabId != null) unawaited(_loadWeather(_selectedLab!));
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
      if (!_isRecentPosition(position)) {
        position = await Geolocator.getLastKnownPosition().timeout(
          const Duration(seconds: 3),
        );
      }
      if (!_isRecentPosition(position)) {
        position = await _locationManager.determinePosition().timeout(
          const Duration(seconds: 6),
        );
      }
      if (position == null) {
        throw Exception('Geen locatie beschikbaar');
      }

      if (!mounted) return;
      setState(() {
        _userPosition = position;
        _isLoadingLocation = false;
        if (_preferredLabId == null) _selectedLab = _nearestLab();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
    }
    if (_preferredLabId == null && mounted) await _loadWeather(_selectedLab!);
  }

  bool _isRecentPosition(Position? position) {
    if (position == null) return false;
    final age = DateTime.now().difference(position.timestamp);
    return age >= Duration.zero && age < const Duration(minutes: 10);
  }

  double _distanceTo(WeatherLivingLab lab) => Geolocator.distanceBetween(
    _userPosition!.latitude,
    _userPosition!.longitude,
    lab.center!.latitude,
    lab.center!.longitude,
  );

  WeatherLivingLab _nearestLab() {
    if (_userPosition == null) return _labs.first;
    final located = _labs.where((lab) => lab.center != null);
    if (located.isEmpty) return _labs.first;
    return located.reduce((a, b) => _distanceTo(a) <= _distanceTo(b) ? a : b);
  }

  String _distanceLabel(WeatherLivingLab lab, {bool compact = false}) {
    if (lab.center == null) return 'Gebiedslocatie niet beschikbaar';
    if (_isLoadingLocation) return 'Afstand bepalen...';
    if (_userPosition == null) {
      return compact
          ? 'Locatie niet beschikbaar'
          : 'Afstand onbekend · locatie niet beschikbaar';
    }
    final km = _distanceTo(lab) / 1000;
    final amount = km < 1 ? '< 1' : '± ${km.round()}';
    return compact
        ? '$amount km hemelsbreed'
        : '$amount km hemelsbreed tot het gebiedscentrum';
  }

  String get _selectionLabel {
    if (_preferredLabId != null) return 'Jouw living lab';
    if (_isLoadingLocation) return 'Living lab bepalen...';
    return _userPosition == null
        ? 'Living lab · standaardkeuze'
        : 'Dichtstbijzijnde living lab';
  }

  Future<void> _chooseLab(String? id) async {
    setState(() {
      _preferredLabId = id;
      _selectedLab =
          id == null ? _nearestLab() : _labs.firstWhere((lab) => lab.id == id);
    });
    unawaited(_loadWeather(_selectedLab!));
    if (id == null) {
      await _preferences?.remove(_preferredLabKey);
    } else {
      await _preferences?.setString(_preferredLabKey, id);
    }
  }

  void _showLabPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (sheetContext) => SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Kies je living lab',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _selectionLabel,
                        style: const TextStyle(
                          color: ChallengeScreen.mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final lab in _labs)
                      ListTile(
                        key: ValueKey('choose-${lab.id}'),
                        leading: const Icon(Icons.park_outlined),
                        title: Text(lab.name),
                        subtitle: Text(_distanceLabel(lab)),
                        trailing:
                            lab.id == _selectedLab?.id
                                ? const Icon(
                                  Icons.check,
                                  color: ChallengeScreen.deepGreen,
                                )
                                : null,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          unawaited(_chooseLab(lab.id));
                        },
                      ),
                    const Divider(),
                    ListTile(
                      key: const ValueKey('choose-nearest-lab'),
                      leading: const Icon(Icons.near_me_outlined),
                      title: const Text('Dichtstbijzijnde gebruiken'),
                      subtitle:
                          _userPosition == null
                              ? const Text(
                                'Locatie nodig voor automatische keuze',
                              )
                              : null,
                      enabled: _userPosition != null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        unawaited(_chooseLab(null));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  _WeatherCache? _readWeatherCache(WeatherLivingLab lab) {
    try {
      final raw = _preferences?.getString('home_lab_weather_${lab.id}');
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return _WeatherCache(
        _WeatherInfo.fromCode(
          temperature: (data['temperature'] as num).round(),
          code: data['code'] as int,
          isDay: data['isDay'] as bool,
        ),
        DateTime.parse(data['fetchedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadWeather(WeatherLivingLab lab) async {
    final request = ++_weatherRequest;
    _loadingTimer?.cancel();
    if (lab.center == null) {
      setState(() {
        _weather = _WeatherInfo.unavailable();
        _weatherNote = 'Deze living lab heeft nog geen gebiedslocatie.';
        _showLoading = false;
      });
      return;
    }
    final cached = _readWeatherCache(lab);
    final age =
        cached == null ? null : DateTime.now().difference(cached.fetchedAt);
    final usableCache =
        cached != null &&
        age! >= Duration.zero &&
        age < const Duration(hours: 1);
    if (!mounted) return;
    setState(() {
      _weather = usableCache ? cached.weather : _WeatherInfo.loading();
      _weatherNote = null;
      _showLoading = false;
    });
    if (usableCache && age < const Duration(minutes: 10)) return;
    if (!usableCache) {
      _loadingTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && request == _weatherRequest && _weather.isLoading) {
          setState(() => _showLoading = true);
        }
      });
    }
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lab.center!.latitude.toStringAsFixed(4),
        'longitude': lab.center!.longitude.toStringAsFixed(4),
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
      if (!mounted || request != _weatherRequest) return;
      setState(() {
        _weather = nextWeather;
        _weatherNote = null;
      });
      // Cache each lab independently, including across app restarts.
      try {
        await _preferences?.setString(
          'home_lab_weather_${lab.id}',
          jsonEncode({
            'temperature': temperature,
            'code': weatherCode,
            'isDay': isDay,
            'fetchedAt': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {
        // A storage failure must not hide a successful weather response.
      }
    } catch (_) {
      if (!mounted || request != _weatherRequest) return;
      setState(() {
        if (usableCache) {
          _weatherNote = 'Laatst opgehaald; bijwerken mislukt';
        } else {
          _weather = _WeatherInfo.unavailable();
        }
      });
    }
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
              const _HomeBrand(),
              const SizedBox(height: 24),
              _HomeHeader(greeting: _greeting, name: _displayName),
              const SizedBox(height: 18),
              if (_selectedLab != null)
                _WeatherLocationPanel(
                  weather: _weather,
                  lab: _selectedLab!,
                  selectionLabel: _selectionLabel,
                  distanceLabel: _distanceLabel(_selectedLab!, compact: true),
                  onChooseLab: _isLoadingLabs ? null : _showLabPicker,
                  showLoading: _showLoading,
                  note: _weatherNote,
                ),
              if (_selectedLab == null || _labsError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labsError ??
                            (_isLoadingLabs
                                ? 'Living labs laden...'
                                : 'Geen living labs beschikbaar.'),
                      ),
                      if (!_isLoadingLabs)
                        TextButton.icon(
                          onPressed: _initializeLivingLab,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Opnieuw proberen'),
                        ),
                    ],
                  ),
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

class _HomeBrand extends StatelessWidget {
  const _HomeBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/logo-wildlife.svg',
          width: 40,
          height: 40,
          excludeFromSemantics: true,
          colorFilter: const ColorFilter.mode(
            ChallengeScreen.deepGreen,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Wild Gids',
            style: TextStyle(
              color: ChallengeScreen.deepGreen,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
        ),
      ],
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
                    fontSize: 32,
                    height: 1.12,
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
  const _WeatherCache(this.weather, this.fetchedAt);
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
    required this.lab,
    required this.selectionLabel,
    required this.distanceLabel,
    required this.onChooseLab,
    required this.showLoading,
    this.note,
  });

  final _WeatherInfo weather;
  final WeatherLivingLab lab;
  final String selectionLabel;
  final String distanceLabel;
  final VoidCallback? onChooseLab;
  final bool showLoading;
  final String? note;

  String get _shortName => lab.name;

  Color get _iconColor {
    if (weather.isLoading || weather.description == 'Weer niet beschikbaar') {
      return ChallengeScreen.mutedText;
    }
    return switch (weather.condition) {
      _WeatherCondition.sun =>
        weather.icon == Icons.nightlight_round
            ? const Color(0xFF536381)
            : const Color(0xFFAA7011),
      _WeatherCondition.rain => const Color(0xFF396B86),
      _WeatherCondition.snow => const Color(0xFF467888),
      _WeatherCondition.storm => const Color(0xFF655778),
      _WeatherCondition.cloud ||
      _WeatherCondition.fog => const Color(0xFF65747A),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-weather-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ChallengeScreen.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: 'Living lab wijzigen',
            child: Semantics(
              button: true,
              label: '$selectionLabel: ${lab.name}. Living lab wijzigen',
              excludeSemantics: true,
              child: InkWell(
                key: const ValueKey('living-lab-selector'),
                onTap: onChooseLab,
                borderRadius: BorderRadius.circular(4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                        color: ChallengeScreen.deepGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _shortName,
                          style: const TextStyle(
                            color: ChallengeScreen.deepGreen,
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more,
                        color: ChallengeScreen.deepGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      weather.temperatureLabel,
                      style: const TextStyle(
                        color: ChallengeScreen.deepGreen,
                        fontSize: 38,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      weather.isLoading && !showLoading
                          ? 'Weer'
                          : weather.description,
                      style: const TextStyle(
                        color: ChallengeScreen.mutedText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                height: 48,
                child:
                    weather.isLoading && showLoading
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ChallengeScreen.deepGreen,
                          ),
                        )
                        : Icon(
                          weather.icon,
                          key: const ValueKey('home-weather-icon'),
                          color: _iconColor,
                          size: 40,
                        ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            distanceLabel,
            style: const TextStyle(
              color: ChallengeScreen.mutedText,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: const TextStyle(
                color: ChallengeScreen.mutedText,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard();

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChallengeScreen.pageBackground,
      builder:
          (sheetContext) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Voorbeeldmelding',
                          style: TextStyle(
                            color: Color(0xFF8B5A00),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sluiten',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(
                          Icons.close,
                          color: ChallengeScreen.deepGreen,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Wandelpad afgesloten',
                    style: TextStyle(
                      color: ChallengeScreen.deepGreen,
                      fontSize: 24,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Het wandelpad bij Genneper Parken is tijdelijk afgesloten.',
                    style: TextStyle(
                      color: ChallengeScreen.deepGreen,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dit is een voorbeeld om te laten zien hoe meldingen eruitzien. '
                    'De afsluiting is niet bevestigd en deze melding hoort niet '
                    'bij het geselecteerde living lab.',
                    style: TextStyle(
                      color: ChallengeScreen.mutedText,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFAF1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFF1D8A8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('home-announcement'),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFF8B5A00),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wandelpad afgesloten',
                      style: TextStyle(
                        color: ChallengeScreen.deepGreen,
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Voorbeeld',
                      style: TextStyle(
                        color: Color(0xFF8B5A00),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: ChallengeScreen.deepGreen,
                size: 22,
              ),
            ],
          ),
        ),
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
    const foreground = ChallengeScreen.deepGreen;
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
            colors: [Color(0xFFF0F5E9), Color(0xFFE1EDD7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC9DABA)),
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
                right: 0,
                bottom: 0,
                child: Image.asset(
                  assetPath,
                  height: 70,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(1.0),
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
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: ChallengeScreen.softGreen,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: Icon(icon, color: foreground, size: 24),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: foreground,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
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
          _BadgeItem(
            icon: Icons.forest_rounded,
            label: 'Bos',
            background: Color(0xFFE1EFDD),
            accent: Color(0xFF326343),
          ),
          _BadgeItem(
            icon: Icons.pets_rounded,
            label: 'Dieren',
            background: Color(0xFFFFEDC6),
            accent: Color(0xFF8A570D),
          ),
          _BadgeItem(
            icon: Icons.photo_camera_rounded,
            label: 'Foto',
            background: Color(0xFFE0EDF8),
            accent: Color(0xFF336387),
          ),
          _BadgeItem(
            icon: Icons.lock_outline_rounded,
            label: 'Vergrendeld',
            background: Color(0xFFEEEEEC),
            accent: Color(0xFF667064),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.background,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: ValueKey('home-badge-$label'),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: accent, size: 28),
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
