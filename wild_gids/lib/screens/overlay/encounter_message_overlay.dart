import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';

class EncounterMessageOverlay extends StatelessWidget {
  final String message;
  final String? title;
  final int? severity;

  const EncounterMessageOverlay({super.key, required this.message, this.title, this.severity});

  @override
  Widget build(BuildContext context) {
    // choose accent based on severity
    final Color accent = (severity == 1)
        ? Colors.red.shade700
        : (severity == 2)
            ? Colors.orange.shade700
            : AppColors.darkGreen;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent, // No dimmed layer - handled by showDialog barrierColor
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 160),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.lightMintGreen.withOpacity(0.98),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkGreen, width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon / asset (smaller)
                    Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10, top: 2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/icons/animalmeet.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(Icons.pets, color: accent, size: 32),
                        ),
                      ),
                    ),
                    // Texts (constrained)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((title ?? '').isNotEmpty)
                            Text(
                              title!,
                              style: TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if ((title ?? '').isNotEmpty) const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Close X (compact)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkResponse(
                        radius: 18,
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close, size: 18, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
