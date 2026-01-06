import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/data_apis/species_api_interface.dart';
import 'package:wildgids/models/api_models/species.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/utils/species_click_tracker.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/screens/shared/overzicht_screen.dart';

// Image resolution now handled by SpeciesImageResolver + SpeciesClickTracker

class SpeciesListScreen extends StatefulWidget {
  const SpeciesListScreen({super.key});

  @override
  State<SpeciesListScreen> createState() => _SpeciesListScreenState();
}

class _SpeciesListScreenState extends State<SpeciesListScreen> {
  late Future<List<Species>> _futureSpecies;
  List<Species> _all = [];
  List<Species> _filtered = [];
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final api = context.read<SpeciesApiInterface>();
    _futureSpecies = api.getAllSpecies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            // Go back to Overzicht explicitly to avoid black screen from empty stack
            final nav = context.read<NavigationStateInterface>();
            nav.pushAndRemoveUntil(context, const OverzichtScreen());
          },
          tooltip: 'Terug',
        ),
        title: const Text('Soorten', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: AppColors.lightMintGreen,
        elevation: 0,
      ),
      body: FutureBuilder<List<Species>>(
        future: _futureSpecies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Fout bij laden: ${snapshot.error}'));
          }
          final species = snapshot.data ?? [];
          if (_all.isEmpty && species.isNotEmpty) {
            _all = species;
            _filtered = species;
          }
          if (_filtered.isEmpty) {
            return const Center(child: Text('Geen soorten gevonden'));
          }
          return Column(
            children: [
              // Search + toggle bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.lightMintGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkGreen, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.darkGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'zoeken',
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (val) {
                            final q = val.trim().toLowerCase();
                            setState(() {
                              _filtered = _all.where((s) {
                                final name = s.commonName.toLowerCase();
                                final latin = (s.latinName ?? '').toLowerCase();
                                return name.contains(q) || latin.contains(q);
                              }).toList();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ViewToggle(
                        isGrid: _isGridView,
                        onChanged: (isGrid) => setState(() => _isGridView = isGrid),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _isGridView
                      ? _SpeciesGrid(species: _filtered, onChanged: () => setState(() {}))
                      : _SpeciesList(species: _filtered, onChanged: () => setState(() {})),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onChanged;

  const _ViewToggle({required this.isGrid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkGreen, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(
            selected: isGrid,
            icon: Icons.grid_view_rounded,
            onTap: () => onChanged(true),
          ),
          _toggleButton(
            selected: !isGrid,
            icon: Icons.view_list_rounded,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({required bool selected, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? AppColors.brown : AppColors.lightMintGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: selected ? Colors.white : AppColors.brown),
      ),
    );
  }
}

class _SpeciesGrid extends StatelessWidget {
  final List<Species> species;
  final VoidCallback? onChanged;
  const _SpeciesGrid({required this.species, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 40.0;
    const gaps = 12.0 * 2;
    final tileWidth = (screenWidth - horizontalPadding - gaps) / 3;
    final tileHeight = tileWidth + 50;

    return SingleChildScrollView(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: species.map((s) {
          return SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: _SpeciesTile(species: s, onChanged: onChanged),
          );
        }).toList(),
      ),
    );
  }
}

class _SpeciesTile extends StatelessWidget {
  final Species species;
  final VoidCallback? onChanged;
  const _SpeciesTile({required this.species, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await SpeciesClickTracker.markClicked(species.id);
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: species)),
        );
        if (onChanged != null) onChanged!();
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.darkGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 0,
      ),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.darkGreen,
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  color: AppColors.darkGreen,
                  child: FutureBuilder<bool>(
                    future: SpeciesClickTracker.isClicked(species.id),
                    builder: (context, snapshot) {
                      final clicked = snapshot.data ?? false;
                      final path = clicked
                          ? SpeciesImageResolver.realForCommonName(species.commonName)
                          : SpeciesImageResolver.drawingForCommonName(species.commonName);
                      if (path == null) {
                        return const Center(child: Icon(Icons.pets, size: 64, color: Colors.white));
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          path,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.pets, size: 64, color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                species.commonName.isNotEmpty ? species.commonName : (species.latinName ?? 'Onbekend'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesList extends StatelessWidget {
  final List<Species> species;
  final VoidCallback? onChanged;
  const _SpeciesList({required this.species, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: species.length,
      padding: const EdgeInsets.only(bottom: 16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = species[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await SpeciesClickTracker.markClicked(s.id);
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: s)),
              );
              if (onChanged != null) onChanged!();
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                height: 72,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    _imageBox(commonName: s.commonName, speciesId: s.id),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.commonName.isNotEmpty ? s.commonName : (s.latinName ?? 'Onbekend'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            s.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _imageBox({required String commonName, required String speciesId}) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
      ),
      child: Container(
        width: 56,
        height: 56,
        color: AppColors.darkGreen,
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: FutureBuilder<bool>(
            future: SpeciesClickTracker.isClicked(speciesId),
            builder: (context, snapshot) {
              final clicked = snapshot.data ?? false;
              final path = clicked
                  ? SpeciesImageResolver.realForCommonName(commonName)
                  : SpeciesImageResolver.drawingForCommonName(commonName);
              if (path == null) {
                final fallback = SpeciesImageResolver.drawingForCommonName(commonName);
                if (fallback != null) {
                  return Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(fallback, fit: BoxFit.contain),
                  );
                }
                return const Icon(Icons.pets, color: Colors.white, size: 28);
              }
              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    final fallback = SpeciesImageResolver.drawingForCommonName(commonName);
                    if (fallback != null) return Image.asset(fallback, fit: BoxFit.contain);
                    return const Icon(Icons.pets, color: Colors.white, size: 28);
                  },
                ),
              );
            },
          ),
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
    final title = species.commonName.isNotEmpty ? species.commonName : (species.latinName ?? 'Soort');
    final headerImageDrawing = SpeciesImageResolver.drawingForCommonName(species.commonName);

    return Scaffold(
      body: Column(
        children: [
          // Header
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.only(top: 48, left: 8, right: 20, bottom: 16),
              color: AppColors.darkGreen,
              child: SizedBox(
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back button on the left
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Centered title/category
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(species.category, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                    ],
                  ),
                  // Image on the right
                  Align(
                    alignment: Alignment.centerRight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: Colors.white.withOpacity(0.2),
                        child: FutureBuilder<bool>(
                          future: SpeciesClickTracker.isClicked(species.id),
                          builder: (context, snapshot) {
                            final clicked = snapshot.data ?? false;
                            final path = clicked
                                ? SpeciesImageResolver.realForCommonName(species.commonName)
                                : headerImageDrawing;
                            if (path == null) {
                              return const Center(child: Icon(Icons.pets, color: Colors.white, size: 36));
                            }
                            return GestureDetector(
                              onTap: () => _showImageViewer(context, path),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  path,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.pets, color: Colors.white, size: 36),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
          // Divider
          Container(height: 6, color: Colors.white),

          // Slideshow cards with stacked look
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        // back layers for stacked effect
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
                        // main page view card
                        _pageCardContainer(
                          child: Stack(
                            children: [
                              // PageView with animated transitions
                              PageView.builder(
                                controller: _pageController,
                                itemCount: 4,
                                onPageChanged: (i) => setState(() => _currentPage = i),
                                itemBuilder: (context, index) {
                                  final titles = const ['Omschrijving', 'Gedrag', 'Rol in de natuur', 'Advies'];
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
                                      if (_pageController.position.hasContentDimensions) {
                                        final current = (_pageController.page ?? _currentPage.toDouble());
                                        t = current - index.toDouble();
                                      } else {
                                        t = _currentPage.toDouble() - index.toDouble();
                                      }
                                      final scale = 1.0 - (t.abs() * 0.06).clamp(0.0, 0.06);
                                      final opacity = 1.0 - (t.abs() * 0.35).clamp(0.0, 0.35);
                                      return Transform.scale(
                                        scale: scale,
                                        child: Opacity(
                                          opacity: opacity,
                                          child: _contentCard(title: titles[index], text: _composeText(species, include: includes[index])),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              // Left/Right arrows
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                                  onPressed: _currentPage > 0
                                      ? () => _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                                  onPressed: _currentPage < 3
                                      ? () => _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
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
                  // chips row to switch pages
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(child: _chip('OMSCHRIJVING', 0)),
                          const SizedBox(width: 12),
                          Expanded(child: _chip('GEDRAG', 1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  // Helper to compose text sections
  String _composeText(Species s, {required List<String> include}) {
    final parts = <String?>[];
    if (include.contains('description')) parts.add(s.description);
    if (include.contains('behaviour')) parts.add(s.behaviour);
    if (include.contains('roleInNature')) parts.add(s.roleInNature);
    if (include.contains('advice')) parts.add(s.advice);
    return parts.where((p) => (p ?? '').isNotEmpty).cast<String>().join('\n\n');
  }

  // Chip widget
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
        backgroundColor: selected ? AppColors.darkGreen : AppColors.lightMintGreen,
        foregroundColor: selected ? Colors.white : AppColors.brown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.darkGreen)),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  // Container styling for the page view card
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
  // Content card for each page
  Widget _contentCard({required String title, required String text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              text.isNotEmpty ? text : '—',
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
