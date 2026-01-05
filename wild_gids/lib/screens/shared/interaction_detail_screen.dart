import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:intl/intl.dart';
import 'package:wildgids/utils/location_label.dart';

class InteractionDetailScreen extends StatelessWidget {
  final MyInteraction interaction;

  const InteractionDetailScreen({super.key, required this.interaction});

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
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
              centerText: 'Interactie Details',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                Navigator.of(context).pop();
              },
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
              useFixedText: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        interaction.type.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Species Information
                    _buildSection(
                      title: 'Dier Informatie',
                      children: [
                        _buildInfoRow(
                          'Gewone naam',
                          interaction.species.commonName,
                        ),
                        _buildInfoRow(
                          'Wetenschappelijke naam',
                          interaction.species.name,
                        ),
                        if (interaction.species.category.isNotEmpty)
                          _buildInfoRow(
                            'Categorie',
                            interaction.species.category,
                          ),
                        if (interaction.species.description.isNotEmpty)
                          _buildInfoRow(
                            'Beschrijving',
                            interaction.species.description,
                          ),
                        if (interaction.species.behaviour.isNotEmpty)
                          _buildInfoRow(
                            'Gedrag',
                            interaction.species.behaviour,
                          ),
                        if (interaction.species.advice.isNotEmpty)
                          _buildInfoRow('Advies', interaction.species.advice),
                        if (interaction.species.roleInNature.isNotEmpty)
                          _buildInfoRow(
                            'Rol in de natuur',
                            interaction.species.roleInNature,
                          ),
                      ],
                    ),

                    // Time Information
                    _buildSection(
                      title: 'Tijd & Datum',
                      children: [
                        _buildInfoRow(
                          'Moment',
                          _formatDateTime(interaction.moment),
                        ),
                        _buildInfoRow(
                          'Ingediend op',
                          _formatDateTime(interaction.timestamp),
                        ),
                      ],
                    ),

                    // Location Information
                    _buildSection(
                      title: 'Locatie',
                      children: [
                        _buildInfoRow(
                          'Interactie locatie',
                          formatFriendlyLocation(
                            interaction.location.latitude,
                            interaction.location.longitude,
                          ),
                        ),
                        _buildInfoRow(
                          'Plaats',
                          formatFriendlyLocation(
                            interaction.place.latitude,
                            interaction.place.longitude,
                          ),
                        ),
                      ],
                    ),

                    // Description
                    if (interaction.description.isNotEmpty)
                      _buildSection(
                        title: 'Beschrijving',
                        children: [
                          Text(
                            interaction.description,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                    // Report Details
                    if (interaction.reportOfCollision != null)
                      _buildCollisionReport(interaction.reportOfCollision!),
                    if (interaction.reportOfDamage != null)
                      _buildDamageReport(interaction.reportOfDamage!),
                    if (interaction.reportOfSighting != null)
                      _buildSightingReport(interaction.reportOfSighting!),

                    // Questionnaire Information
                    if (interaction.questionnaire != null)
                      _buildQuestionnaireSection(interaction.questionnaire!),

                    // User Information
                    _buildSection(
                      title: 'Gebruiker',
                      children: [
                        _buildInfoRow('Naam', interaction.user.name),
                        _buildInfoRow('ID', interaction.user.id),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildCollisionReport(ReportOfCollision report) {
    return _buildSection(
      title: 'Aanrijding Details',
      children: [
        _buildInfoRow('Intensiteit', report.intensity),
        _buildInfoRow('Urgentie', report.urgency),
        _buildInfoRow('Geschatte schade', 'â‚¬${report.estimatedDamage}'),
        const SizedBox(height: 8),
        const Text(
          'Betrokken dieren:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...report.involvedAnimals.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final animal = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightMintGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dier $index',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Geslacht: ${animal.sex}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Levensfase: ${animal.lifeStage}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Conditie: ${animal.condition}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDamageReport(ReportOfDamage report) {
    return _buildSection(
      title: 'Schade Details',
      children: [
        _buildInfoRow('Bezit', report.belonging),
        _buildInfoRow('Impact type', report.impactType),
        _buildInfoRow('Impact waarde', report.impactValue.toString()),
        _buildInfoRow('Geschatte schade', 'â‚¬${report.estimatedDamage}'),
        _buildInfoRow('Geschat verlies', 'â‚¬${report.estimatedLoss}'),
      ],
    );
  }

  Widget _buildSightingReport(ReportOfSighting report) {
    return _buildSection(
      title: 'Waarneming Details',
      children: [
        const Text(
          'Betrokken dieren:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...report.involvedAnimals.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final animal = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightMintGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dier $index',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Geslacht: ${animal.sex}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Levensfase: ${animal.lifeStage}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Conditie: ${animal.condition}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionnaireSection(QuestionnaireInfo questionnaire) {
    return _buildSection(
      title: 'Vragenlijst',
      children: [
        _buildInfoRow('Naam', questionnaire.name),
        _buildInfoRow('Identificatie', questionnaire.identifier),
        const SizedBox(height: 8),
        const Text(
          'Experiment:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.lightMintGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Naam', questionnaire.experiment.name),
              if (questionnaire.experiment.description.isNotEmpty)
                _buildInfoRow(
                  'Beschrijving',
                  questionnaire.experiment.description,
                ),
              if (questionnaire.experiment.start != null)
                _buildInfoRow(
                  'Start',
                  _formatDateTime(questionnaire.experiment.start!),
                ),
              if (questionnaire.experiment.end != null)
                _buildInfoRow(
                  'Einde',
                  _formatDateTime(questionnaire.experiment.end!),
                ),
              _buildInfoRow('Onderzoeker', questionnaire.experiment.user.name),
            ],
          ),
        ),
      ],
    );
  }
}

