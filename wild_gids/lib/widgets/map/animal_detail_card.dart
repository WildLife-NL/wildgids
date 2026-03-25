import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';

/// Displays detailed information about an animal sighting in a card format.
/// 
/// Shows the animal image, species name, and metadata including sighting date/time,
/// gender, age, and observer information.
class AnimalDetailCard extends StatelessWidget {
  static const double _cardHeight = 200;
  static const double _imageWidth = 120;
  static const double _imageCornerRadius = 8;
  static const double _contentSpacing = 12;
  static const double _rowSpacing = 6;
  static const double _columnSpacing = 8;

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  static const TextStyle _animalNameStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 11,
    color: Color.fromARGB(255, 115, 115, 115),
  );

  static const TextStyle _valueStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  final AnimalPin? animal;

  const AnimalDetailCard({
    super.key,
    this.animal,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = animal?.speciesName ?? 'Onbekend dier';
    final formattedDate = _formatDate(animal?.seenAt);
    final formattedTime = _formatTime(animal?.seenAt);
    final imagePath = _getAnimalImagePath(animal?.speciesName);

    return SizedBox(
      height: _cardHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSection(imagePath),
          const SizedBox(width: _contentSpacing),
          _buildDetailsSection(context, displayName, formattedDate, formattedTime),
        ],
      ),
    );
  }

  /// Builds the left section containing the animal image.
  Widget _buildImageSection(String? imagePath) {
    return Container(
      width: _imageWidth,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_imageCornerRadius),
          bottomLeft: Radius.circular(_imageCornerRadius),
        ),
        border: Border.all(
          color: Colors.grey[400] ?? Colors.grey,
          width: 2,
        ),
      ),
      child: imagePath != null
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_imageCornerRadius),
                bottomLeft: Radius.circular(_imageCornerRadius),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.pets,
                    size: 40,
                    color: Colors.grey[400],
                  );
                },
              ),
            )
          : Center(
              child: Icon(
                Icons.pets,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
    );
  }

  /// Builds the right section containing animal details and metadata.
  Widget _buildDetailsSection(
    BuildContext context,
    String displayName,
    String formattedDate,
    String formattedTime,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(
          right: _contentSpacing,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Waarneming', style: _headerStyle),
            Text(displayName, style: _animalNameStyle),
            const SizedBox(height: _rowSpacing),
            _buildMetadataRow(
              [
                ('Aantal', '1'),
                ('Datum', formattedDate),
                ('Tijd', formattedTime),
              ],
            ),
            const SizedBox(height: _rowSpacing),
            _buildMetadataRow(
              [
                ('Geslacht', 'Mannelijk'),
                ('Leeftijd', 'Onvolwassen'),
              ],
            ),
            const SizedBox(height: _rowSpacing),
            _buildInfoRow(Icons.location_on, 'Locatie onbekend'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.person, 'Gerapporteerd door: @milapulvirenti'),
          ],
        ),
      ),
    );
  }

  /// Builds a row of metadata columns with title-value pairs.
  Widget _buildMetadataRow(List<(String, String)> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: _columnSpacing),
          Expanded(
            child: _buildDetailColumn(items[i].$1, items[i].$2),
          ),
        ],
      ],
    );
  }

  /// Builds an info row with an icon and text.
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: _labelStyle,
          ),
        ),
      ],
    );
  }

  /// Formats a DateTime to short date format (YY-MM-DD).
  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final dateStr = dateTime.toString().split(' ')[0];
    if (dateStr.length != 10) return dateStr;
    return '${dateStr.substring(2, 4)}-${dateStr.substring(5, 7)}-${dateStr.substring(8, 10)}';
  }

  /// Formats a DateTime to time format (HH:MM).
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Resolves the image path for an animal species.
  String? _getAnimalImagePath(String? identifier) {
    if (identifier == null) return null;
    if (identifier.startsWith('assets/')) return identifier;
    
    final sanitized = identifier.toLowerCase().replaceAll(' ', '_');
    return 'assets/animals/$sanitized.png';
  }

  /// Builds a detail column with title and value.
  Widget _buildDetailColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _labelStyle),
        Text(
          value,
          style: _valueStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

