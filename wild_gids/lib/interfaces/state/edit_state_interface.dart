import 'package:flutter/material.dart';

abstract class EditStateInterface {
  bool get isEditMode;
  void toggleEditMode();
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}
