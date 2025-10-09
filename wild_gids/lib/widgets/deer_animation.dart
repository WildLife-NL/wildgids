// lib/widgets/deer_animation.dart
import 'package:flutter/material.dart';

class DeerAnimationPage extends StatefulWidget {
  const DeerAnimationPage({Key? key}) : super(key: key);

  @override
  State<DeerAnimationPage> createState() => _DeerAnimationPageState();
}

class _DeerAnimationPageState extends State<DeerAnimationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xPosition;
  late Animation<double> _yJump;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6), // Slower, smoother movement
    );

    // Animate across full screen width
    _xPosition = Tween<double>(
      begin: -100, // Start off-screen left
      end: 2000,  // End far right (adjust for slow loop)
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Jump arc
    _yJump = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: -120.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: -120.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

 // lib/widgets/deer_animation.dart
@override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final deerSize = size.width * 0.3;
  final baseBottom = size.height * 0.6; // Lowered from 0.7 → 0.6 (higher number = higher up, so smaller = lower)

  return SizedBox.expand(
    child: Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              left: _xPosition.value,
              bottom: baseBottom + _yJump.value,
              child: Image.asset(
                'assets/icons/deer.png',
                width: deerSize,
                height: deerSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: deerSize,
                    height: deerSize,
                    color: Colors.red,
                    child: const Icon(Icons.error, color: Colors.white),
                  );
                },
              ),
            );
          },
        ),
      ],
    ),
  );
}

}