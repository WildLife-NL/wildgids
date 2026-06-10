import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/constants/sighting_report_activities.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_details_screen.dart';
import 'package:wildgids/screens/waarneming/animal_waarneming_summary_screen.dart';
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';

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
  String _humanActivity = SightingReportActivityCatalog.defaultHumanActivity;
  String _perceivedAnimalActivity =
      SightingReportActivityCatalog.defaultPerceivedAnimalActivity;
  late TextEditingController _humanActivityOtherController;
  late TextEditingController _perceivedActivityOtherController;

  @override
  void initState() {
    super.initState();

    final sighting =
        context.read<AnimalSightingReportingInterface>().getCurrentanimalSighting();

    _humanActivity =
        sighting?.humanActivity ?? SightingReportActivityCatalog.defaultHumanActivity;

    _perceivedAnimalActivity = sighting?.perceivedAnimalActivity ??
        SightingReportActivityCatalog.defaultPerceivedAnimalActivity;
    _humanActivityOtherController = TextEditingController(text: sighting?.humanActivityOther ?? '');
    _perceivedActivityOtherController = TextEditingController(text: sighting?.perceivedAnimalActivityOther ?? '');
  }

  void _handleNext() {
    final sightingManager = context.read<AnimalSightingReportingInterface>();
    final sighting = sightingManager.getCurrentanimalSighting();

    if (sighting != null) {
      final updatedSighting = sighting.copyWith(
        humanActivity: _humanActivity,
        humanActivityOther: SightingReportActivityCatalog.isOtherHuman(_humanActivity)
            ? (_humanActivityOtherController.text.isNotEmpty ? _humanActivityOtherController.text : null)
            : null,
        perceivedAnimalActivity: _perceivedAnimalActivity,
        perceivedAnimalActivityOther: SightingReportActivityCatalog.isOtherPerceivedAnimal(_perceivedAnimalActivity)
            ? (_perceivedActivityOtherController.text.isNotEmpty ? _perceivedActivityOtherController.text : null)
            : null,
      );

      sightingManager.updateCurrentanimalSighting(updatedSighting);
    }

    if (widget.proceedToDetails) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimalWaarnemingDetailsScreen(
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
        builder: (context) => AnimalWaarnemingSummaryScreen(
          totalCount: widget.totalCount,
        ),
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
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppBar(
              centerText: 'Waarneming',
              rightIcon: null,
              showUserIcon: false,
              useFixedText: true,
              onLeftIconPressed: _handleBack,
              textColor: AppColors.textPrimary,
              iconColor: AppColors.textPrimary,
              fontScale: 1.4,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(16, 2, 16, 16 + keyboardInset),
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Activiteit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _activityDropdown(
                          label: 'Wat deed je toen je het dier zag?',
                          value: _humanActivity,
                          options: SightingReportActivityCatalog.instance.humanActivities,
                          onChanged: (v) {
                            setState(() => _humanActivity = v);
                          },
                        ),
                        if (SightingReportActivityCatalog.isOtherHuman(_humanActivity)) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _humanActivityOtherController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Omschrijf wat je deed',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Color(0xFF999999), width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Color(0xFF37A904), width: 2),
                              ),
                            ),
                            maxLines: 2,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _activityDropdown(
                          label: 'Wat deed het dier?',
                          value: _perceivedAnimalActivity,
                          options:
                              
                          SightingReportActivityCatalog.instance.perceivedAnimalActivities,
                          onChanged: (v) {
                            setState(() => _perceivedAnimalActivity = v);
                          },
                        ),
                        if (SightingReportActivityCatalog.isOtherPerceivedAnimal(_perceivedAnimalActivity)) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _perceivedActivityOtherController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Omschrijf wat het dier deed',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Color(0xFF999999), width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Color(0xFF37A904), width: 2),
                              ),
                            ),
                            maxLines: 2,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                        SizedBox(height: keyboardInset > 0 ? 8 : 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: Color(0xFF999999),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Vorige',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF37A904),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Volgende',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }

  Widget _activityDropdown({
    required String label,
    required String value,
    required List<SightingReportActivityOption> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(value),
          menuMaxHeight: 600,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
          initialValue: options.any((o) => o.apiValue == value)
              ? value
              : options.last.apiValue,
          decoration: InputDecoration(
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(
      color: Color(0xFF999999),
      width: 1.2,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(
      color: Color(0xFF37A904),
      width: 2,
    ),
  ),
),
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o.apiValue,
                  child: Text(
                o.labelNl,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
