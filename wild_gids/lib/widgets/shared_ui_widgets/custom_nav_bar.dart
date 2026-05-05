import 'package:flutter/material.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
//import 'dart:math' as math;

class CustomNavBar extends StatelessWidget {
  final NavTab currentTab;
  final ValueChanged<NavTab> onTabSelected;

  const CustomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  static const double _barHeight = 85.0;
  static const double _centerButtonSize = 60.0;
  static const double _centerButtonOffset = -20.0;
  static const double _bumpRadius = 30.0;
  static const double _bumpShoulder = 13.0;

  static const Color _activeColor = Color(0xFF37A904);
  static const Color _inactiveColor = Color(0xFFB0B0B0);
  static const Color _centerButtonColor = Color(0xFF8FBC8F);
  static const Color _navBarBackground = Colors.white;

  static const double _iconSize = 24.0;
  static const double _fontSize = 12.0;
  static const double _indicatorHeight = 3.0;
  static const double _indicatorWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: 45,
          left: screenWidth / 2 - 35,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: _barHeight,
          child: CustomPaint(
            painter: NavBarCurvePainter(
              backgroundColor: _navBarBackground,
              bumpRadius: _bumpRadius,
              bumpShoulder: _bumpShoulder,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: _buildNavItem(
                        tab: NavTab.zones,
                        icon: Icons.add_location_alt,
                        label: 'Soorten',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        tab: NavTab.waarneming,
                        icon: Icons.visibility, // <-- binocular/observation icon
                        label: 'Waarneming',    // <-- singular, as requested
                      ),
                    ),
                    const SizedBox(width: 60), // Space for the center button (FAB)
                    Expanded(
                      child: _buildNavItem(
                        tab: NavTab.logboek,
                        icon: Icons.menu_book,
                        label: 'Logboek',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        tab: NavTab.profile,
                        icon: Icons.person,
                        label: 'Profiel',
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: _centerButtonOffset,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildCenterButton()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required NavTab tab,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentTab == tab;
    final color = isSelected ? _activeColor : _inactiveColor;

    return GestureDetector(
      onTap: () => onTabSelected(tab),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: _indicatorHeight,
              width: _indicatorWidth,
              decoration: BoxDecoration(
                color: isSelected ? _activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Icon(icon, size: _iconSize, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: _fontSize,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = currentTab == NavTab.kaart;
    final color = isSelected ? _activeColor : _inactiveColor;

    return GestureDetector(
      onTap: () => onTabSelected(NavTab.kaart),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _centerButtonSize,
            height: _centerButtonSize,
            decoration: BoxDecoration(
              color: isSelected ? _activeColor : _centerButtonColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.map, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Kaart',
            style: TextStyle(
              fontSize: _fontSize,
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class NavBarCurvePainter extends CustomPainter {
  final Color backgroundColor;
  final double bumpRadius;
  final double bumpShoulder;

  const NavBarCurvePainter({
    this.backgroundColor = Colors.white,
    this.bumpRadius = 30.0,
    this.bumpShoulder = 13.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill;

    final shadowPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    final double centerX = size.width / 2;

    path.moveTo(0, 0);
    path.lineTo(centerX - bumpRadius - bumpShoulder, 0);

    path.cubicTo(
      centerX - bumpRadius - 6,
      0,
      centerX - bumpRadius - 3,
      -bumpRadius + 5,
      centerX,
      -bumpRadius,
    );

    path.cubicTo(
      centerX + bumpRadius + 3,
      -bumpRadius + 5,
      centerX + bumpRadius + 6,
      0,
      centerX + bumpRadius + bumpShoulder,
      0,
    );
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NavBarCurvePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.bumpRadius != bumpRadius ||
        oldDelegate.bumpShoulder != bumpShoulder;
  }
}

