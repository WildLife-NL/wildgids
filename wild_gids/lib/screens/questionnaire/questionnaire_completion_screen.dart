import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/screens/shared/overzicht_screen.dart';

class QuestionnaireCompletionScreen extends StatefulWidget {
  const QuestionnaireCompletionScreen({super.key});

  @override
  State<QuestionnaireCompletionScreen> createState() =>
      _QuestionnaireCompletionScreenState();
}

class _QuestionnaireCompletionScreenState
    extends State<QuestionnaireCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xPosition;
  late Animation<double> _yJump;
  bool _isHovered = false;
  bool _isPressed = false;

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
      end: 500, // Exit to the right (tune for screen width)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    // Creates a "jump arc"
    _yJump = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -100.0),
        weight: 50,
      ), // jump up
      TweenSequenceItem(
        tween: Tween(begin: -100.0, end: 0.0),
        weight: 50,
      ), // fall down
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(); // repeat jump cycle
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToOverview() {
    context.read<NavigationStateInterface>().pushAndRemoveUntil(
      context,
      OverzichtScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _isHovered || _isPressed;

    // Dynamically position deer higher on the screen
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final baseBottom = screenHeight * 0.75; // roughly 75% from top (moved up)

    // Deer size: 45% of screen width
    final deerSize = screenWidth * 0.45;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Jumping deer animation
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
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Thank you text
                    const Text(
                      'Bedankt.',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Report sent text
                    const Text(
                      'Gids verzonden\nen succesvol afgerond.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle text
                    const Text(
                      'U kunt deze bekijken in uw profiel.',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Roboto',
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),

                    // Button to go to overview
                    MouseRegion(
                      onEnter: (_) => setState(() => _isHovered = true),
                      onExit: (_) => setState(() => _isHovered = false),
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) {
                          setState(() => _isPressed = false);
                          _navigateToOverview();
                        },
                        onTapCancel: () => setState(() => _isPressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isActive ? AppColors.darkGreen : Colors.white,
                            border: Border.all(
                              color: AppColors.darkGreen,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Terug naar Overzicht',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                              color:
                                  isActive ? Colors.white : AppColors.darkGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ], // children of Column
                ), // Column
              ), // Padding
            ), // Center
          ), // SafeArea
        ], // children of Stack
      ), // Stack / body
    ); // Scaffold
  }
}

