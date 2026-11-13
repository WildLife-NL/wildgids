import 'package:flutter/material.dart';
import 'package:wildgids/constants/sighting_report_activities.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/models/enums/animal_count_mode.dart';
import 'package:wildgids/utils/api_datetime.dart';
import 'package:wildgids/utils/location_label.dart';
import 'package:wildgids/utils/species_icon_utils.dart';
import 'package:wildgids/widgets/guide/animal_artwork.dart';
import 'package:wildgids/widgets/guide/animal_name.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';

class InteractionDetailScreen extends StatelessWidget {
  const InteractionDetailScreen({super.key, required this.interaction});

  final MyInteraction interaction;

  List<InvolvedAnimal> get _animals =>
      interaction.reportOfSighting?.involvedAnimals ??
      interaction.reportOfCollision?.involvedAnimals ??
      [];

  String get _type => switch (interaction.type.id) {
    1 => 'Waarneming',
    2 => 'Schade',
    3 => 'Aanrijding',
    _ => switch (interaction.type.name.toLowerCase()) {
      'sighting' => 'Waarneming',
      'damage' => 'Schade',
      'collision' => 'Aanrijding',
      _ => interaction.type.name.isEmpty ? 'Melding' : interaction.type.name,
    },
  };

  String get _countLabel {
    final mode = AnimalCountMode.fromNotes(interaction.description);
    if (mode != AnimalCountMode.exact) return mode.summary(null);
    // Older reports may have no individual animals. An empty list is not one animal.
    return _animals.isEmpty ? 'Aantal onbekend' : mode.summary(_animals.length);
  }

  String get _notes =>
      interaction.description
          .split('\n')
          .where(
            (line) =>
                line.trim() != AnimalCountMode.group.note &&
                line.trim() != AnimalCountMode.unsure.note,
          )
          .join('\n')
          .trim();

  String _placeLabel(MyInteractionLocation place) {
    final address = [
      place.streetName,
      place.cityName,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    return address.isNotEmpty
        ? address
        : formatFriendlyLocation(place.latitude, place.longitude);
  }

  String _behaviour(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('nocturnal')) return 'Nachtactief';
    if (lower.contains('diurnal')) return 'Dagactief';
    if (lower.contains('omnivore')) return 'Alleseter';
    if (lower.contains('herbivore')) return 'Planteneter';
    if (lower.contains('carnivore')) return 'Vleeseter';
    return value;
  }

