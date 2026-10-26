import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wildgids/managers/map/amenity_map_controller.dart';
import 'package:wildgids/models/ui_models/living_lab_area.dart';
import 'package:wildgids/models/ui_models/map_amenity.dart';

const _amenityGreen = Color(0xFF075044);

Color amenityColor(AmenityCategory category) => switch (category) {
  AmenityCategory.toilet => const Color(0xFF7B3FA1),
  AmenityCategory.parking => const Color(0xFF2463A5),
  AmenityCategory.drinkingWater => const Color(0xFF087E8B),
  AmenityCategory.viewpoint => const Color(0xFF3C7D35),
  AmenityCategory.birdHide => const Color(0xFF9A6218),
  AmenityCategory.entrance => const Color(0xFFBA4823),
  AmenityCategory.visitorCentre => const Color(0xFF117663),
  AmenityCategory.estate => const Color(0xFF865846),
  AmenityCategory.pointOfInterest => const Color(0xFFB33369),
};

Color amenityClusterColor(Iterable<Color> colors) {
  final distinct = colors.toSet();
  return distinct.length == 1 ? distinct.single : const Color(0xFF3E484D);
}

IconData amenityIcon(AmenityCategory category) => switch (category) {
  AmenityCategory.toilet => Icons.wc,
  AmenityCategory.parking => Icons.local_parking,
  AmenityCategory.drinkingWater => Icons.water_drop_outlined,
  AmenityCategory.viewpoint => Icons.landscape_outlined,
  AmenityCategory.birdHide => Icons.visibility_outlined,
  AmenityCategory.entrance => Icons.meeting_room_outlined,
  AmenityCategory.visitorCentre => Icons.info_outline,
  AmenityCategory.estate => Icons.account_balance_outlined,
  AmenityCategory.pointOfInterest => Icons.place_outlined,
};

