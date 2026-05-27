import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/animal_waarneming_models/animal_pin.dart';
import 'package:wildgids/utils/api_datetime.dart';
import 'package:wildgids/utils/location_label.dart';
import 'package:wildgids/utils/species_icon_utils.dart';

class AnimalDetailCard extends StatefulWidget {
  static const double _cardHeight = 205;
  static const double _imageWidth = 150;

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

  String _getSpeciesImagePath(String? speciesName) {
    // Use the centralized utility function
    return getSpeciesCardImagePath(speciesName) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final displayName = animal?.speciesName ?? 'Onbekend dier';
    final formattedDate = _formatDate(animal?.seenAt);
    final formattedTime = _formatTime(animal?.seenAt);
    final locationLabel = _locationLabel ?? '—';
    
    // Use the species name to get the image path if no explicit iconPath provided
    final imagePath = widget.iconPath ?? _getSpeciesImagePath(animal?.speciesName);

    return SizedBox(
      height: AnimalDetailCard._cardHeight,
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFF999999),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: AnimalDetailCard._imageWidth,
              decoration: const BoxDecoration(
                color: Color(0xFFE0D9C9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: _buildImage(imagePath),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                    (animal?.reportType ?? 'Waarneming')
                  .replaceFirstMapped(
                    RegExp(r'^[a-z]'),
                    (m) => m.group(0)!.toUpperCase(),
                  ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailColumn('Datum', formattedDate),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDetailColumn('Tijd', formattedTime),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Geslacht, leeftijd en melder staan niet in de kaart-data.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color.fromARGB(255, 115, 115, 115),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationLabel,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 115, 115, 115),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? iconPath) {
    if (iconPath != null && iconPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: Image.asset(
          iconPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.pets,
            size: 38,
            color: Color(0xFF2D8B5C),
          ),
        ),
      );
    }

    return const Icon(
      Icons.pets,
      size: 38,
      color: Color(0xFF2D8B5C),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color.fromARGB(255, 115, 115, 115),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final local = ApiDateTime.toLocal(dateTime);
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day-$month-$year';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--';
    final local = ApiDateTime.toLocal(dateTime);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}