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
          if (species.isEmpty) {
            return const Center(child: Text('Geen soorten gevonden'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8.0),
            itemCount: species.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final s = species[index];
              return ListTile(
                leading: const Icon(Icons.pets),
                title: Text(s.commonName.isNotEmpty ? s.commonName : (s.latinName ?? 'Onbekend')),
                subtitle: Text(s.category),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpeciesDetailScreen(species: s),
                    ),
                  );
                },
              );
            },
          );
        },
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
