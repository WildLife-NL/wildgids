import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/screens/shared/overzicht_screen.dart';
import 'package:wildgids/utils/species_click_tracker.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/widgets/animals/scrollable_animal_grid.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/location/kaart_overview_screen.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/profile/profile_screen.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';

class SpeciesListScreen extends StatefulWidget {
  const SpeciesListScreen({super.key});

  @override
  State<SpeciesListScreen> createState() => _SpeciesListScreenState();
}

class _SpeciesListScreenState extends State<SpeciesListScreen> {
  late Future<List<Species>> _futureSpecies;
  final ScrollController _scrollController = ScrollController();

  List<Species> _allSpecies = [];
  List<AnimalModel>? _animals;
  List<String> _categories = ['Alle'];
  String _selectedCategory = 'Alle';

  bool _isLoading = true;
  String? _error;

void _onTabSelected(NavTab tab) {
  final nav = context.read<NavigationStateInterface>();

  switch (tab) {
    case NavTab.soorten:
    case NavTab.zones:
      return;

    case NavTab.rapporten:
      nav.pushReplacementForward(
        context,
        const WaarnemmingStartScreen(),
      );
      break;

    case NavTab.kaart:
      nav.pushReplacementForward(
        context,
        const KaartOverviewScreen(),
      );
      break;

    case NavTab.logboek:
      nav.pushReplacementForward(
        context,
        const LogbookScreen(),
      );
      break;

    case NavTab.instellingen:
    case NavTab.profile:
      nav.pushReplacementForward(
        context,
        const ProfileScreen(),
      );
      break;
  }
}

