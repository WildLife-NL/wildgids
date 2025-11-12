import 'package:wildrapport/widgets/toasts/snack_bar_with_progress_bar.dart';

class ToastNotificationHandler {
  static void sendToastNotification(context, String toastMessage, [int? amount]) {
    SnackBarWithProgressBar.show(
      context: context,
      message: toastMessage,
      duration: Duration(seconds: amount ?? 3),
    );
  }
}
