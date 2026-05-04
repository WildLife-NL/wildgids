import 'package:flutter/material.dart';

abstract class OverzichtInterface {
  // Properties
  String get userName;
  double get topContainerHeight;
  double get welcomeFontSize;
  double get usernameFontSize;
  double get logoWidth;
  double get logoHeight;

  // Methods
  void updateUserName(String newName);

  // State management
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}
