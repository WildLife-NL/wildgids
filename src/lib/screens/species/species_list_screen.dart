import 'package:wildgids/widgets/guide/animal_name.dart';
import 'package:flutter/material.dart';
import 'package:wildgids/widgets/shared_ui_widgets/category_picker.dart';
import 'package:wildgids/screens/species/species_detail_screen.dart';
export 'package:wildgids/screens/species/species_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_model.dart';
import 'package:wildgids/utils/species_click_tracker.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/widgets/guide/animal_artwork.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
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

      final categories =
          species
              .map((s) => s.category)
              .where((c) => c.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      final filteredSpecies =
          _selectedCategory == 'Alle'
              ? species
              : species.where((s) => s.category == _selectedCategory).toList();

      final animals =
          filteredSpecies.map((s) {
            final name =
                s.commonName.isNotEmpty
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
    Navigator.of(context).pop();
  }

  Future<void> _handleSpeciesSelection(AnimalModel animal) async {
    final selectedSpecies = _allSpecies.firstWhere(
      (s) => s.id == animal.animalId,
      orElse:
          () => _allSpecies.firstWhere((s) {
            final name =
                s.commonName.isNotEmpty
                    ? s.commonName
                    : (s.latinName ?? 'Onbekend');
            return name == animal.animalName;
          }),
    );

    await SpeciesClickTracker.markClicked(selectedSpecies.id);

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => SpeciesDetailScreen(
              species: selectedSpecies,
              onTabSelected: _onTabSelected,
            ),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _handleCategoryChanged(String value) async {
    setState(() {
      _selectedCategory = value;
    });

    await _loadSpecies();
  }

  void _retrySpecies() {
    _futureSpecies = context.read<SpeciesApiInterface>().getAllSpecies();
    _loadSpecies();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GuideStyle.background,
    appBar: AppBar(
      backgroundColor: GuideStyle.background,
      foregroundColor: GuideStyle.ink,
      title: const Text('Dierengids'),
      leading: BackButton(onPressed: _handleBackNavigation),
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leer de dieren kennen',
                        style: TextStyle(
                          fontSize: 34,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: GuideStyle.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kies een dier en ontdek meer.',
                        style: TextStyle(
                          color: GuideStyle.muted,
                          fontSize: 17,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CategoryPicker(
                        categories: _categories,
                        selected: _selectedCategory,
                        enabled: !_isLoading && _error == null,
                        onChanged: _handleCategoryChanged,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: GuideStyle.ink),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _GuideMessage(
                    text: 'De dieren konden niet worden geladen.',
                    onRetry: _retrySpecies,
                  ),
                )
              else if (_animals == null || _animals!.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _GuideMessage(
                    text: 'Geen dieren gevonden in deze categorie.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: AnimalName.gridColumns(
                        context,
                        _animals!.map((animal) => animal.animalName),
                        width:
                            MediaQuery.sizeOf(
                              context,
                            ).width.clamp(0, 680).toDouble() -
                            40,
                      ),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                      mainAxisExtent:
                          225 +
                          (MediaQuery.textScalerOf(context).scale(1) - 1) * 90,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final animal = _animals![index];
                      return _GuideAnimalTile(
                        animal: animal,
                        onTap: () => _handleSpeciesSelection(animal),
                      );
                    }, childCount: _animals!.length),
                  ),
                ),
            ],
          ),
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

class _GuideAnimalTile extends StatelessWidget {
  const _GuideAnimalTile({required this.animal, required this.onTap});
  final AnimalModel animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: GuideStyle.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: GuideStyle.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AnimalArtwork(
              imagePath: animal.animalImagePath,
              zoom: animal.animalName.toLowerCase() == 'egel' ? 1.32 : 1.10,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AnimalName(
                    animal.animalName,
                    style: const TextStyle(
                      color: GuideStyle.ink,
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                FutureBuilder<bool>(
                  future: SpeciesClickTracker.isClicked(animal.animalId ?? ''),
                  builder:
                      (context, snapshot) =>
                          snapshot.data == true
                              ? const Tooltip(
                                message: 'Al bekeken',
                                child: Icon(
                                  Icons.check_circle_outline,
                                  color: GuideStyle.ink,
                                  size: 20,
                                ),
                              )
                              : const Icon(
                                Icons.chevron_right_rounded,
                                color: GuideStyle.ink,
                                size: 20,
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

class _GuideMessage extends StatelessWidget {
  const _GuideMessage({required this.text, this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.pets_outlined, color: GuideStyle.ink, size: 36),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: GuideStyle.muted, fontSize: 17),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Opnieuw proberen')),
      ],
    ),
  );
}
