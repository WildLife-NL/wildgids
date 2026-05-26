import 'package:flutter/material.dart';

/// Matches [CustomNavBar] bar height (excluding safe area).
const double kMainNavBarHeight = 85.0;

/// Bottom margin for floating snackbars above the main tab bar.
EdgeInsets floatingSnackBarMargin(BuildContext context) {
  final padding = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(
    16,
    8,
    16,
    padding.bottom + kMainNavBarHeight + 12,
  );
}

/// Whether the nearest [Scaffold] is [MainNavScreen] (has bottom tab bar).
bool _isOnMainNavScaffold(BuildContext context) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold == null) return false;
  return scaffold.widget.bottomNavigationBar != null;
}

EdgeInsets snackBarMarginForContext(BuildContext context) {
  if (_isOnMainNavScaffold(context)) {
    return floatingSnackBarMargin(context);
  }
  final padding = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(16, 8, 16, padding.bottom + 16);
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: snackBarMarginForContext(context),
        duration: duration,
      ),
    );
}

