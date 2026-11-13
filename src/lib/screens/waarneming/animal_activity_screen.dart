import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:wildgids/widgets/reporting/report_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/sighting_report_activities.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_details_screen.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_summary_screen.dart';

class AnimalActivityScreen extends StatefulWidget {
  final int totalCount;

  /// Na activiteit doorgaan naar per-dier details i.p.v. direct naar samenvatting.
  final bool proceedToDetails;

  const AnimalActivityScreen({
    super.key,
    required this.totalCount,
    this.proceedToDetails = false,
  });

  @override
  State<AnimalActivityScreen> createState() => _AnimalActivityScreenState();
}

class _AnimalActivityScreenState extends State<AnimalActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  String _humanActivity = SightingReportActivityCatalog.defaultHumanActivity;
  String _perceivedAnimalActivity =
      SightingReportActivityCatalog.defaultPerceivedAnimalActivity;
  late TextEditingController _humanActivityOtherController;
  late TextEditingController _perceivedActivityOtherController;

  @override
  void initState() {
    super.initState();

    final sighting =
        context
            .read<AnimalSightingReportingInterface>()
            .getCurrentanimalSighting();

    _humanActivity = SightingReportActivityCatalog.normalizeHuman(
      sighting?.humanActivity,
    );

    _perceivedAnimalActivity =
        SightingReportActivityCatalog.normalizePerceivedAnimal(
          sighting?.perceivedAnimalActivity,
        );
    _humanActivityOtherController = TextEditingController(
      text: sighting?.humanActivityOther ?? '',
    );
    _perceivedActivityOtherController = TextEditingController(
      text: sighting?.perceivedAnimalActivityOther ?? '',
    );
  }

  void _handleNext() {
    if (_formKey.currentState?.validate() == false) return;
    final sightingManager = context.read<AnimalSightingReportingInterface>();
    final sighting = sightingManager.getCurrentanimalSighting();

    if (sighting != null) {
      final updatedSighting = sighting.copyWith(
        humanActivity: _humanActivity,
        humanActivityOther:
            SightingReportActivityCatalog.isOtherHuman(_humanActivity)
                ? (_humanActivityOtherController.text.isNotEmpty
                    ? _humanActivityOtherController.text
                    : null)
                : null,
        perceivedAnimalActivity: _perceivedAnimalActivity,
        perceivedAnimalActivityOther:
            SightingReportActivityCatalog.isOtherPerceivedAnimal(
                  _perceivedAnimalActivity,
                )
                ? (_perceivedActivityOtherController.text.isNotEmpty
                    ? _perceivedActivityOtherController.text
                    : null)
                : null,
      );

      sightingManager.updateCurrentanimalSighting(updatedSighting);
    }

    if (widget.proceedToDetails) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AnimalWaarnemingDetailsScreen(
                animalIndex: 0,
                totalCount: widget.totalCount,
              ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AnimalWaarnemingSummaryScreen(totalCount: widget.totalCount),
      ),
    );
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _humanActivityOtherController.dispose();
    _perceivedActivityOtherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ReportLayout(
    title: 'Wat gebeurde er?',
    stage: 'Activiteit',
    onBack: _handleBack,
    footer: ReportAction(label: 'Verder', onPressed: _handleNext),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportAnimal(
            animal:
                context
                    .read<AnimalSightingReportingInterface>()
                    .getCurrentanimalSighting()
                    ?.animalSelected,
            height: 135,
          ),
          const SizedBox(height: 20),
          ReportSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle(Icons.pets_outlined, 'Wat deed het dier?'),
                const SizedBox(height: 16),
                _activityDropdown(
                  'Activiteit van het dier',
                  _perceivedAnimalActivity,
                  SightingReportActivityCatalog
                      .instance
                      .perceivedAnimalActivities,
                  (value) => setState(() => _perceivedAnimalActivity = value),
                ),
                if (SightingReportActivityCatalog.isOtherPerceivedAnimal(
                  _perceivedAnimalActivity,
                )) ...[
                  const SizedBox(height: 12),
                  _otherField(
                    _perceivedActivityOtherController,
                    'Wat deed het dier?',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ReportSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle(Icons.directions_walk_outlined, 'Wat deed jij?'),
                const SizedBox(height: 16),
                _activityDropdown(
                  'Jouw activiteit',
                  _humanActivity,
                  SightingReportActivityCatalog.instance.humanActivities,
                  (value) => setState(() => _humanActivity = value),
                ),
                if (SightingReportActivityCatalog.isOtherHuman(
                  _humanActivity,
                )) ...[
                  const SizedBox(height: 12),
                  _otherField(_humanActivityOtherController, 'Wat deed je?'),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 28, color: GuideStyle.ink),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: GuideStyle.ink,
            fontSize: 21,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );

  Widget _otherField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        maxLines: 2,
        validator:
            (value) =>
                value?.trim().isNotEmpty == true
                    ? null
                    : 'Vul een toelichting in.',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _activityDropdown(
    String label,
    String value,
    List<SightingReportActivityOption> options,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    key: ValueKey(label + value),
    initialValue: value,
    isExpanded: true,
    isDense: false,
    itemHeight: null,
    menuMaxHeight: 360,
    dropdownColor: GuideStyle.background,
    borderRadius: BorderRadius.circular(12),
    style: const TextStyle(
      fontFamily: 'Overpass',
      color: GuideStyle.ink,
      fontSize: 16,
      height: 1.25,
    ),
    selectedItemBuilder:
        (_) =>
            options
                .map(
                  (option) => Align(
                    alignment: Alignment.centerLeft,
                    heightFactor: 1,
                    child: Text(option.labelNl),
                  ),
                )
                .toList(),
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: GuideStyle.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GuideStyle.border),
      ),
    ),
    items:
        options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.apiValue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(option.labelNl),
                ),
              ),
            )
            .toList(),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
}
