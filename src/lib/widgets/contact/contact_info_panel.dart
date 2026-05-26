import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/models/api_models/contact_model.dart';
import 'package:wildgids/utils/api_datetime.dart';

/// Animal + researcher conveyance messages from a contact API response.
class ContactInfoPanel extends StatelessWidget {
  const ContactInfoPanel({
    super.key,
    required this.contact,
    this.compact = false,
    this.showAnimalHeader = true,
  });

  final Contact contact;
  final bool compact;
  final bool showAnimalHeader;

  @override
  Widget build(BuildContext context) {
    final conveyances = contact.conveyances
        .where((c) => c.displayText.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAnimalHeader) ...[
          _AnimalHeader(contact: contact, compact: compact),
          if (contact.sensorId != null && contact.sensorId!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Sensor: ${contact.sensorId}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
        if (conveyances.isNotEmpty) ...[
          SizedBox(height: compact ? 10 : 14),
          Text(
            'Bericht van onderzoeker',
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...conveyances.map((c) => _ConveyanceTile(conveyance: c)),
        ],
      ],
    );
  }
}

class _AnimalHeader extends StatelessWidget {
  const _AnimalHeader({required this.contact, required this.compact});

  final Contact contact;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 40 : 48,
          height: compact ? 40 : 48,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.pets,
            color: AppColors.primaryGreen,
            size: compact ? 22 : 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.animalDisplayLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 15 : 17,
                  color: const Color(0xFF5B3C1A),
                ),
              ),
              if (contact.collarAnimalId != null &&
                  contact.collarAnimalId!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'ID: ${contact.collarAnimalId}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConveyanceTile extends StatelessWidget {
  const _ConveyanceTile({required this.conveyance});

  final ContactConveyance conveyance;

  @override
  Widget build(BuildContext context) {
    final title = conveyance.messageName?.trim();
    final body = conveyance.messageText?.trim();
    final time = ApiDateTime.formatNl(
      conveyance.timestamp,
      pattern: 'dd MMM yyyy, HH:mm',
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF5B3C1A),
              ),
            ),
          if (body != null && body.isNotEmpty) ...[
            if (title != null && title.isNotEmpty) const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.grey.shade800,
              ),
            ),
          ],
          if (title == null && body == null)
            Text(
              conveyance.displayText,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