  String _advice(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('keep distance')) return 'Houd afstand';
    if (lower.contains('do not feed')) return 'Niet voeren';
    if (lower.contains('report to authorities')) return 'Meld bij autoriteiten';
    return value;
  }

  String _animalValue(String value) => switch (value.toLowerCase()) {
    'unknown' => 'Onbekend',
    'male' => 'Mannelijk',
    'female' => 'Vrouwelijk',
    'infant' => 'Pasgeboren',
    'adolescent' => 'Onvolwassen',
    'adult' => 'Volwassen',
    'healthy' => 'Gezond',
    'impaired' => 'Ziek of gewond',
    'dead' => 'Dood',
    _ => value,
  };

  @override
  Widget build(BuildContext context) {
    final species = interaction.species;
    final name =
        species.commonName.isNotEmpty
            ? species.commonName
            : species.name.isNotEmpty
            ? species.name
            : 'Onbekend dier';
    final sighting = interaction.reportOfSighting;
    final damage = interaction.reportOfDamage;
    final collision = interaction.reportOfCollision;
    final questionnaire = interaction.questionnaire;
    final hasSpeciesInfo = [
      species.category,
      species.description,
      species.behaviour,
      species.advice,
      species.roleInNature,
    ].any((value) => value.isNotEmpty);
    return Scaffold(
      backgroundColor: GuideStyle.background,
      appBar: AppBar(
        backgroundColor: GuideStyle.background,
        foregroundColor: GuideStyle.ink,
        title: Text(_type),
        leading: const BackButton(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context, name),
                    const SizedBox(height: 20),
                    _DetailSection(
                      title: 'Jouw ontmoeting',
                      icon: Icons.auto_stories_outlined,
                      child: Column(
                        children: [
                          _fact(
                            Icons.calendar_today_outlined,
                            'Datum en tijd',
                            ApiDateTime.formatNl(interaction.moment),
                          ),
                          _fact(
                            Icons.place_outlined,
                            'Plek van de ontmoeting',
                            _placeLabel(interaction.place),
                          ),
                          if (_notes.isNotEmpty)
                            _fact(Icons.notes_rounded, 'Notities', _notes),
                        ],
                      ),
                    ),
                    if (sighting != null &&
                        (sighting.humanActivity != null ||
                            sighting.perceivedAnimalActivity != null))
                      _DetailSection(
                        title: 'Activiteit',
                        icon: Icons.pets_outlined,
                        child: Column(
                          children: [
                            if (sighting.perceivedAnimalActivity != null)
                              _value(
                                'Wat deed het dier?',
                                SightingReportActivityCatalog.isOtherPerceivedAnimal(
                                          sighting.perceivedAnimalActivity!,
                                        ) &&
                                        sighting
                                                .perceivedAnimalActivityOther
                                                ?.isNotEmpty ==
                                            true
                                    ? sighting.perceivedAnimalActivityOther!
                                    : SightingReportActivityCatalog.labelNlForPerceivedAnimal(
                                      sighting.perceivedAnimalActivity!,
                                    ),
                              ),
                            if (sighting.humanActivity != null)
                              _value(
                                'Wat deed jij?',
                                SightingReportActivityCatalog.isOtherHuman(
                                          sighting.humanActivity!,
                                        ) &&
                                        sighting
                                                .humanActivityOther
                                                ?.isNotEmpty ==
                                            true
                                    ? sighting.humanActivityOther!
                                    : SightingReportActivityCatalog.labelNlForHuman(
                                      sighting.humanActivity!,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    if (_animals.isNotEmpty)
                      _DetailSection(
                        title: 'Dierdetails',
                        icon: Icons.info_outline_rounded,
                        collapsible: true,
                        child: Column(
                          children: [
                            for (var i = 0; i < _animals.length; i++)
                              _value(
                                'Dier ${i + 1}',
                                [
                                      _animals[i].sex,
                                      _animals[i].lifeStage,
                                      _animals[i].condition,
                                    ]
                                    .where((value) => value.isNotEmpty)
                                    .map(_animalValue)
                                    .join(' · '),
                              ),
                          ],
                        ),
                      ),
                    if (damage != null)
                      _DetailSection(
                        title: 'Schade',
                        icon: Icons.report_outlined,
                        child: Column(
                          children: [
                            _value('Bezit', damage.belonging),
                            _value('Impact type', damage.impactType),
                            _value('Impact waarde', '${damage.impactValue}'),
                            _value(
                              'Geschatte schade',
                              '€${damage.estimatedDamage}',
                            ),
                            _value(
                              'Geschat verlies',
                              '€${damage.estimatedLoss}',
                            ),
                          ],
                        ),
                      ),
                    if (collision != null)
                      _DetailSection(
                        title: 'Aanrijding',
                        icon: Icons.warning_amber_rounded,
                        child: Column(
                          children: [
                            _value('Intensiteit', collision.intensity),
                            _value('Urgentie', collision.urgency),
                            _value(
                              'Geschatte schade',
                              '€${collision.estimatedDamage}',
                            ),
                          ],
                        ),
                      ),
                    if (hasSpeciesInfo)
                      _DetailSection(
                        title: 'Over dit dier',
                        icon: Icons.forest_outlined,
                        collapsible: true,
                        child: Column(
                          children: [
                            _value('Categorie', species.category),
                            _value('Beschrijving', species.description),
                            _value('Gedrag', _behaviour(species.behaviour)),
                            _value('Advies', _advice(species.advice)),
                            _value('Rol in de natuur', species.roleInNature),
                          ],
                        ),
                      ),
                    if (questionnaire != null)
                      _DetailSection(
                        title: 'Vragenlijst',
                        icon: Icons.assignment_outlined,
                        collapsible: true,
                        child: Column(
                          children: [
                            _value('Vragenlijst', questionnaire.name),
                            _value('Identificatie', questionnaire.identifier),
                            _value('Experiment', questionnaire.experiment.name),
                            _value(
                              'Beschrijving',
                              questionnaire.experiment.description,
                            ),
                            if (questionnaire.experiment.start != null)
                              _value(
                                'Start',
                                ApiDateTime.formatNl(
                                  questionnaire.experiment.start!,
                                ),
                              ),
                            if (questionnaire.experiment.end != null)
                              _value(
                                'Einde',
                                ApiDateTime.formatNl(
                                  questionnaire.experiment.end!,
                                ),
                              ),
                            _value(
                              'Onderzoeker',
                              questionnaire.experiment.user.name,
                            ),
                          ],
                        ),
                      ),
                    _DetailSection(
                      title: 'Meldingsgegevens',
                      icon: Icons.receipt_long_outlined,
                      collapsible: true,
                      child: Column(
                        children: [
                          _value('Type', _type),
                          _value(
                            'Locatie apparaat',
                            _placeLabel(interaction.location),
                          ),
                          _value(
                            'Ingediend op',
                            ApiDateTime.formatNl(interaction.timestamp),
                          ),
                          _value('Gebruiker', interaction.user.name),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String name) => LayoutBuilder(
    builder: (context, constraints) {
      const titleStyle = TextStyle(
        color: GuideStyle.ink,
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w800,
      );
      final sideBySide =
          constraints.maxWidth >= 330 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.2 &&
          AnimalName.widthFor(context, name, titleStyle) <=
              (constraints.maxWidth - 12) * 0.46;
      final identity = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimalName(name, style: titleStyle),
          if (interaction.species.name.isNotEmpty &&
              interaction.species.name != name) ...[
            const SizedBox(height: 8),
            AnimalName(
              interaction.species.name,
              style: const TextStyle(
                fontSize: 15,
                color: GuideStyle.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (interaction.reportOfSighting != null ||
              interaction.reportOfCollision != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: GuideStyle.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _countLabel,
                style: const TextStyle(
                  color: GuideStyle.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      );
      final art = SizedBox(
        height: 190,
        child: AnimalArtwork(imagePath: getSpeciesCardImagePath(name)),
      );
      if (sideBySide) {
        return Row(
          children: [
            Expanded(flex: 46, child: identity),
            const SizedBox(width: 12),
            Expanded(flex: 54, child: art),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [identity, const SizedBox(height: 8), art],
      );
    },
  );

  Widget _fact(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: GuideStyle.ink),
        const SizedBox(width: 12),
        Expanded(child: _value(label, value, padding: EdgeInsets.zero)),
      ],
    ),
  );

  Widget _value(
    String label,
    String value, {
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 8),
  }) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: GuideStyle.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                height: 1.35,
                color: GuideStyle.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.collapsible = false,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: GuideStyle.border),
    );
    final heading = Text(
      title,
      style: const TextStyle(
        color: GuideStyle.ink,
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child:
            collapsible
                ? ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: GuideStyle.ink,
                  collapsedIconColor: GuideStyle.ink,
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  leading: Icon(icon, color: GuideStyle.ink),
                  title: heading,
                  children: [child],
                )
                : Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: GuideStyle.ink),
                          const SizedBox(width: 12),
                          Expanded(child: heading),
                        ],
                      ),
                      const SizedBox(height: 12),
                      child,
                    ],
                  ),
                ),
      ),
    );
  }
}
