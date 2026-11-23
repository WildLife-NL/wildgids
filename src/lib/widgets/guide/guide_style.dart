import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared visual treatment for the diary and animal guide.
class GuideStyle {
  static const ink = Color(0xFF003D2E);
  static const muted = Color(0xFF60695F);
  static const border = Color(0xFFE5E7DD);
  static const surface = Color(0xFFF0F2E9);
  static const background = Color(0xFFFFFFFC);

  static ShapeBorder get card => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: const BorderSide(color: border),
  );

  static ButtonStyle get primaryButton => FilledButton.styleFrom(
    backgroundColor: ink,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(56),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontFamily: 'Overpass',
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  );
}

class GuideBrand extends StatelessWidget {
  const GuideBrand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SvgPicture.asset(
        'assets/logo-wildlife.svg',
        width: 36,
        height: 36,
        colorFilter: const ColorFilter.mode(GuideStyle.ink, BlendMode.srcIn),
      ),
      const SizedBox(width: 10),
      const Flexible(
        child: Text(
          'Wild Gids',
          style: TextStyle(
            color: GuideStyle.ink,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}
