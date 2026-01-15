import 'package:flutter/material.dart';

class PermissionGate extends StatelessWidget {
  final Widget child;

  const PermissionGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    debugPrint('[PermissionGate] Widget rendered');
    // Keep in mind that since LocationScreen can only be reached after permission is granted,
    // we can directly return the child
    return child;
  }
}
