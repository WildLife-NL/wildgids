import 'package:flutter/material.dart';

enum PermissionType { location }

abstract class PermissionInterface {
  /// Check if a specific permission is granted
  Future<bool> isPermissionGranted(PermissionType permission);

  /// Request a specific permission with explanation dialog
  Future<bool> requestPermission(
    BuildContext context,
    PermissionType permission, {
    bool showRationale = true,
  });

  /// Show permission rationale dialog
  Future<bool> showPermissionRationale(
    BuildContext context,
    PermissionType permission,
  );

  /// Handle initial app permissions
  Future<void> handleInitialPermissions(BuildContext context);
}
