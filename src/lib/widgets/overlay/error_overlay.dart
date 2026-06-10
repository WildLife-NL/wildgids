import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_text_theme.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class ErrorOverlay extends StatelessWidget {
  final List<String> messages;
  final String? title;
  final String? instruction;

  /// messages: one or more descriptive messages. If the first message is
  /// short it will be used as the title and the remainder shown as details.
  /// Optionally provide [title] and [instruction] to override defaults.
  const ErrorOverlay({
    super.key,
    required this.messages,
    this.title,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final rawTitle = title;
    String titleToShow;
    String bodyToShow = '';

    if (rawTitle != null && rawTitle.isNotEmpty) {
      titleToShow = rawTitle;
      bodyToShow = messages.join('\n');
    } else if (messages.isNotEmpty) {
      if (messages.first.length <= 60 && messages.length > 1) {
        titleToShow = messages.first;
        bodyToShow = messages.sublist(1).join('\n');
      } else if (messages.length == 1 && messages.first.length <= 80) {
        titleToShow = messages.first;
        bodyToShow = instruction ?? '';
      } else {
        titleToShow = 'Fout';
        bodyToShow = messages.join('\n');
      }
    } else {
      titleToShow = 'Fout';
      bodyToShow = instruction ?? '';
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              titleToShow,
              style: TextStyle(
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (bodyToShow.isNotEmpty) ...[
              Text(
                bodyToShow,
                textAlign: TextAlign.center,
                style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                  fontSize: responsive.fontSize(13),
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
            ] else
              const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Oké',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

