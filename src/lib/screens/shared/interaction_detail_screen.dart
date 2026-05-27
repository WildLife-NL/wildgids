import 'package:flutter/material.dart';
//import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildgids/utils/api_datetime.dart';
import 'package:wildgids/utils/location_label.dart';
import 'package:wildgids/utils/species_icon_utils.dart';

class InteractionDetailScreen extends StatelessWidget {
  final MyInteraction interaction;

  const InteractionDetailScreen({super.key, required this.interaction});

  String _formatDateTime(DateTime dateTime) => ApiDateTime.formatNl(dateTime);

  String _localizeType(String type) {
    switch (type.toLowerCase()) {
      case 'sighting':
        return 'Waarneming';
      case 'damage':
        return 'Schade';
      case 'collision':
        return 'Aanrijding';
      default:
        return type;
    }
  }

  String _localizeBehaviour(String behaviour) {
    final lower = behaviour.toLowerCase();
    if (lower.contains('nocturnal')) return 'Nachtactief';
    if (lower.contains('diurnal')) return 'Dagactief';
    if (lower.contains('omnivore')) return 'Alleseter';
    if (lower.contains('herbivore')) return 'Planteneter';
    if (lower.contains('carnivore')) return 'Vleeseter';
    return behaviour;
  }

  String _localizeAdvice(String advice) {
    final lower = advice.toLowerCase();
    if (lower.contains('keep distance')) return 'Houd afstand';
    if (lower.contains('do not feed')) return 'Niet voeren';
    if (lower.contains('report to authorities')) return 'Meld bij autoriteiten';
    return advice;
  }

  String _animalSummary() {
    final animals = interaction.reportOfSighting?.involvedAnimals ??
        interaction.reportOfCollision?.involvedAnimals ??
        [];
    return animals.isEmpty ? '1' : animals.length.toString();
  }

