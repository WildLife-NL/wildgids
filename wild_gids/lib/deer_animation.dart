import 'package:flutter/material.dart';

class DeerAnimationPage extends StatefulWidget {
  const DeerAnimationPage({key});

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
      duration: const Duration(seconds: 4),
    );

    // Moves the deer from left (off-screen) to right (off-screen)
    _xPosition = Tween<double>(
      begin: -200, // Start off the left side
      end: 500,    // Exit to the right (tune for screen width)
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Creates a "jump arc"
    _yJump = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -100.0), weight: 50), // jump up
      TweenSequenceItem(tween: Tween(begin: -100.0, end: 0.0), weight: 50), // fall down
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(); // repeat jump cycle
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically position deer higher on the screen
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final baseBottom = screenHeight * 0.6; // roughly 60% from top

    // Deer size: 45% of screen width
    final deerSize = screenWidth * 0.45;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(
                left: _xPosition.value,
                bottom: baseBottom + _yJump.value,
                child: Image.asset(
                  'assets/icons/deer.png',
                  width: deerSize,
                  height: deerSize,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
