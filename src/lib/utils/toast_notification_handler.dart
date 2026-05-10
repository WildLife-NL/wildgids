import 'package:wildgids/widgets/toasts/snack_bar_with_progress_bar.dart';
import 'package:wildgids/utils/notification_service.dart';

class ToastNotificationHandler {
  static void sendToastNotification(
    context,
    String toastMessage, [
    int? amount,
  ]) {
    SnackBarWithProgressBar.show(
      context: context,
      message: toastMessage,
      duration: Duration(seconds: amount ?? 3),
    );

    // Also surface as a system notification on the device
    NotificationService.instance.show(
      title: 'Wild Gids',
      body: toastMessage,
    );
  }
}

