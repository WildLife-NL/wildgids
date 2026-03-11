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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom nav bar items
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
                tab: NavTab.rapporten,
                iconPath: 'assets/icons/nav-bar/rapporten.svg',
                selectedIconPath: 'assets/icons/nav-bar/rapport-selected.svg',
                label: 'Rapporten',
              ),
              // Empty space for center button
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
          // Center floating button
          Positioned(
            top: -20,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: _buildCenterButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required NavTab tab,
    required String iconPath,
    String? selectedIconPath,
    required String label,
  }) {
    final isSelected = currentTab == tab;
    final color = isSelected ? const Color(0xFF37A904) : const Color(0xFFB0B0B0);
    
    // Use selected icon if active
    final String displayIconPath = isSelected 
        ? (selectedIconPath ?? iconPath.replaceAll('.svg', '-selected.svg'))
        : iconPath;
    
    return GestureDetector(
      onTap: () => onTabSelected(tab),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top indicator line for selected state
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF37A904) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            SvgPicture.asset(
              displayIconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
    final color = isSelected ? const Color(0xFF37A904) : const Color(0xFFB0B0B0);
    
    // Use selected icon if active
    final String iconPath = isSelected 
        ? 'assets/icons/nav-bar/kaart-selected.svg'
        : 'assets/icons/nav-bar/kaart.svg';
    
    return GestureDetector(
      onTap: () => onTabSelected(NavTab.kaart),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF37A904) : const Color(0xFF8FBC8F),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
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
              fontSize: 12,
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
