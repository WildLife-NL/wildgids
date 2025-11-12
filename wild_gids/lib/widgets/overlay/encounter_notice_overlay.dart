import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/constants/app_text_theme.dart';

/// Message-style popup for encounter/tracking notices on the map.
/// Displays the animalmeet icon and a centered message in a chat-bubble style.
class EncounterNoticeOverlay extends StatelessWidget {
  final String message;

  const EncounterNoticeOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap outside to dismiss
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, minWidth: 320),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.lightMintGreen.withValues(alpha: 0.85), // 0xFFF1F5F2 with transparency
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkGreen, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minHeight: 100,
                maxHeight: 160,
              ),
              child: Stack(
                children: [
                  // Content centered
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // animalmeet icon on the left
                          Image.asset(
                            'assets/icons/animalmeet.png',
                            width: 36,
                            height: 36,
                          ),
                          const SizedBox(width: 12),
                          // Message text
                          Expanded(
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                height: 1.25,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    right: 8,
                    top: 8,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close, size: 18, color: Colors.black54),
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
