/// Custom navigation bar with curved cutout for center floating button.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/enums/nav_tab.dart';

class CustomNavBar extends StatelessWidget {
  final NavTab currentTab;
  final ValueChanged<NavTab> onTabSelected;

  const CustomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  // Design constants
  // Size constants
  static const double _barHeight = 85.0;
  static const double _centerButtonSize = 60.0;
  static const double _centerButtonOffset = -20.0;
  static const double _centerButtonPadding = 13.0;
  static const double _bumpRadius = 30.0;
  static const double _bumpShoulder = 13.0;
  
  // Color constants
  static const Color _activeColor = Color(0xFF37A904);
  static const Color _inactiveColor = Color(0xFFB0B0B0);
  static const Color _centerButtonColor = Color(0xFF8FBC8F);
  static const Color _navBarBackground = Colors.white;
  
  // Icon and text sizing
  static const double _iconSize = 24.0;
  static const double _fontSize = 12.0;
  static const double _indicatorHeight = 3.0;
  static const double _indicatorWidth = 40.0;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
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
                    _buildNavItem(
                      tab: NavTab.soorten,
                      iconPath: 'assets/icons/nav-bar/soorten.svg',
                      selectedIconPath: 'assets/icons/nav-bar/soorten-selected.svg',
                      label: 'Soorten',
                    ),
                    _buildNavItem(
                      tab: NavTab.waarneming,
                      iconPath: 'assets/icons/nav-bar/rapporten.svg',
                      selectedIconPath: 'assets/icons/nav-bar/rapport-selected.svg',
                      label: 'Rapporten',
                    ),
                    
                    const SizedBox(width: 60),
                    
                    _buildNavItem(
                      tab: NavTab.logboek,
                      iconPath: 'assets/icons/nav-bar/logboek.svg',
                      selectedIconPath: 'assets/icons/nav-bar/logboek-selected.svg',
                      label: 'LogBoek',
                    ),
                    _buildNavItem(
                      tab: NavTab.instellingen,
                      iconPath: 'assets/icons/nav-bar/settings.svg',
                      selectedIconPath: 'assets/icons/nav-bar/settings-selected.svg',
                      label: 'Instellingen',
                    ),
                  ],
                ),
                
                // Floating center button
                Positioned.fill(
                  top: _centerButtonOffset,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildCenterButton(),
                  ),
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
    required String iconPath,
    String? selectedIconPath,
    required String label,
  }) {
    final isSelected = currentTab == tab;
    final color = isSelected ? _activeColor : _inactiveColor;
    final String displayIconPath = isSelected 
        ? (selectedIconPath ?? iconPath.replaceAll('.svg', '-selected.svg'))
        : iconPath;
    
    return GestureDetector(
      onTap: () => onTabSelected(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            
            SvgPicture.asset(
              displayIconPath,
              width: _iconSize,
              height: _iconSize,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
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
    final String iconPath = isSelected 
        ? 'assets/icons/nav-bar/kaart-selected.svg'
        : 'assets/icons/nav-bar/kaart.svg';
    
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
              ),
              child: Padding(
                padding: const EdgeInsets.all(_centerButtonPadding),
                child: SvgPicture.asset(
                  iconPath,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
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

/// Custom painter for nav bar with curved cutout
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
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    final double centerX = size.width / 2;

    // Draw the nav bar shape with curved cutout
    path.moveTo(0, 0);
    path.lineTo(centerX - bumpRadius - bumpShoulder, 0);
    
    // Left curve
    path.cubicTo(
      centerX - bumpRadius - 6,
      0,
      centerX - bumpRadius - 3,
      -bumpRadius + 5,
      centerX,
      -bumpRadius,
    );
    
    // Right curve
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
