import 'package:flutter/material.dart';
import 'package:wildrapport/interfaces/other/overzicht_interface.dart';

class OverzichtManager implements OverzichtInterface {
  final List<VoidCallback> _listeners = [];
  String _userName = 'John Doe';

  // Constants
  @override
  final double topContainerHeight = 285.0;

  @override
  final double welcomeFontSize = 20.0;

  @override
  final double usernameFontSize = 24.0;

  @override
  final double logoWidth = 180.0;

  @override
  final double logoHeight = 180.0;

  @override
  String get userName => _userName;

  @override
  void updateUserName(String newName) {
    _userName = newName;
    _notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
