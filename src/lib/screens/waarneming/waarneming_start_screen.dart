import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/screens/waarneming/location_selection_screen.dart';
import 'package:provider/provider.dart';

class WaarnemmingStartScreen extends StatelessWidget {
  const WaarnemmingStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6F4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 70, bottom: 16.0),
              child: Text(
                'Meld uw waarneming',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: Colors.black,
                    ),
              ),
            ),
            
            // Map section with binoculars overlay and start button
            Padding(
              padding: const EdgeInsets.only(
                top: 80.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Map background image - full height
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color.fromARGB(60, 0, 0, 0), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icons/map-pic.jpg',
                        height: 320,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  // Start button - positioned directly below binoculars
                  Positioned(
                    top: 170,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color.fromARGB(95, 0, 0, 0),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              final navigationManager = context.read<NavigationStateInterface>();
                              debugPrint('[Waarneming] Start new sighting');
                              navigationManager.pushForward(
                                context,
                                const LocationSelectionScreen(),
                              );
                            },
                            child: Column(
                              children: [
                                Text(
                                  'Start',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nieuwe Waarneming Starten',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Binoculars icon in dark circle - rendered on top of button
                  Positioned(
                    top: 80,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Color(0xFF333333),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/binoculars-filled.svg',
                          width: 48,
                          height: 48,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Recent sightings section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recente waarnemingen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRecentSightingsList(context),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSightingsList(BuildContext context) {
    // Placeholder data until this list is fed from API state.
    final recentSightings = [
      {
        'day': 'Vandag',
        'animal': 'Eekhoorn',
        'distance': '3km verderop',
        'image': 'assets/animals/eekhoorn.png',
      },
      {
        'day': 'Gisteren',
        'animal': 'Ree',
        'distance': '5km verderop',
        'image': 'assets/animals/ree.png',
      },
      {
        'day': '3 Dagen Geleden',
        'animal': 'Vos',
        'distance': '8km verderop',
        'image': 'assets/animals/vos.png',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        children: List.generate(recentSightings.length, (index) {
          final sighting = recentSightings[index];
          final isLast = index == recentSightings.length - 1;
          
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Detail navigation can be wired when a destination exists.
                  debugPrint('[Waarneming] Tapped sighting: ${sighting['animal']}');
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Animal image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          sighting['image']!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.pets, size: 24),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      // Sighting info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sighting['day']!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sighting['animal']!,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Distance
                      Text(
                        sighting['distance']!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Divider - not after last item
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.grey[300],
                  indent: 60,
                  endIndent: 0,
                ),
            ],
          );
        }),
      ),
    );
  }
}
