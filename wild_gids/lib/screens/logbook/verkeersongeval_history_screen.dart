import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/data_managers/api_client.dart';
import 'package:wildrapport/data_managers/my_interaction_api.dart';
import 'package:wildrapport/models/api_models/my_interaction.dart';
import 'package:wildrapport/utils/location_label.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/screens/logbook/logbook_screen.dart';

class VerkeersongevalHistoryScreen extends StatelessWidget {
  const VerkeersongevalHistoryScreen({super.key});

  bool _isAanrijding(MyInteraction interaction) => interaction.type.id == 3;

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<ApiClient>();
    final myInteractionApi = MyInteractionApi(apiClient);
    final interactionsFuture = myInteractionApi.getMyInteractions();

    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Verkeersongeval geschiedenis',
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
            Expanded(
              child: FutureBuilder<List<MyInteraction>>(
                future: interactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.darkGreen),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text('Fout bij laden', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            SizedBox(height: 8),
                            Text('Kon verkeersongevallen niet laden. Probeer opnieuw.', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data ?? [];
                  final filtered = data.where(_isAanrijding).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.history, color: AppColors.darkGreen, size: 64),
                            SizedBox(height: 16),
                            Text('Nog geen verkeersongevallen', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            SizedBox(height: 8),
                            Text('Na het indienen van een verkeersongeval wordt deze hier zichtbaar.', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _InteractionTile(interaction: filtered[index]);
                    },
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

class _InteractionTile extends StatelessWidget {
  final MyInteraction interaction;
  const _InteractionTile({required this.interaction});

  String _formatDateTime(DateTime dt) => DateFormat('dd MMM yyyy, HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final species = interaction.species.commonName.isNotEmpty ? interaction.species.commonName : interaction.species.name;
    final collision = interaction.reportOfCollision;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _DetailSheet(interaction: interaction)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Dieraanrijding', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(_formatDateTime(interaction.moment), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Text(species, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF5B3C1A))),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 12),
            const Text('Aanrijding', style: TextStyle(fontWeight: FontWeight.bold)),
            if (collision != null) ...[
              const SizedBox(height: 6),
              Text('Dieren betrokken: ${collision.involvedAnimals.length}'),
              Text('Intensiteit: ${collision.intensity}'),
              Text('Urgentie: ${collision.urgency}'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  formatFriendlyLocation(interaction.place.latitude, interaction.place.longitude),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (interaction.questionnaire != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vragenlijst: ${interaction.questionnaire!.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5B3C1A))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final MyInteraction interaction;
  const _DetailSheet({required this.interaction});

  String _formatDateTime(DateTime dt) => DateFormat('dd MMM yyyy, HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final species = interaction.species.commonName.isNotEmpty ? interaction.species.commonName : interaction.species.name;
    final collision = interaction.reportOfCollision;

    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      appBar: AppBar(
        backgroundColor: AppColors.lightMintGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Details', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(species, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(_formatDateTime(interaction.moment), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                if (interaction.description.isNotEmpty) ...[
                  const Text('Beschrijving:', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(interaction.description, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                ],
                const Text('Locatie:', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  formatFriendlyLocation(interaction.place.latitude, interaction.place.longitude),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (interaction.species.category.isNotEmpty) ...[
                  const Text('Dierencategorie:', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(interaction.species.category, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                ],
                if (collision != null) ...[
                  const Text('Aanrijdingsrapport:', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Intensiteit: ${collision.intensity}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                        Text('Urgentie: ${collision.urgency}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                        Text('Geschatte schade: €${collision.estimatedDamage}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Betrokken dieren (${collision.involvedAnimals.length}):', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  ...collision.involvedAnimals.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final animal = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Dier $idx', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text('Geslacht: ${animal.sex}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                            Text('Levensstadium: ${animal.lifeStage}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                            Text('Toestand: ${animal.condition}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
