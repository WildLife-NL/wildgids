import 'package:flutter/material.dart';

abstract class NavigationStateInterface {
  /// Cleans up controllers and resources
  void dispose();

  /// Clears navigation stack and returns to home screen
  void resetToHome(BuildContext context);

  /// Clears all application state and saved objects
  void clearApplicationState(BuildContext context);

  /// Navigates to a new screen, removing all previous routes
  void pushAndRemoveUntil(BuildContext context, Widget screen);

  /// Replaces current screen with new screen
  void pushReplacementForward(BuildContext context, Widget screen);

  /// Replaces current screen with previous screen
  void pushReplacementBack(BuildContext context, Widget screen);

  /// Pushes a new screen onto the navigation stack
  void pushForward(BuildContext context, Widget screen);
}
