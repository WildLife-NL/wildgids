import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/animal_waarneming_models/observed_animal_entry.dart';
import 'package:wildgids/models/enums/animal_age.dart';
import 'package:wildgids/models/enums/animal_age_extensions.dart';
import 'package:wildgids/models/enums/animal_condition.dart';
import 'package:wildgids/models/enums/animal_gender.dart';

class AnimalCounting extends StatefulWidget {
  final VoidCallback? onAddToList;

  const AnimalCounting({super.key, this.onAddToList});

  @override
  State<AnimalCounting> createState() => _AnimalCountingState();
}

class _AnimalCountingState extends State<AnimalCounting> {
  AnimalGender? _selectedGender;
  AnimalAge? _selectedAge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F4),
      body: SafeArea(
        child: Column(
          children: [
            // Heading
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 12, 0, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hoeveel van deze dieren heb je gezien?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                ),
              ),
            ),
            // Main card container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: const Color(0xFF999999),
                      width: 1.5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Mannelijk'),
                                selected: _selectedGender == AnimalGender.mannelijk,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedGender = AnimalGender.mannelijk;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Vrouwelijk'),
                                selected: _selectedGender == AnimalGender.vrouwelijk,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedGender = AnimalGender.vrouwelijk;
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Onbekend'),
                                selected: _selectedGender == AnimalGender.onbekend,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedGender = AnimalGender.onbekend;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_selectedGender != null)
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Volwassen'),
                                  selected: _selectedAge == AnimalAge.volwassen,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedAge = AnimalAge.volwassen;
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Onvolwassen'),
                                  selected: _selectedAge == AnimalAge.onvolwassen,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedAge = AnimalAge.onvolwassen;
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(AnimalAge.pasGeboren.label),
                                  selected: _selectedAge == AnimalAge.pasGeboren,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedAge = AnimalAge.pasGeboren;
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Onbekend'),
                                  selected: _selectedAge == AnimalAge.onbekend,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedAge = AnimalAge.onbekend;
                                    });
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Vorige',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_selectedGender == null || _selectedAge == null) return;
                        final manager =
                            context.read<AnimalSightingReportingInterface>();
                        manager.addObservedAnimal(
                          ObservedAnimalEntry(
                            age: _selectedAge!,
                            gender: _selectedGender!,
                            condition: AnimalCondition.andere,
                            count: 1,
                          ),
                        );
                        manager.syncObservedAnimalsToSighting();
                        widget.onAddToList?.call();
                      },
                      child: const Text(
                        'Voeg toe aan de lijst',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox.shrink(),
    );
  }
}

