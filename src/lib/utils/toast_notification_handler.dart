import 'package:wildgids/widgets/toasts/snack_bar_with_progress_bar.dart';
import 'package:wildgids/utils/notification_service.dart';

class ToastNotificationHandler {
  /// In-app snackbar; optional system push only when [asSystemNotification] is true
  /// and the user has Meldingen enabled in profile.
  static void sendToastNotification(
    context,
    String toastMessage, [
    int? amount,
    bool asSystemNotification = false,
  ]) {
    SnackBarWithProgressBar.show(
      context: context,
      message: toastMessage,
      duration: Duration(seconds: amount ?? 3),
    );

    if (!asSystemNotification) return;

    NotificationService.instance.show(
      title: 'WildGids',
      body: toastMessage,
    );
  }
}

