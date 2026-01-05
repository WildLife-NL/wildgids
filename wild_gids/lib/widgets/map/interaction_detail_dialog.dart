import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/models/api_models/interaction_query_result.dart';
import 'package:intl/intl.dart';

/// A detailed dialog for displaying interaction information from the map.
/// Displays rich information about animal sightings, detections, or interactions.
class InteractionDetailDialog extends StatelessWidget {
  final InteractionQueryResult interaction;
  final String? animalIconPath;

  InteractionDetailDialog({
    super.key,
    required this.interaction,
    this.animalIconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with species name and type
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          interaction.speciesName ?? 'Onbekend dier',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (interaction.typeName != null)
                          Text(
                            interaction.typeName!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animal image if available
                    if (animalIconPath != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            animalIconPath!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.pets,
                                size: 80,
                                color: AppColors.darkGreen,
                              );
                            },
                          ),
                        ),
                      ),

                    if (animalIconPath != null) const SizedBox(height: 20),

                    // Reporter information if available
                    if (interaction.userName != null) ...[
                      _buildInfoSection(
                        icon: Icons.person,
                        title: 'Gemeld door',
                        content: Text(
                          interaction.userName!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                    ],

                    // Date and Time Section
                    _buildInfoSection(
                      icon: Icons.calendar_today,
                      title: 'Wanneer',
                      content: _buildDateTimeInfo(),
                    ),

                    const Divider(height: 32),

                    // Location Section
                    _buildInfoSection(
                      icon: Icons.location_on,
                      title: 'Locatie',
                      content: _buildLocationInfo(),
                    ),

                    // Animal details if available
                    if (interaction.involvedAnimals != null &&
                        interaction.involvedAnimals!.isNotEmpty) ...[
                      const Divider(height: 32),
                      _buildInfoSection(
                        icon: Icons.pets,
                        title: 'Betrokken dieren',
                        content: _buildAnimalInfo(),
                      ),
                    ],

                    // Description if available
                    if (interaction.description != null &&
                        interaction.description!.isNotEmpty) ...[
                      const Divider(height: 32),
                      _buildInfoSection(
                        icon: Icons.description,
                        title: 'Beschrijving',
                        content: Text(
                          interaction.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],

                    // TODO: Add when API provides this data
                    // Animal details (sex, age, count)
                    // Reporter information
                    // Photos if available
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Sluiten',
                      style: TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.darkGreen),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.only(left: 28), child: content),
      ],
    );
  }

  Widget _buildDateTimeInfo() {
    final local = interaction.moment.toLocal();
    final dateStr = DateFormat('EEEE d MMMM yyyy').format(local);
    final timeStr = DateFormat('HH:mm').format(local);

    // Calculate how long ago
    final now = DateTime.now();
    final difference = now.difference(local);
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo =
          '${difference.inDays} dag${difference.inDays > 1 ? 'en' : ''} geleden';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} uur geleden';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minuten geleden';
    } else {
      timeAgo = 'Zojuist';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($timeAgo)',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Place name if available
        if (interaction.placeName != null && interaction.placeName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              interaction.placeName!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),

        // Coordinates in a subtle way
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.my_location, size: 14, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                '${interaction.lat.toStringAsFixed(5)}, ${interaction.lon.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalInfo() {
    if (interaction.involvedAnimals == null ||
        interaction.involvedAnimals!.isEmpty) {
      return const Text(
        'Geen details beschikbaar',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
    }

    // Group and count animals
    final Map<String, int> animalCounts = {};
    final Map<String, List<String>> animalDetails = {};

    for (var animal in interaction.involvedAnimals!) {
      final details = <String>[];
      if (animal.sex != null) {
        final sexLabel = _getSexLabel(animal.sex!);
        if (sexLabel != null) details.add(sexLabel);
      }
      if (animal.lifeStage != null) {
        final ageLabel = _getAgeLabel(animal.lifeStage!);
        if (ageLabel != null) details.add(ageLabel);
      }
      if (animal.condition != null) {
        final conditionLabel = _getConditionLabel(animal.condition!);
        if (conditionLabel != null) details.add(conditionLabel);
      }

      final key = details.isNotEmpty ? details.join(' ') : 'Onbekend';
      animalCounts[key] = (animalCounts[key] ?? 0) + 1;
      animalDetails[key] = details;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${interaction.involvedAnimals!.length} dier${interaction.involvedAnimals!.length > 1 ? 'en' : ''}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...animalCounts.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${entry.value}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String? _getSexLabel(String sex) {
    switch (sex.toLowerCase()) {
      case 'male':
      case 'mannelijk':
        return 'Mannelijk';
      case 'female':
      case 'vrouwelijk':
        return 'Vrouwelijk';
      case 'other':
      case 'anders':
        return 'Onbekend geslacht';
      default:
        return null;
    }
  }

  String? _getAgeLabel(String lifeStage) {
    switch (lifeStage.toLowerCase()) {
      case 'newborn':
      case 'baby':
      case 'pasgeboren':
        return 'Pas geboren';
      case 'juvenile':
      case 'young':
      case 'jong':
      case 'onvolwassen':
        return 'Jong';
      case 'adult':
      case 'volwassen':
        return 'Volwassen';
      default:
        return lifeStage;
    }
  }

  String? _getConditionLabel(String condition) {
    switch (condition.toLowerCase()) {
      case 'alive':
      case 'levend':
        return 'Levend';
      case 'dead':
      case 'dood':
        return 'Dood';
      case 'injured':
      case 'gewond':
        return 'Gewond';
      default:
        return null;
    }
  }
}
