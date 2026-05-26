import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/utils/api_datetime.dart';
import 'package:wildgids/utils/location_label.dart';

class AnimalDetailCard extends StatefulWidget {
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
  State<AnimalDetailCard> createState() => _AnimalDetailCardState();
}

class _AnimalDetailCardState extends State<AnimalDetailCard> {
  final _locationResolver = LocationMapManager();
  String? _locationLabel;
  int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    _resolveLocationLabel();
  }

  @override
  void didUpdateWidget(AnimalDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPin = oldWidget.animal;
    final pin = widget.animal;
    if (oldPin?.lat != pin?.lat ||
        oldPin?.lon != pin?.lon ||
        oldPin?.locationLabel != pin?.locationLabel) {
      _resolveLocationLabel();
    }
  }

  Future<void> _resolveLocationLabel() async {
    final pin = widget.animal;
    if (pin == null) {
      setState(() => _locationLabel = null);
      return;
    }

    final preset = pin.locationLabel?.trim();
    if (preset != null && preset.isNotEmpty) {
      setState(() => _locationLabel = preset);
      return;
    }

    final generation = ++_resolveGeneration;
    setState(
      () => _locationLabel = formatFriendlyLocation(pin.lat, pin.lon),
    );

    try {
      final address = await _locationResolver.getAddressFromPosition(
        Position(
          latitude: pin.lat,
          longitude: pin.lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );
      if (!mounted || generation != _resolveGeneration) return;
      final trimmed = address.trim();
      if (trimmed.isNotEmpty) {
        setState(() => _locationLabel = formatAddressForDisplay(trimmed));
      }
    } catch (_) {
      // Province/coords fallback already shown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final displayName = animal?.speciesName ?? 'Onbekend dier';
    final formattedDate = _formatDate(animal?.seenAt);
    final formattedTime = _formatTime(animal?.seenAt);

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: AnimalDetailCard._cardHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(widget.iconPath),
            const SizedBox(width: AnimalDetailCard._contentSpacing),
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
      topLeft: Radius.circular(AnimalDetailCard._imageCornerRadius),
      bottomLeft: Radius.circular(AnimalDetailCard._imageCornerRadius),
    );

    return Container(
      width: AnimalDetailCard._imageWidth,
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
    final locationLabel = _locationLabel ?? '—';

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(
          right: AnimalDetailCard._contentSpacing,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Waarneming', style: AnimalDetailCard._headerStyle),
            Text(displayName, style: AnimalDetailCard._animalNameStyle),
            const SizedBox(height: AnimalDetailCard._rowSpacing),
            _buildMetadataRow(
              [
                ('Datum', formattedDate),
                ('Tijd', formattedTime),
              ],
            ),
            const SizedBox(height: AnimalDetailCard._rowSpacing),
            const Text(
              'Geslacht, leeftijd en melder staan niet in de kaart-data.',
              style: AnimalDetailCard._labelStyle,
            ),
            const SizedBox(height: AnimalDetailCard._rowSpacing),
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
          if (i > 0) const SizedBox(width: AnimalDetailCard._columnSpacing),
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
            maxLines: 2,
            style: AnimalDetailCard._labelStyle,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final local = ApiDateTime.toLocal(dateTime);
    final yy = (local.year % 100).toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '$yy-$mm-$dd';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final local = ApiDateTime.toLocal(dateTime);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildDetailColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AnimalDetailCard._labelStyle),
        Text(
          value,
          style: AnimalDetailCard._valueStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
