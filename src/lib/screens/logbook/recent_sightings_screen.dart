import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/my_interaction_api.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/screens/shared/interaction_detail_screen.dart';
import 'package:wildgids/utils/api_datetime.dart';
import 'package:wildgids/utils/location_label.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';

class RecentSightingsScreen extends StatefulWidget {
  const RecentSightingsScreen({super.key});

  @override
  State<RecentSightingsScreen> createState() => _RecentSightingsScreenState();
}

class _RecentSightingsScreenState extends State<RecentSightingsScreen> {
  late Future<List<MyInteraction>> _interactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadInteractions();
  }

  void _loadInteractions() {
    final api = MyInteractionApi(context.read<ApiClient>());
    _interactionsFuture = api.getMyInteractions().then(_sortByMoment);
  }

  List<MyInteraction> _sortByMoment(List<MyInteraction> items) {
    final sorted = List<MyInteraction>.from(items)
      ..sort((a, b) => b.moment.compareTo(a.moment));
    return sorted;
  }

  void _handleBackNavigation(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LogbookScreen()),
      (route) => false,
    );
  }

  String _speciesName(MyInteraction interaction) {
    if (interaction.species.commonName.isNotEmpty) {
      return interaction.species.commonName;
    }
    if (interaction.species.name.isNotEmpty) {
      return interaction.species.name;
    }
    return 'Onbekend dier';
  }

  String _typeLabel(MyInteraction interaction) {
    switch (interaction.type.id) {
      case 1:
        return 'Waarneming';
      case 2:
        return 'Schademelding';
      case 3:
        return 'Dieraanrijding';
      default:
        final name = interaction.type.name.trim();
        return name.isNotEmpty ? name : 'Melding';
    }
  }

  int _animalCount(MyInteraction interaction) {
    final sighting = interaction.reportOfSighting;
    if (sighting != null && sighting.involvedAnimals.isNotEmpty) {
      return sighting.involvedAnimals.length;
    }
    final collision = interaction.reportOfCollision;
    if (collision != null && collision.involvedAnimals.isNotEmpty) {
      return collision.involvedAnimals.length;
    }
    return 1;
  }

  String _locationLabel(MyInteraction interaction) {
    final lat = interaction.place.latitude;
    final lon = interaction.place.longitude;
    if (lat == 0 && lon == 0) {
      return formatFriendlyLocation(
        interaction.location.latitude,
        interaction.location.longitude,
      );
    }
    return formatFriendlyLocation(lat, lon);
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
              centerText: 'Logboek',
              leftIcon: Icons.arrow_back_ios,
              rightIcon: null,
              showUserIcon: false,
              useFixedText: true,
              onLeftIconPressed: () => _handleBackNavigation(context),
              textColor: Colors.black,
              fontScale: 1.4,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Expanded(
              child: FutureBuilder<List<MyInteraction>>(
                future: _interactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkGreen,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Meldingen laden mislukt',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () {
                                setState(_loadInteractions);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.darkGreen,
                              ),
                              child: const Text('Opnieuw proberen'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final interactions = snapshot.data ?? [];
                  if (interactions.isEmpty) {
                    return Center(
                      child: Text(
                        'Geen meldingen gevonden',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.darkGreen,
                    onRefresh: () async {
                      setState(_loadInteractions);
                      await _interactionsFuture;
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: interactions.length,
                      itemBuilder: (context, index) {
                        final interaction = interactions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _RecentInteractionCard(
                            interaction: interaction,
                            typeLabel: _typeLabel(interaction),
                            speciesName: _speciesName(interaction),
                            animalCount: _animalCount(interaction),
                            location: _locationLabel(interaction),
                            dateTime: ApiDateTime.formatSummary(
                              interaction.moment,
                            ),
                            imagePath: SpeciesImageResolver.drawingForCommonName(
                              interaction.species.commonName.isNotEmpty
                                  ? interaction.species.commonName
                                  : interaction.species.name,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InteractionDetailScreen(
                                    interaction: interaction,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInteractionCard extends StatelessWidget {
  const _RecentInteractionCard({
    required this.interaction,
    required this.typeLabel,
    required this.speciesName,
    required this.animalCount,
    required this.location,
    required this.dateTime,
    required this.imagePath,
    required this.onTap,
  });

  final MyInteraction interaction;
  final String typeLabel;
  final String speciesName;
  final int animalCount;
  final String location;
  final String dateTime;
  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateParts = dateTime.split('|');
    final date = dateParts.isNotEmpty ? dateParts.first.trim() : dateTime;
    final time = dateParts.length > 1 ? dateParts[1].trim() : '';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 220,
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderDefault, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImageSection(imagePath: imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        typeLabel,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        speciesName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailColumn('Aantal', '$animalCount'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: _DetailColumn('Datum', date)),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(child: _DetailColumn('Tijd', time)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 115, 115, 115),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: const Color(0xFFE0D9C9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        border: Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: imagePath != null && imagePath!.isNotEmpty
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.asset(
                imagePath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.pets,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
              ),
            )
          : Center(
              child: Icon(Icons.pets, size: 40, color: Colors.grey.shade400),
            ),
    );
  }
}

class _DetailColumn extends StatelessWidget {
  const _DetailColumn(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color.fromARGB(255, 115, 115, 115),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
