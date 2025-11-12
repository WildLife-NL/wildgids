import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:wildrapport/interfaces/other/permission_interface.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';

class PermissionManager implements PermissionInterface {
  PermissionManager();

  @override
  Future<bool> isPermissionGranted(PermissionType permission) async {
    final isGranted = await Permission.location.isGranted;
    debugPrint('[PermissionManager] Checking permission status: $isGranted');
    return isGranted;
  }

  @override
  Future<bool> requestPermission(
    BuildContext context,
    PermissionType permission, {
    bool showRationale = true,
  }) async {
    debugPrint(
      '[PermissionManager] Requesting permission, showRationale: $showRationale',
    );

    if (showRationale) {
      debugPrint('[PermissionManager] Showing permission rationale dialog');
      bool shouldProceed = await showPermissionRationale(context, permission);
      debugPrint(
        '[PermissionManager] User response to rationale: $shouldProceed',
      );
      if (!shouldProceed) return false;
    }

    debugPrint('[PermissionManager] Making actual permission request');
    final status = await Permission.location.request();
    debugPrint(
      '[PermissionManager] Permission request result: ${status.isGranted}',
    );
    return status.isGranted;
  }

  @override
  Future<bool> showPermissionRationale(
    BuildContext context,
    PermissionType permission,
  ) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.lightMintGreen,
            title: Text(
              'Locatie Toegang',
              style: AppTextTheme.textTheme.titleMedium?.copyWith(
                color: Colors.black,
              ),
            ),
            content: Text(
              'We hebben toegang tot je locatie nodig om nauwkeurig te kunnen rapporteren waar je dieren hebt waargenomen.',
              style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkGreen,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                child: const Text('Niet nu'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkGreen,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                child: const Text('Doorgaan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Remove handleInitialPermissions as it's no longer needed
  @override
  Future<void> handleInitialPermissions(BuildContext context) async {
    // No longer needed as permissions are handled in the location flow
  }
}
