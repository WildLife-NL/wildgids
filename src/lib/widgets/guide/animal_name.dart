import 'package:flutter/material.dart';

/// Displays the complete animal name on one line without truncating it.
/// Callers give long names more room before this scales text down as a fallback.
class AnimalName extends StatelessWidget {
  const AnimalName(
    this.name, {
    super.key,
    this.style,
    this.alignment = Alignment.centerLeft,
  });
  final String name;
  final TextStyle? style;
  final Alignment alignment;

  static double widthFor(BuildContext context, String name, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: name,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  static int gridColumns(
    BuildContext context,
    Iterable<String> names, {
    required double width,
    double reserved = 48,
  }) {
    final labelWidth = (width - 14) / 2 - reserved;
    const readable = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
    return names.any((name) => widthFor(context, name, readable) > labelWidth)
        ? 1
        : 2;
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: name,
    excludeFromSemantics: true,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(name, maxLines: 1, softWrap: false, style: style),
    ),
  );
}
