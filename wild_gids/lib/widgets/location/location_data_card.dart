import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocationDataCard extends StatelessWidget {
  final String? cityName;
  final String? streetName;
  final String? houseNumber;
  final bool isLoading;
  final bool isCurrentLocation;
  final double? latitude;
  final double? longitude;

  const LocationDataCard({
    super.key,
    this.cityName,
    this.streetName,
    this.houseNumber,
    this.isLoading = false,
    this.isCurrentLocation = true,
    this.latitude,
    this.longitude,
  });

  String get _fullAddress {
    final List<String> parts = [];
    if (streetName != null) {
      parts.add('${streetName!}${houseNumber != null ? " $houseNumber" : ""}');
    }
    if (cityName != null) {
      parts.add(cityName!);
    }
    if (latitude != null && longitude != null) {
      parts.add(
        '(${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)})',
      );
    }
    return parts.join(', ');
  }

  void _copyAddress(BuildContext context) {
    if (_fullAddress.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _fullAddress));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adres gekopieerd'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildCard(
        child: const Row(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            Text('Locatie wordt geladen...'),
          ],
        ),
      );
    }

    final Color locationColor = isCurrentLocation ? Colors.blue : Colors.red;
    final String titleText =
        isCurrentLocation ? 'Huidige Locatie' : 'Geselecteerde Locatie';

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: locationColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, color: locationColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (streetName != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${streetName!}${houseNumber != null ? " $houseNumber" : ""}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: locationColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_fullAddress.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: locationColor,
                              onPressed: () => _copyAddress(context),
                              tooltip: 'Kopieer adres',
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (latitude != null && longitude != null)
                      Text(
                        '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: locationColor),
                      ),
                    Row(
                      children: [
                        if (cityName != null)
                          Text(
                            cityName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (cityName != null)
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        Text(
                          titleText,
                          style: TextStyle(fontSize: 12, color: locationColor),
                        ),
                      ],
                    ),
                    if (cityName == null && streetName == null)
                      Text(
                        'Locatie niet beschikbaar',
                        style: TextStyle(fontSize: 14, color: locationColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      ),
    );
  }
}
