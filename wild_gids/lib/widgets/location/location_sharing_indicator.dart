import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/providers/app_state_provider.dart';

/// A widget that displays a persistent visual indicator when location sharing is enabled.
/// Shows a location icon with optional animated pulse effect.
class LocationSharingIndicator extends StatelessWidget {
  final bool showLabel;
  final double iconSize;
  final MainAxisAlignment alignment;

  const LocationSharingIndicator({
    super.key,
    this.showLabel = false,
    this.iconSize = 20,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appStateProvider, _) {
        if (!appStateProvider.isLocationTrackingEnabled) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignment,
          children: [
            _PulsingLocationIcon(iconSize: iconSize),
            if (showLabel) ...[
              SizedBox(width: iconSize * 0.5),
              Text(
                'Locatie actief',
                style: TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: iconSize * 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// A pulsing location icon that animates when location tracking is active.
class _PulsingLocationIcon extends StatefulWidget {
  final double iconSize;

  const _PulsingLocationIcon({required this.iconSize});

  @override
  State<_PulsingLocationIcon> createState() => _PulsingLocationIconState();
}

class _PulsingLocationIconState extends State<_PulsingLocationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Tooltip(
        message: 'Locatie delen is ingeschakeld',
        child: Icon(
          Icons.location_on,
          color: AppColors.darkGreen,
          size: widget.iconSize,
        ),
      ),
    );
  }
}

/// A compact indicator badge suitable for display in app bars or headers.
class LocationSharingBadge extends StatelessWidget {
  final double badgeSize;

  const LocationSharingBadge({
    super.key,
    this.badgeSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appStateProvider, _) {
        if (!appStateProvider.isLocationTrackingEnabled) {
          return const SizedBox.shrink();
        }

        return Container(
          width: badgeSize,
          height: badgeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkGreen.withOpacity(0.2),
            border: Border.all(
              color: AppColors.darkGreen,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Tooltip(
              message: 'Locatie delen is ingeschakeld',
              child: Icon(
                Icons.location_on,
                color: AppColors.darkGreen,
                size: badgeSize * 0.6,
              ),
            ),
          ),
        );
      },
    );
  }
}