  List<Widget> _animalRows() {
    final animals = interaction.reportOfSighting?.involvedAnimals ??
        interaction.reportOfCollision?.involvedAnimals ??
        [];

    if (animals.isEmpty) return [];

    return animals.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final animal = entry.value;
      final details = [
        animal.sex,
        animal.lifeStage,
        animal.condition,
      ].where((v) => v.isNotEmpty).join(', ');

      return _buildDetailRow('Dier $index', details);
    }).toList();
  }

  void _handleBackNavigation(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final commonName = interaction.species.commonName.isNotEmpty
        ? interaction.species.commonName
        : interaction.species.name;
    final imagePath = getSpeciesCardImagePath(commonName);
    final animalRows = _animalRows();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              centerText: _localizeType(interaction.type.name),
              leftIcon: Icons.arrow_back_ios,
              rightIcon: null,
              showUserIcon: false,
              useFixedText: true,
              onLeftIconPressed: () => _handleBackNavigation(context),
              textColor: Colors.black,
              iconColor: Colors.black,
              fontScale: 1.4,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),

            // Main card container — styled to match SightingDetailScreen.
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Overzicht',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _AnimalImageCard(
                            imagePath: imagePath,
                            label: commonName,
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Aantal: ${_animalSummary()}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),

                          if (animalRows.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...animalRows,
                            const SizedBox(height: 16),
                            _divider(),
                            const SizedBox(height: 16),
                          ] else ...[
                            const SizedBox(height: 16),
                            _divider(),
                            const SizedBox(height: 16),
                          ],

                          _buildDetailRow(
                            'Type',
                            _localizeType(interaction.type.name),
                          ),
                          _buildDetailRow(
                            'Locatie',
                            formatFriendlyLocation(
                              interaction.location.latitude,
                              interaction.location.longitude,
                            ),
                          ),
                          _buildDetailRow(
                            'Plaats',
                            formatFriendlyLocation(
                              interaction.place.latitude,
                              interaction.place.longitude,
                            ),
                          ),
                          _buildDetailRow(
                            'Datum & Tijd',
                            _formatDateTime(interaction.moment),
                          ),
                          _buildDetailRow(
                            'Ingediend op',
                            _formatDateTime(interaction.timestamp),
                          ),

                          if (interaction.description.isNotEmpty)
                            _buildDetailRow(
                              'Beschrijving',
                              interaction.description,
                            ),

                          const SizedBox(height: 8),
                          _divider(),
                          const SizedBox(height: 16),

                          _buildDetailRow(
                            'Gewone naam',
                            interaction.species.commonName,
                          ),
                          _buildDetailRow(
                            'Wetenschappelijke naam',
                            interaction.species.name,
                          ),
                          if (interaction.species.category.isNotEmpty)
                            _buildDetailRow(
                              'Categorie',
                              interaction.species.category,
                            ),
                          if (interaction.species.description.isNotEmpty)
                            _buildDetailRow(
                              'Beschrijving',
                              interaction.species.description,
                            ),
                          if (interaction.species.behaviour.isNotEmpty)
                            _buildDetailRow(
                              'Gedrag',
                              _localizeBehaviour(
                                interaction.species.behaviour,
                              ),
                            ),
                          if (interaction.species.advice.isNotEmpty)
                            _buildDetailRow(
                              'Advies',
                              _localizeAdvice(interaction.species.advice),
                            ),
                          if (interaction.species.roleInNature.isNotEmpty)
                            _buildDetailRow(
                              'Rol in de natuur',
                              interaction.species.roleInNature,
                            ),

                          if (interaction.reportOfDamage != null) ...[
                            const SizedBox(height: 8),
                            _divider(),
                            const SizedBox(height: 16),
                            _buildDamageRows(interaction.reportOfDamage!),
                          ],

                          if (interaction.reportOfCollision != null) ...[
                            const SizedBox(height: 8),
                            _divider(),
                            const SizedBox(height: 16),
                            _buildCollisionRows(
                              interaction.reportOfCollision!,
                            ),
                          ],

                          if (interaction.questionnaire != null) ...[
                            const SizedBox(height: 8),
                            _divider(),
                            const SizedBox(height: 16),
                            _buildQuestionnaireRows(interaction.questionnaire!),
                          ],

                          const SizedBox(height: 8),
                          _divider(),
                          const SizedBox(height: 16),
                          _buildDetailRow('Gebruiker', interaction.user.name),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: const Color(0xFF999999),
    );
  }

  Widget _buildCollisionRows(ReportOfCollision report) {
    return Column(
      children: [
        _buildDetailRow('Intensiteit', report.intensity),
        _buildDetailRow('Urgentie', report.urgency),
        _buildDetailRow('Geschatte schade', '€${report.estimatedDamage}'),
      ],
    );
  }

  Widget _buildDamageRows(ReportOfDamage report) {
    return Column(
      children: [
        _buildDetailRow('Bezit', report.belonging),
        _buildDetailRow('Impact type', report.impactType),
        _buildDetailRow('Impact waarde', report.impactValue.toString()),
        _buildDetailRow('Geschatte schade', '€${report.estimatedDamage}'),
        _buildDetailRow('Geschat verlies', '€${report.estimatedLoss}'),
      ],
    );
  }

  Widget _buildQuestionnaireRows(QuestionnaireInfo questionnaire) {
    return Column(
      children: [
        _buildDetailRow('Vragenlijst', questionnaire.name),
        _buildDetailRow('Identificatie', questionnaire.identifier),
        _buildDetailRow('Experiment', questionnaire.experiment.name),
        if (questionnaire.experiment.description.isNotEmpty)
          _buildDetailRow(
            'Beschrijving',
            questionnaire.experiment.description,
          ),
        if (questionnaire.experiment.start != null)
          _buildDetailRow(
            'Start',
            _formatDateTime(questionnaire.experiment.start!),
          ),
        if (questionnaire.experiment.end != null)
          _buildDetailRow(
            'Einde',
            _formatDateTime(questionnaire.experiment.end!),
          ),
        _buildDetailRow('Onderzoeker', questionnaire.experiment.user.name),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalImageCard extends StatelessWidget {
  final String? imagePath;
  final String label;

  const _AnimalImageCard({
    required this.imagePath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 140,
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shadowColor:
              const Color.fromARGB(133, 0, 0, 0).withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF999999),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 120,
                child: imagePath != null
                    ? Image.asset(
                        imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
              Container(
                height: 1,
                color: const Color(0xFF999999),
                width: 140,
              ),
              Container(
                width: 140,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
