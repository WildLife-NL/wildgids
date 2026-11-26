import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/models/park_walking_route.dart';
import 'package:wildgids/models/park_boundary.dart';
import 'package:wildgids/services/park_walking_routes_controller.dart';

Color parkRouteColor(String? name) => switch (name?.toLowerCase()) {
  'blauw' => const Color(0xFF1565C0),
  'rood' => const Color(0xFFC62828),
  'groen' => const Color(0xFF25672B),
  'geel' => const Color(0xFFFBC02D),
  'zwart' => const Color(0xFF212121),
  'bruin' => const Color(0xFF795548),
  'paars' => const Color(0xFF7B1FA2),
  'wit' => Colors.white,
  'oranje' => const Color(0xFFEF6C00),
  _ => const Color(0xFF616161),
};

class ZuidKennemerlandBoundaryLayer extends StatelessWidget {
  const ZuidKennemerlandBoundaryLayer({super.key, required this.controller});
  final ParkWalkingRoutesController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder:
        (context, _) => IgnorePointer(
          child: PolylineLayer(
            polylineCulling: true,
            polylines: [
              if (controller.boundaryEnabled && controller.boundary != null)
                for (final ring in controller.boundary!.rings)
                  Polyline(
                    points: ring,
                    color: AppColors.darkGreen,
                    strokeWidth: 3,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.5,
                    isDotted: true,
                  ),
            ],
          ),
        ),
  );
}