  @override
  void initState() {
    super.initState();
    final api = context.read<SpeciesApiInterface>();
    _futureSpecies = api.getAllSpecies();
    _loadSpecies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecies() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final species = await _futureSpecies;
      _allSpecies = species;

      final categories = species
          .map((s) => s.category)
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final filteredSpecies = _selectedCategory == 'Alle'
          ? species
          : species.where((s) => s.category == _selectedCategory).toList();

      final animals = filteredSpecies.map((s) {
        final name = s.commonName.isNotEmpty
            ? s.commonName
            : (s.latinName ?? 'Onbekend');

        return AnimalModel(
          animalId: s.id,
          animalName: name,
          animalImagePath: SpeciesImageResolver.drawingForCommonName(
            s.commonName,
          ),
          genderViewCounts: [],
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _categories = ['Alle', ...categories];
        _animals = animals;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleBackNavigation() {
    final nav = context.read<NavigationStateInterface>();
    nav.pushAndRemoveUntil(context, const OverzichtScreen());
  }

  Future<void> _handleSpeciesSelection(AnimalModel animal) async {
    final selectedSpecies = _allSpecies.firstWhere(
      (s) => s.id == animal.animalId,
      orElse: () => _allSpecies.firstWhere(
        (s) {
          final name = s.commonName.isNotEmpty
              ? s.commonName
              : (s.latinName ?? 'Onbekend');
          return name == animal.animalName;
        },
      ),
    );

    await SpeciesClickTracker.markClicked(selectedSpecies.id);

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpeciesDetailScreen(species: selectedSpecies),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleCategoryChanged(String value) async {
    setState(() {
      _selectedCategory = value;
    });

    await _loadSpecies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Soorten',
              rightIcon: null,
              showUserIcon: false,
              useFixedText: true,
              onLeftIconPressed: _handleBackNavigation,
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.4,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 12, 0, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Klik op een dier om er meer over te leren:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: Color(0xFF999999),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            bottom: 8,
                          ),
                          child: Text(
                            'Categorie',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.15),
                              width: 1.2,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(12),
                              dropdownColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black.withValues(alpha: 0.6),
                                size: 24,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _handleCategoryChanged(value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ScrollableAnimalGrid(
                            animals: _animals,
                            isLoading: _isLoading,
                            error: _error,
                            scrollController: _scrollController,
                            onAnimalSelected: _handleSpeciesSelection,
                            onRetry: _loadSpecies,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
  top: false,
  child: CustomNavBar(
    currentTab: NavTab.zones,
    onTabSelected: _onTabSelected,
  ),
),
    );
  }
}

class SpeciesDetailScreen extends StatefulWidget {
  final Species species;

  const SpeciesDetailScreen({super.key, required this.species});

  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showImageViewer(BuildContext context, String path) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sluiten',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.asset(
                      path,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final species = widget.species;
    final title = species.commonName.isNotEmpty
        ? species.commonName
        : (species.latinName ?? 'Soort');

    final headerImageDrawing =
        SpeciesImageResolver.drawingForCommonName(species.commonName);

    return Scaffold(
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.only(
                top: 48,
                left: 8,
                right: 20,
                bottom: 16,
              ),
              color: AppColors.darkGreen,
              child: SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          species.category,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 72,
                          height: 72,
                          color: Colors.white.withValues(alpha: 0.2),
                          child: FutureBuilder<bool>(
                            future: SpeciesClickTracker.isClicked(species.id),
                            builder: (context, snapshot) {
                              final clicked = snapshot.data ?? false;

                              final path = clicked
                                  ? SpeciesImageResolver.realForCommonName(
                                      species.commonName,
                                    )
                                  : headerImageDrawing;

                              if (path == null) {
                                return const Center(
                                  child: Icon(
                                    Icons.pets,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () => _showImageViewer(context, path),
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Image.asset(
                                    path,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Center(
                                      child: Icon(
                                        Icons.pets,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(height: 6, color: Colors.white),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned(
                          right: 0,
                          top: 24,
                          child: _stackedLayer(widthFactor: 0.92),
                        ),
                        Positioned(
                          right: 8,
                          top: 12,
                          child: _stackedLayer(widthFactor: 0.96),
                        ),
                        _pageCardContainer(
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: 4,
                                onPageChanged: (i) {
                                  setState(() => _currentPage = i);
                                },
                                itemBuilder: (context, index) {
                                  final titles = const [
                                    'Omschrijving',
                                    'Gedrag',
                                    'Rol in de natuur',
                                    'Advies',
                                  ];

                                  final includes = const [
                                    ['description'],
                                    ['behaviour'],
                                    ['roleInNature'],
                                    ['advice'],
                                  ];

                                  return AnimatedBuilder(
                                    animation: _pageController,
                                    builder: (context, child) {
                                      double t = 0.0;

                                      if (_pageController
                                          .position.hasContentDimensions) {
                                        final current = _pageController.page ??
                                            _currentPage.toDouble();
                                        t = current - index.toDouble();
                                      } else {
                                        t = _currentPage.toDouble() -
                                            index.toDouble();
                                      }

                                      final scale = 1.0 -
                                          (t.abs() * 0.06).clamp(0.0, 0.06);
                                      final opacity = 1.0 -
                                          (t.abs() * 0.35).clamp(0.0, 0.35);

                                      return Transform.scale(
                                        scale: scale,
                                        child: Opacity(
                                          opacity: opacity,
                                          child: _contentCard(
                                            title: titles[index],
                                            text: _composeText(
                                              species,
                                              include: includes[index],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: _currentPage > 0
                                      ? () => _pageController.previousPage(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            curve: Curves.easeInOut,
                                          )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: _currentPage < 3
                                      ? () => _pageController.nextPage(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            curve: Curves.easeInOut,
                                          )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _chip('OMSCHRIJVING', 0)),
                          const SizedBox(width: 12),
                          Expanded(child: _chip('GEDRAG', 1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _chip('ROL IN DE NATUUR', 2)),
                          const SizedBox(width: 12),
                          Expanded(child: _chip('ADVIES', 3)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _composeText(Species s, {required List<String> include}) {
    final parts = <String?>[];

    if (include.contains('description')) parts.add(s.description);
    if (include.contains('behaviour')) parts.add(s.behaviour);
    if (include.contains('roleInNature')) parts.add(s.roleInNature);
    if (include.contains('advice')) parts.add(s.advice);

    return parts.where((p) => (p ?? '').isNotEmpty).cast<String>().join('\n\n');
  }

  Widget _chip(String label, int page) {
    final selected = _currentPage == page;

    return ElevatedButton(
      onPressed: () => _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor:
            selected ? AppColors.darkGreen : AppColors.lightMintGreen,
        foregroundColor: selected ? Colors.white : AppColors.brown,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkGreen),
        ),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _pageCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 440,
      decoration: BoxDecoration(
        color: AppColors.darkGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _stackedLayer({required double widthFactor}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 420,
        decoration: BoxDecoration(
          color: AppColors.darkGreen,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _contentCard({
    required String title,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              text.isNotEmpty ? text : '—',
              style: const TextStyle(
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}