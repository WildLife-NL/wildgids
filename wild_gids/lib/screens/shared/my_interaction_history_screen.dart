import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/data_managers/my_interaction_api.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/utils/location_label.dart';
import 'package:wildgids/screens/logbook/logbook_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:intl/intl.dart';
import 'package:wildgids/screens/shared/interaction_detail_screen.dart';
// Removed filter dependencies

class MyInteractionHistoryScreen extends StatefulWidget {
  const MyInteractionHistoryScreen({super.key});

  @override
  State<MyInteractionHistoryScreen> createState() =>
      _MyInteractionHistoryScreenState();
}

class _MyInteractionHistoryScreenState
    extends State<MyInteractionHistoryScreen> {
  late Future<List<MyInteraction>> _interactionsFuture;
  // Filter removed: show all interactions unfiltered

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    final myInteractionApi = MyInteractionApi(apiClient);
    _interactionsFuture = myInteractionApi.getMyInteractions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Mijn Interacties',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LogbookScreen()),
                );
              },
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
              useFixedText: true,
            ),
            // Filter UI removed
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
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
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
                              'Fout bij het laden van interacties',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.history,
                              color: AppColors.darkGreen,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Geen interacties gevonden',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'U heeft nog geen interacties gemeld',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    final interactions = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: interactions.length,
                      itemBuilder: (context, index) {
                        return _InteractionCard(
                          interaction: interactions[index],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // No filtering: all interactions are shown
}

class _InteractionCard extends StatelessWidget {
  final MyInteraction interaction;

  const _InteractionCard({required this.interaction});

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  Widget _buildReportDetails() {
    if (interaction.reportOfCollision != null) {
      final report = interaction.reportOfCollision!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aanrijding',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Dieren betrokken: ${report.involvedAnimals.length}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Intensiteit: ${report.intensity}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Urgentie: ${report.urgency}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    } else if (interaction.reportOfDamage != null) {
      final report = interaction.reportOfDamage!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schademelding',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Type: ${report.impactType}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Waarde: ${report.impactValue}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Geschatte schade: â‚¬${report.estimatedDamage}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    } else if (interaction.reportOfSighting != null) {
      final report = interaction.reportOfSighting!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waarneming',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Dieren gezien: ${report.involvedAnimals.length}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => InteractionDetailScreen(interaction: interaction),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      interaction.type.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDateTime(interaction.moment),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                interaction.species.commonName.isNotEmpty
                    ? interaction.species.commonName
                    : interaction.species.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (interaction.description.isNotEmpty) ...[
                Text(
                  interaction.description,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              const SizedBox(height: 8),
              _buildReportDetails(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      formatFriendlyLocation(
                        interaction.place.latitude,
                        interaction.place.longitude,
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (interaction.questionnaire != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightMintGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vragenlijst: ${interaction.questionnaire!.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Experiment: ${interaction.questionnaire!.experiment.name}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

