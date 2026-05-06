import 'package:flutter/material.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';

class AnimalDetailCard extends StatelessWidget {
  static const double _cardHeight = 150;
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
  final String? iconPath;

  const AnimalDetailCard({
    super.key,
    this.animal,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = animal?.speciesName ?? 'Onbekend dier';
    final formattedDate = _formatDate(animal?.seenAt);
    final formattedTime = _formatTime(animal?.seenAt);

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: _cardHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(iconPath),
            const SizedBox(width: _contentSpacing),
            _buildDetailsSection(
              displayName,
              formattedDate,
              formattedTime,
              animal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String? iconPath) {
    final radius = const BorderRadius.only(
      topLeft: Radius.circular(_imageCornerRadius),
      bottomLeft: Radius.circular(_imageCornerRadius),
    );

    return Container(
      width: _imageWidth,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: radius,
        border: Border.all(
          color: Colors.grey[400] ?? Colors.grey,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Center(
            child: iconPath != null
                ? Image.asset(
                    iconPath,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.pets,
                        size: 56,
                        color: Colors.grey[500],
                      );
                    },
                  )
                : Icon(
                    Icons.pets,
                    size: 56,
                    color: Colors.grey[500],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(
    String displayName,
    String formattedDate,
    String formattedTime,
    AnimalPin? pin,
  ) {
    final locationLabel = pin != null
        ? '${pin.lat.toStringAsFixed(5)}, ${pin.lon.toStringAsFixed(5)}'
        : '—';

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
            const Text('Waarneming', style: _headerStyle),
            Text(displayName, style: _animalNameStyle),
            const SizedBox(height: _rowSpacing),
            _buildMetadataRow(
              [
                ('Datum', formattedDate),
                ('Tijd', formattedTime),
              ],
            ),
            const SizedBox(height: _rowSpacing),
            const Text(
              'Geslacht, leeftijd en melder staan niet in de kaart-data.',
              style: _labelStyle,
            ),
            const SizedBox(height: _rowSpacing),
            _buildInfoRow(Icons.location_on, locationLabel),
          ],
        ),
      ),
    );
  }

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

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final dateStr = dateTime.toString().split(' ')[0];
    if (dateStr.length != 10) return dateStr;
    return '${dateStr.substring(2, 4)}-${dateStr.substring(5, 7)}-${dateStr.substring(8, 10)}';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildDetailColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
