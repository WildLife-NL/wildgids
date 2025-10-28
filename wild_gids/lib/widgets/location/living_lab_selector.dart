import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/providers/map_provider.dart';
import 'package:wildrapport/screens/belonging/belonging_location_screen.dart';
import 'package:wildrapport/widgets/location/livinglab_map_widget.dart';
import 'package:wildrapport/screens/location/map_screen.dart';
import 'package:provider/provider.dart';

class LivingLabSelector extends StatefulWidget {
  final String currentLabName;

  const LivingLabSelector({super.key, required this.currentLabName});

  @override
  State<LivingLabSelector> createState() => _LivingLabSelectorState();
}

class _LivingLabSelectorState extends State<LivingLabSelector>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  final Duration _expandDuration = const Duration(milliseconds: 200);

  void _selectLab(String labName) {
    if (labName == widget.currentLabName) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _isExpanded = false);
    });

    final labData =
        labName == 'Nationaal Park Zuid-Kennemerland'
            ? (center: const LatLng(52.3874, 4.5753), offset: 0.018)
            : (center: const LatLng(51.1950, 5.7230), offset: 0.045);

    // Reset map state without creating a new controller
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    mapProvider.resetMapState();

    // Determine if we're in the possession flow
    // Method 1: Check the current route name
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    bool isFromPossession =
        routeName.contains('Possession') || routeName.contains('Possesion');

    // Method 2: Check if the current LivingLabMapScreen has isFromPossession=true
    if (!isFromPossession) {
      final currentMapScreen =
          context.findAncestorWidgetOfExactType<LivingLabMapScreen>();
      isFromPossession = currentMapScreen?.isFromPossession ?? false;
    }

    // Method 3: Check if we can find a PossesionLocationScreen in the widget tree
    if (!isFromPossession) {
      isFromPossession =
          context.findAncestorWidgetOfExactType<BelongingLocationScreen>() !=
          null;
    }

    debugPrint(
      '[LivingLabSelector] Selecting lab: $labName, isFromPossession: $isFromPossession',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: RouteSettings(
          name: isFromPossession ? 'PossesionLivingLabMap' : 'LivingLabMap',
        ),
        builder:
            (_) => MapScreen(
              title: labName,
              mapWidget: LivingLabMapScreen(
                labName: labName,
                labCenter: labData.center,
                boundaryOffset: labData.offset,
                isFromPossession: isFromPossession, // Pass the flag
              ),
            ),
      ),
    );
  }

  Widget _buildLabOption(String labName) {
    final isSelected = labName == widget.currentLabName;
    return GestureDetector(
      onTap: () => _selectLab(labName),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        margin: const EdgeInsets.only(
          bottom: 6,
        ), // Slight space between options
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brown.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                labName,
                style: TextStyle(
                  color: AppColors.brown,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: AppColors.brown, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return AnimatedSize(
      duration: _expandDuration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.brown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Living Labs',
                    style: TextStyle(
                      color: AppColors.brown,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_left, color: AppColors.brown, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            _buildLabOption('Nationaal Park Zuid-Kennemerland'),
            _buildLabOption('Grenspark Kempen-Broek'),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsed() {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_rounded, color: AppColors.brown, size: 22),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: AppColors.brown, size: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
    );
  }
}
