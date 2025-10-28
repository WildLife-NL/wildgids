import 'package:flutter/material.dart';
import 'package:wildrapport/widgets/location/living_lab_selector.dart';

class MapScreen extends StatefulWidget {
  final Widget mapWidget;
  final String title;
  final VoidCallback? onBackPressed;

  const MapScreen({
    super.key,
    required this.mapWidget,
    this.title = 'Kaart',
    this.onBackPressed,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            widget.mapWidget,
            Positioned(
              left: 16,
              bottom: 96,
              child: LivingLabSelector(currentLabName: widget.title),
            ),
          ],
        ),
      ),
    );
  }
}
