import 'package:flutter/material.dart';

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
    return Scaffold(body: SafeArea(child: widget.mapWidget));
  }
}
