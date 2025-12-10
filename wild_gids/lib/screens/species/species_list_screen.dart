import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/data_apis/species_api_interface.dart';
import 'package:wildrapport/models/api_models/species.dart';
import 'package:wildrapport/constants/app_colors.dart';

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
        title: const Text('Soorten'),
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
                      ? _SpeciesGrid(species: _filtered)
                      : _SpeciesList(species: _filtered),
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
  const _SpeciesGrid({required this.species});

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
            child: _SpeciesTile(species: s),
          );
        }).toList(),
      ),
    );
  }
}

class _SpeciesTile extends StatelessWidget {
  final Species species;
  const _SpeciesTile({required this.species});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: species)),
        );
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
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  color: AppColors.darkGreen,
                  child: const Center(
                    child: Icon(Icons.pets, size: 64, color: Colors.white),
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
  const _SpeciesList({required this.species});

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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: s)),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(16)),
              child: SizedBox(
                height: 72,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    _imageBox(),
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

  Widget _imageBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 56,
        height: 56,
        color: AppColors.darkGreen,
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.pets, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class SpeciesDetailScreen extends StatelessWidget {
  final Species species;

  const SpeciesDetailScreen({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(species.commonName.isNotEmpty ? species.commonName : (species.latinName ?? 'Soort'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (species.latinName != null)
              _InfoSection(
                title: 'Wetenschappelijke naam',
                child: Text(
                  species.latinName!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.black),
                ),
              ),
            if (species.category.isNotEmpty)
              _InfoSection(
                title: 'Categorie',
                child: Text(species.category, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              ),
            if (species.description != null)
              _InfoSection(
                title: 'Beschrijving',
                child: Text(species.description!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              ),
            if (species.behaviour != null)
              _InfoSection(
                title: 'Gedrag',
                child: Text(species.behaviour!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              ),
            if (species.roleInNature != null)
              _InfoSection(
                title: 'Rol in de natuur',
                child: Text(species.roleInNature!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              ),
            if (species.advice != null)
              _InfoSection(
                title: 'Advies',
                child: Text(species.advice!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              ),
            if (species.schema != null)
              _InfoSection(
                title: 'Schema',
                child: Text(species.schema!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black)),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
