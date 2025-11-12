import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';

/// Unified error popup matching the provided design reference.
/// Usage: showDialog(context: ctx, builder: (_) => ErrorOverlay(messages: ['Primary line', 'Detail...']))
class ErrorOverlay extends StatelessWidget {
  final List<String> messages;
  final String title;

  /// [messages] shown stacked; first message can be a short summary, rest explanatory.
  /// [title] defaults to 'Fout'.
  const ErrorOverlay({super.key, required this.messages, this.title = 'Fout'});

  @override
  Widget build(BuildContext context) {
  // Split messages into primary + details combined
    final primary = messages.isNotEmpty ? messages.first : '';
    final details = messages.length > 1 ? messages.sublist(1).join('\n') : '';

    return GestureDetector(
      // Tap outside closes
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300, minWidth: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.lightMintGreen, // 0xFFF1F5F2
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red, width: 2),
              ),
              // Cap the overall height to keep the popup compact
              constraints: const BoxConstraints(
                minHeight: 180,
                maxHeight: 180,
              ),
              child: Stack(
                children: [
                  // Content
                  // Center the content within the popup card
                  Center(
                    child: Padding(
                      // Tighter vertical padding to reduce overall height
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.black,
                            size: 30, // smaller icon
                          ),
                          const SizedBox(height: 8),
                          Text(
                            primary.isEmpty ? title : primary,
                            textAlign: TextAlign.center,
                            style: AppTextTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 1.15, // tighter line-height
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              details,
                              textAlign: TextAlign.center,
                              style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                                color: Colors.black,
                                height: 1.2, // compact paragraph spacing
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Close button inside the card padding area
                  Positioned(
                    right: 8,
                    top: 8,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close, size: 20, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
