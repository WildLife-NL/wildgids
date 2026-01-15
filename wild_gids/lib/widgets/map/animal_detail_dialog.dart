import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/animal_waarneming_models/animal_pin.dart';
import '../../constants/app_colors.dart';

class AnimalDetailDialog extends StatelessWidget {
  final AnimalPin animal;
  final String? animalIconPath;

  const AnimalDetailDialog({
    super.key,
    required this.animal,
    this.animalIconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          animalIconPath != null
                              ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  animalIconPath!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.pets,
                                      size: 32,
                                      color: AppColors.darkGreen,
                                    );
                                  },
                                ),
                              )
                              : const Icon(
                                Icons.pets,
                                size: 32,
                                color: AppColors.darkGreen,
                              ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dier waarneming',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            animal.speciesName ?? 'Onbekend',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Date and Time
                _buildDateTimeInfo(),

                const SizedBox(height: 16),

                // Location
                _buildLocationInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeInfo() {
    final local = animal.seenAt.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    String timeAgo;
    if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes} minuten geleden';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours} uur geleden';
    } else {
      timeAgo = '${difference.inDays} dagen geleden';
    }

    return _buildInfoSection(
      Icons.calendar_today,
      'Datum & Tijd',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE d MMMM yyyy').format(local),
            style: const TextStyle(fontSize: 14, color: AppColors.darkGreen),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(local),
            style: const TextStyle(fontSize: 14, color: AppColors.darkGreen),
          ),
          const SizedBox(height: 4),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return _buildInfoSection(
      Icons.location_on,
      'Locatie',
      Text(
        '${animal.lat.toStringAsFixed(6)}, ${animal.lon.toStringAsFixed(6)}',
        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.darkGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
