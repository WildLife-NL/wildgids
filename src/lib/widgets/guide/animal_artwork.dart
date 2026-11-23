import 'package:flutter/material.dart';

/// Frames the existing illustrations without altering the source assets.
/// Feathering the paper edges avoids a visible rectangle against the page.
class AnimalArtwork extends StatelessWidget {
  const AnimalArtwork({
    super.key,
    required this.imagePath,
    this.label,
    this.zoom = 1.10,
  });

  final String? imagePath;
  final String? label;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return const Center(
        child: Icon(Icons.pets_outlined, size: 48, color: Color(0xFF003B2B)),
      );
    }
    final picture = Image.asset(
      imagePath!,
      fit: BoxFit.contain,
      semanticLabel: label,
      excludeFromSemantics: label == null,
      errorBuilder:
          (_, _, _) => const Center(
            child: Icon(
              Icons.pets_outlined,
              size: 48,
              color: Color(0xFF003B2B),
            ),
          ),
    );
    return FittedBox(
      fit: BoxFit.contain,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback:
            (bounds) => const LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0, 0.15, 0.85, 1],
            ).createShader(bounds),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback:
              (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0, 0.12, 0.88, 1],
              ).createShader(bounds),
          child: ClipRect(child: Transform.scale(scale: zoom, child: picture)),
        ),
      ),
    );
  }
}
