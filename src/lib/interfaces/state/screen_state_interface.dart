import 'package:flutter/material.dart';

abstract class ScreenStateInterface {
  void loadScreenState();
  void saveScreenState();
  void updateState(String key, dynamic value);
  Map<String, dynamic> getCurrentState();
  void safeSetState(VoidCallback fn);
}

// Remove ReportManagerInterface methods that are now handled by NavigationStateInterface
