import 'package:flutter/material.dart';

class CartoAttribution extends StatelessWidget {
  const CartoAttribution({super.key, this.alignment = Alignment.bottomRight});
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ColoredBox(
          color: const Color(0xE6FFFFFF),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Text(
              '\u00a9 CARTO\n\u00a9 OpenStreetMap contributors',
              textAlign:
                  alignment == Alignment.bottomLeft
                      ? TextAlign.left
                      : TextAlign.right,
              style: const TextStyle(fontSize: 10, color: Color(0xFF333333)),
            ),
          ),
        ),
      ),
    ),
  );
}
