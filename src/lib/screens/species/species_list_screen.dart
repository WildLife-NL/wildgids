import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
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
import 'package:wildgids/screens/game/challenge_screen.dart';

class SpeciesListScreen extends StatefulWidget {
  final bool showBottomNav;

  const SpeciesListScreen({super.key, this.showBottomNav = true});

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
      case NavTab.ontdekken:
        nav.pushReplacementForward(context, const ChallengeScreen());
        break;
      case NavTab.zones:
        return;
      case NavTab.waarneming:
        nav.pushReplacementForward(context, const WaarnemmingStartScreen());
        break;
      case NavTab.kaart:
        nav.pushReplacementForward(context, const KaartOverviewScreen());
        break;
      case NavTab.logboek:
        nav.pushReplacementForward(context, const LogbookScreen());
        break;
      case NavTab.instellingen:
      case NavTab.profile:
        nav.pushReplacementForward(context, const ProfileScreen());
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
        final name =
            s.commonName.isNotEmpty ? s.commonName : (s.latinName ?? 'Onbekend');

        return AnimalModel(
          animalId: s.id,
          animalName: name,
          animalImagePath:
              SpeciesImageResolver.drawingForCommonName(s.commonName),
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
    Navigator.of(context).pop();
  }

  Future<void> _handleSpeciesSelection(AnimalModel animal) async {
    final selectedSpecies = _allSpecies.firstWhere(
      (s) => s.id == animal.animalId,
      orElse: () => _allSpecies.firstWhere((s) {
        final name =
            s.commonName.isNotEmpty ? s.commonName : (s.latinName ?? 'Onbekend');
        return name == animal.animalName;
      }),
    );

    await SpeciesClickTracker.markClicked(selectedSpecies.id);

    if (!mounted) return;

    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: selectedSpecies)));

    if (mounted) setState(() {});
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
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
                                color: AppColors.borderDefault,
                                width: 1.2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(12),
                              dropdownColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 5),
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.black,
                                size: 24,
                              ),
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87),
                              items: _categories.map((category) {
                                return DropdownMenuItem<String>(
                                    value: category, child: Text(category));
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) _handleCategoryChanged(value);
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
      bottomNavigationBar: widget.showBottomNav
          ? SafeArea(
              top: false,
              child: CustomNavBar(
                  currentTab: NavTab.ontdekken, onTabSelected: _onTabSelected),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Detail screen
// ─────────────────────────────────────────────────────────────

class SpeciesDetailScreen extends StatefulWidget {
  final Species species;

  const SpeciesDetailScreen({super.key, required this.species});

  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  final List<bool> _expanded = [true, false, false, false];

  String _composeText(Species s, {required List<String> include}) {
    final parts = <String?>[];
    if (include.contains('description')) parts.add(s.description);
    if (include.contains('behaviour')) parts.add(s.behaviour);
    if (include.contains('roleInNature')) parts.add(s.roleInNature);
    if (include.contains('advice')) parts.add(s.advice);
    return parts
        .where((p) => (p ?? '').isNotEmpty)
        .cast<String>()
        .join('\n\n');
  }

  // ── Slick section tile ──────────────────────────────────────
  Widget _buildSection({
    required String title,
    required String body,
    required int index,
    required IconData icon,
  }) {
    final isOpen = _expanded[index];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFF7FAF7) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOpen
              ? AppColors.primaryGreen
              : AppColors.borderDefault,
          width: 1,
        ),
      ),
      child: Theme(
        // Remove default ExpansionTile dividers
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded[index],
          onExpansionChanged: (v) => setState(() => _expanded[index] = v),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppColors.borderDefault,
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.darkCharcoal, size: 18),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
          ),
          trailing: AnimatedRotation(
            turns: isOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.darkGreen,
              size: 22,
            ),
          ),
          children: [
            Text(
              body.isNotEmpty ? body : '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.75,
                    fontSize: 15,
                  ),
            ),
          ],
        ),
      ),
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
      backgroundColor: const Color(0xFFF5F6F4),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.only(top: 48, left: 8, right: 20, bottom: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.darkGreen, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: -0.3,
                            ),
                      ),
                      if (species.latinName != null &&
                          species.latinName!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          species.latinName!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black38,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.2,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      if (species.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            species.category,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  letterSpacing: 0.4,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Invisible spacer to keep title centred
                const SizedBox(width: 48),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE8E8E8)),

          // ── Card ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.80,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.borderDefault, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Species image ─────────────────
                        Center(
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAF7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.borderDefault,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: FutureBuilder<bool>(
                                future:
                                    SpeciesClickTracker.isClicked(species.id),
                                builder: (context, snapshot) {
                                  final clicked = snapshot.data ?? false;
                                  final path = clicked
                                      ? SpeciesImageResolver
                                          .realForCommonName(species.commonName)
                                      : headerImageDrawing;
                                  if (path == null) {
                                    return const Center(
                                      child: Icon(Icons.pets,
                                          color: AppColors.darkCharcoal, size: 48),
                                    );
                                  }
                                  return Image.asset(path, fit: BoxFit.cover);
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Sections ──────────────────────
                        _buildSection(
                          title: 'Omschrijving',
                          body: _composeText(species,
                              include: ['description']),
                          index: 0,
                          icon: Icons.info_outline_rounded,
                        ),
                        _buildSection(
                          title: 'Gedrag',
                          body: _composeText(species,
                              include: ['behaviour']),
                          index: 1,
                          icon: Icons.psychology_outlined,
                        ),
                        _buildSection(
                          title: 'Rol in de natuur',
                          body: _composeText(species,
                              include: ['roleInNature']),
                          index: 2,
                          icon: Icons.park_outlined,
                        ),
                        _buildSection(
                          title: 'Advies',
                          body: _composeText(species,
                              include: ['advice']),
                          index: 3,
                          icon: Icons.lightbulb_outline_rounded,
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}