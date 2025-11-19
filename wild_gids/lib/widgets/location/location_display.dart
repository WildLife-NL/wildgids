import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildrapport/models/enums/location_type.dart';

class LocationDisplay extends StatefulWidget {
  final VoidCallback onLocationIconTap;
  final String locationText;
  final bool isLoading;
  final Position? position;

  const LocationDisplay({
    super.key,
    required this.onLocationIconTap,
    required this.locationText,
    required this.isLoading,
    this.position,
  });

  String get _displayText {
    if (isLoading) return '';
    if (locationText == LocationType.unknown.displayText) {
      return 'Geen locatie geselecteerd';
    }
    if (position == null) return locationText;

    return '$locationText\n${position!.latitude.toStringAsFixed(6)}, ${position!.longitude.toStringAsFixed(6)}';
  }

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child:
            widget.isLoading
                ? Center(
                  child: SizedBox(
                    height: 36,
                    child: Lottie.asset(
                      'assets/loaders/loading_paw.json',
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      frameRate: FrameRate(60),
                      controller: _animationController,
                      onLoaded: (composition) {
                        _animationController.duration =
                            composition.duration ~/ 2;
                        _animationController.repeat();
                      },
                    ),
                  ),
                )
                : Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onLocationIconTap,
                      child: Image.asset(
                        'assets/location/location_icon.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget._displayText,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