class AmenityMapLayer extends StatelessWidget {
  const AmenityMapLayer({super.key, required this.controller});
  final AmenityMapController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final visible = controller.visibleAmenities;
      if (visible.isEmpty) return const SizedBox.shrink();
      final markerColors = {
        for (final amenity in visible)
          ValueKey(amenity.id): amenityColor(amenity.category),
      };
      return MarkerClusterLayerWidget(
        // Rebuild the cluster tree when filters change, including spiderfied pins.
        key: ValueKey(visible.map((amenity) => amenity.id).join(',')),
        options: MarkerClusterLayerOptions(
          maxClusterRadius: 48,
          size: const Size(44, 44),
          maxZoom: 17,
          disableClusteringAtZoom: 18,
          padding: const EdgeInsets.all(64),
          showPolygon: false,
          spiderfyCluster: true,
          markerChildBehavior: true,
          markers:
              visible
                  .map(
                    (amenity) => Marker(
                      key: ValueKey(amenity.id),
                      point: LatLng(amenity.latitude, amenity.longitude),
                      width: 44,
                      height: 44,
                      rotate: true,
                      child: Tooltip(
                        message:
                            amenity.isExample
                                ? 'Fictief voorbeeld: ${amenity.name}'
                                : amenity.name,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey('amenity-${amenity.id}'),
                            customBorder: const CircleBorder(),
                            onTap:
                                () => showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  useSafeArea: true,
                                  builder:
                                      (_) =>
                                          AmenityDetailSheet(amenity: amenity),
                                ),
                            child: Semantics(
                              button: true,
                              label:
                                  '${amenity.isExample ? 'Fictief voorbeeld, ' : ''}${amenity.name}, ${amenity.category.label}',
                              child: Center(
                                child: Container(
                                  key: ValueKey('amenity-face-${amenity.id}'),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.alphaBlend(
                                      amenityColor(
                                        amenity.category,
                                      ).withValues(alpha: 0.06),
                                      Colors.white,
                                    ),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x20000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    amenity.isExample
                                        ? Icons.science_outlined
                                        : amenityIcon(amenity.category),
                                    color: amenityColor(amenity.category),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
          builder:
              (context, markers) => Semantics(
                label: '${markers.length} voorzieningen',
                button: true,
                child: Center(
                  child: Container(
                    key: const ValueKey('amenity-cluster'),
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: amenityClusterColor(
                          markers.map((marker) => markerColors[marker.key]!),
                        ).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${markers.length}',
                        style: TextStyle(
                          color: amenityClusterColor(
                            markers.map((marker) => markerColors[marker.key]!),
                          ),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ),
      );
    },
  );
}

class AmenityMapControl extends StatelessWidget {
  const AmenityMapControl({
    super.key,
    required this.controller,
    required this.onViewLab,
  });
  final AmenityMapController controller;
  final ValueChanged<LivingLabArea> onViewLab;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder:
        (context, _) => Material(
          color: Colors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(8),
          child: IconButton(
            key: const ValueKey('amenity-filters'),
            tooltip: controller.error ?? 'Voorzieningen en living labs',
            color: _amenityGreen,
            icon: Icon(
              controller.error == null ? Icons.tune : Icons.error_outline,
            ),
            onPressed:
                () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder:
                      (_) => AmenityFilterSheet(
                        controller: controller,
                        onViewLab: onViewLab,
                      ),
                ),
          ),
        ),
  );
}

class AmenityFilterSheet extends StatelessWidget {
  const AmenityFilterSheet({
    super.key,
    required this.controller,
    required this.onViewLab,
  });
  final AmenityMapController controller;
  final ValueChanged<LivingLabArea> onViewLab;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          const _SheetHeading('Voorzieningen'),
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder:
                  (context, _) => ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      for (final lab in controller.labs)
                        ListTile(
                          key: ValueKey('amenity-lab-${lab.id}'),
                          leading: const Icon(
                            Icons.park_outlined,
                            color: _amenityGreen,
                          ),
                          title: Text(lab.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context);
                            onViewLab(lab);
                          },
                        ),
                      const Divider(),
                      if (controller.isLoading) const LinearProgressIndicator(),
                      if (controller.error != null)
                        ListTile(
                          title: Text(controller.error!),
                          trailing: IconButton(
                            tooltip: 'Opnieuw proberen',
                            icon: const Icon(Icons.refresh),
                            onPressed: controller.load,
                          ),
                        ),
                      CheckboxListTile(
                        title: const Text('Alle categorieën'),
                        value:
                            controller.enabledCategories.isEmpty
                                ? false
                                : controller.enabledCategories.length ==
                                    AmenityCategory.values.length
                                ? true
                                : null,
                        tristate: true,
                        activeColor: _amenityGreen,
                        onChanged:
                            (_) => controller.setAllCategories(
                              controller.enabledCategories.length !=
                                  AmenityCategory.values.length,
                            ),
                      ),
                      for (final category in AmenityCategory.values)
                        CheckboxListTile(
                          key: ValueKey('amenity-category-${category.id}'),
                          secondary: Icon(
                            amenityIcon(category),
                            color: amenityColor(category),
                          ),
                          title: Text(category.label),
                          value: controller.enabledCategories.contains(
                            category,
                          ),
                          activeColor: amenityColor(category),
                          onChanged:
                              (value) => controller.setCategory(
                                category,
                                value ?? false,
                              ),
                        ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AmenityDetailSheet extends StatefulWidget {
  const AmenityDetailSheet({super.key, required this.amenity});
  final MapAmenity amenity;

  @override
  State<AmenityDetailSheet> createState() => _AmenityDetailSheetState();
}

class _AmenityDetailSheetState extends State<AmenityDetailSheet> {
  bool _openingMaps = false;
  bool _launchFailed = false;
  MapAmenity get amenity => widget.amenity;

  Future<void> _openGoogleMaps() async {
    if (_openingMaps || amenity.isExample) return;
    setState(() {
      _openingMaps = true;
      _launchFailed = false;
    });
    final destination = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${amenity.latitude},${amenity.longitude}',
      'travelmode': 'walking',
    });
    var opened = false;
    try {
      opened = await launchUrl(
        destination,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Keep the details available so the user can retry a failed handoff.
    }
    if (!mounted) return;
    setState(() {
      _openingMaps = false;
      _launchFailed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  amenityIcon(amenity.category),
                  color: amenityColor(amenity.category),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    amenity.category.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Sluiten',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amenity.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _amenityGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (amenity.isExample) ...[
              const Text(
                'Fictieve voorbeeldlocatie. Dit is geen bevestigde voorziening. '
                'De naam en coordinaten moeten nog door het living lab worden vervangen.',
                style: TextStyle(
                  color: Color(0xFF8A5200),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SelectableText(
              '${amenity.latitude}, ${amenity.longitude}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('open-google-maps'),
                onPressed:
                    _openingMaps || amenity.isExample ? null : _openGoogleMaps,
                style: FilledButton.styleFrom(
                  backgroundColor: _amenityGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon:
                    _openingMaps
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.directions_walk),
                label: const Text(
                  'Open in Google Maps',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (_launchFailed) ...[
              const SizedBox(height: 12),
              Text(
                'Google Maps kon niet worden geopend. Probeer het opnieuw.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SheetHeading extends StatelessWidget {
  const _SheetHeading(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _amenityGreen,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Sluiten',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}