class ParkBoundaryLegend extends StatelessWidget {
  const ParkBoundaryLegend({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        ExcludeSemantics(
          child: Icon(Icons.more_horiz, color: AppColors.darkGreen, size: 28),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Parkgrens Zuid-Kennemerland',
            style: TextStyle(
              color: AppColors.darkCharcoal,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

enum _MapSelection { routes, boundary }

/// Culls off-screen lines and never joins independent GeoJSON parts.
class ParkWalkingRoutesLayer extends StatelessWidget {
  const ParkWalkingRoutesLayer({super.key, required this.controller});
  final ParkWalkingRoutesController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder:
        (context, _) => IgnorePointer(
          child: PolylineLayer(
            polylineCulling: true,
            polylines: [
              for (final route in controller.visibleRoutes)
                for (final line in route.displaySegments)
                  Polyline(
                    points: line,
                    color: parkRouteColor(route.colorName),
                    strokeWidth: controller.selected?.id == route.id ? 6 : 3,
                    borderStrokeWidth: 1.5,
                    // A dark edge keeps white/yellow trails visible on pale tiles.
                    borderColor:
                        route.colorName == 'wit' || route.colorName == 'geel'
                            ? AppColors.darkCharcoal
                            : Colors.white,
                  ),
            ],
          ),
        ),
  );
}

class ParkWalkingRoutesButton extends StatelessWidget {
  const ParkWalkingRoutesButton({
    super.key,
    required this.controller,
    required this.onShowRoutes,
    this.onShowBoundary,
    this.onSelectRoute,
    this.showEnabledState = true,
  });
  final ParkWalkingRoutesController controller;
  final ValueChanged<List<ParkWalkingRoute>> onShowRoutes;
  final ValueChanged<ParkBoundary>? onShowBoundary;
  final ValueChanged<ParkWalkingRoute>? onSelectRoute;
  final bool showEnabledState;

  Future<void> _open(BuildContext context) async {
    // Start before building the sheet so a loading state appears immediately.
    controller.load();
    controller.loadBoundary();
    final selection = await showModalBottomSheet<_MapSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.offWhite,
      builder:
          (_) => _RoutesSheet(
            controller: controller,
            canShowBoundary: onShowBoundary != null,
          ),
    );
    if (selection == _MapSelection.routes) {
      final selected = controller.selected;
      onShowRoutes(selected == null ? controller.visibleRoutes : [selected]);
      if (selected != null) onSelectRoute?.call(selected);
    }
    if (selection == _MapSelection.boundary && controller.boundary != null) {
      onShowBoundary?.call(controller.boundary!);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder:
        (context, _) => Semantics(
          toggled: controller.enabled,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.darkCharcoal,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              if (!showEnabledState && controller.selected != null) {
                controller.showRoute(null);
                onShowRoutes(controller.visibleRoutes);
              } else {
                _open(context);
              }
            },
            icon: const ExcludeSemantics(
              child: Icon(Icons.route_outlined, size: 22),
            ),
            label: Text(
              !showEnabledState && controller.selected != null
                  ? 'Alle routes'
                  : showEnabledState && controller.enabled
                  ? 'Wandelroutes aan'
                  : 'Wandelroutes',
            ),
          ),
        ),
  );
}

class _RoutesSheet extends StatefulWidget {
  const _RoutesSheet({required this.controller, required this.canShowBoundary});
  final ParkWalkingRoutesController controller;
  final bool canShowBoundary;

  @override
  State<_RoutesSheet> createState() => _RoutesSheetState();
}

class _RoutesSheetState extends State<_RoutesSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final routes =
          controller.routes.where((route) => route.matches(_query)).toList();
      return DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.darkCharcoal),
        child: Theme(
          // This map surface has its own light palette, including in system dark mode.
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.darkGreen,
              brightness: Brightness.light,
              surface: AppColors.offWhite,
            ),
            textTheme: Theme.of(context).textTheme.apply(
              bodyColor: AppColors.darkCharcoal,
              displayColor: AppColors.darkCharcoal,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.78,
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Wandelroutes',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Sluiten',
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        child: Text(
                          'Zuid-Kennemerland',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SwitchListTile.adaptive(
                        title: const Text('Toon parkgrens'),
                        subtitle: Text(
                          controller.boundaryLoading
                              ? 'Parkgrens laden…'
                              : 'Gestippelde lijn',
                        ),
                        value: controller.boundaryEnabled,
                        onChanged:
                            controller.boundary == null
                                ? null
                                : controller.setBoundaryEnabled,
                      ),
                    ),
                    if (controller.boundaryFailed)
                      SliverToBoxAdapter(
                        child: TextButton(
                          onPressed: controller.loadBoundary,
                          child: const Text('Parkgrens opnieuw laden'),
                        ),
                      ),
                    if (widget.canShowBoundary && controller.boundary != null)
                      SliverToBoxAdapter(
                        child: TextButton.icon(
                          onPressed: () {
                            controller.setBoundaryEnabled(true);
                            Navigator.pop(context, _MapSelection.boundary);
                          },
                          icon: const Icon(Icons.crop_free),
                          label: const Text('Bekijk het park op de kaart'),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SwitchListTile.adaptive(
                        title: const Text('Toon wandelroutes'),
                        subtitle: Text(
                          controller.selected?.name ??
                              'Alle aangeleverde routes en paden',
                        ),
                        value: controller.enabled,
                        onChanged:
                            controller.loading ||
                                    controller.failed ||
                                    controller.routes.isEmpty
                                ? null
                                : controller.setEnabled,
                      ),
                    ),
                    if (controller.loading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              semanticsLabel: 'Routes laden',
                            ),
                          ),
                        ),
                      )
                    else if (controller.failed)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'De wandelroutes konden niet worden geladen.',
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: controller.load,
                                child: const Text('Opnieuw proberen'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (controller.routes.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Geen wandelroutes beschikbaar.'),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Zoek op route of ingang',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged:
                                    (value) => setState(() => _query = value),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  controller.showRoute(null);
                                  Navigator.pop(context, _MapSelection.routes);
                                },
                                icon: const Icon(Icons.map_outlined),
                                label: Text(
                                  'Bekijk alle ${controller.routes.length} routes en paden',
                                ),
                              ),
                              const Text(
                                'Kies een route om deze op de kaart te bekijken.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (routes.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Geen routes gevonden.'),
                          ),
                        ),
                      SliverList.builder(
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: ExcludeSemantics(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: parkRouteColor(route.colorName),
                                  border: Border.all(color: AppColors.darkGrey),
                                ),
                              ),
                            ),
                            title: Text(route.name),
                            subtitle: Text(
                              [
                                'Circa ${route.distanceLabel}',
                                if (route.entrance != null)
                                  'Ingang: ${route.entrance}',
                                if (route.colorName != null)
                                  'Markering: ${route.colorName}',
                                if (route.operatorName != null)
                                  'Beheerder: ${route.operatorName}',
                              ].join(' · '),
                            ),
                            selected: controller.selected?.id == route.id,
                            trailing: Icon(
                              controller.selected?.id == route.id
                                  ? Icons.check
                                  : Icons.chevron_right,
                            ),
                            onTap: () {
                              controller.showRoute(route);
                              Navigator.pop(context, _MapSelection.routes);
                            },
                          );
                        },
                      ),
                    ],
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Bron: aangeleverde wandelpaden · parkgrens: PDOK/RVO. '
                          'Trajecten kunnen buiten de parkgrens lopen; '
                          'niet alle paden hebben een naam.',
                          style: TextStyle(fontSize: 13, height: 1.4),
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
    },
  );
}
