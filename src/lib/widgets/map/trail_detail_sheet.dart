import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wildgids/models/confirmed_trail_entrance.dart';
import 'package:wildgids/models/park_walking_route.dart';
import 'package:wildgids/services/park_walking_routes_controller.dart';
import 'package:wildgids/utils/trail_geometry.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';

class TrailDetailSheet extends StatefulWidget {
  const TrailDetailSheet({
    super.key,
    required this.route,
    required this.controller,
    required this.userLocation,
    required this.onClose,
    this.locationIsOld = false,
    this.scrollController,
    this.onStartWalk,
    this.walkActionLabel = 'Start wandeling',
    this.walkRecording = false,
    this.walkBusy = false,
    this.walkError,
    this.launchDirections,
  });

  final ParkWalkingRoute route;
  final ParkWalkingRoutesController controller;
  final LatLng? userLocation;
  final bool locationIsOld;
  final ScrollController? scrollController;
  final VoidCallback onClose;
  final Future<bool> Function()? onStartWalk;
  final String walkActionLabel;
  final bool walkRecording;
  final bool walkBusy;
  final String? walkError;
  final Future<bool> Function(Uri)? launchDirections;

  @override
  State<TrailDetailSheet> createState() => _TrailDetailSheetState();
}

class _TrailDetailSheetState extends State<TrailDetailSheet> {
  String? _entranceId;
  bool _opening = false;
  bool _starting = false;
  String? _error;
  LatLng? _distanceLocation;
  ParkWalkingRoute? _distanceRoute;
  double? _cachedDistance;

  Future<void> _directions(ConfirmedTrailEntrance entrance) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final launched =
          await (widget.launchDirections?.call(entrance.directions) ??
              launchUrl(
                entrance.directions,
                mode: LaunchMode.externalApplication,
              ));
      if (!launched && mounted) {
        setState(
          () =>
              _error = 'Google Maps kon niet worden geopend. Probeer opnieuw.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Google Maps kon niet worden geopend. Probeer opnieuw.',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _start() async {
    if (_starting || widget.onStartWalk == null) return;
    setState(() => _starting = true);
    try {
      final started = await widget.onStartWalk!();
      if (started && mounted) widget.onClose();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final route = widget.route;
      final location = widget.userLocation;
      if (location != _distanceLocation || !identical(route, _distanceRoute)) {
        _distanceLocation = location;
        _distanceRoute = route;
        _cachedDistance =
            location == null ? null : distanceToTrailMeters(location, route);
      }
      final distance = _cachedDistance;
      final entrances = widget.controller.entrancesFor(route).toList();
      if (location != null) {
        const measure = Distance(roundResult: false);
        entrances.sort(
          (a, b) =>
              measure(location, a.point).compareTo(measure(location, b.point)),
        );
      }
      final entrance =
          entrances.isEmpty
              ? null
              : entrances.firstWhere(
                (entry) => entry.id == _entranceId,
                orElse: () => entrances.first,
              );
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: GuideStyle.ink,
            brightness: Brightness.light,
            surface: GuideStyle.background,
          ),
          textTheme: theme.textTheme.apply(
            bodyColor: GuideStyle.ink,
            displayColor: GuideStyle.ink,
          ),
        ),
        child: Material(
          color: GuideStyle.background,
          child: SafeArea(
            top: false,
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Wandelroute',
                        style: TextStyle(color: GuideStyle.muted),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sluiten',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  route.name,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: GuideStyle.ink,
                  ),
                ),
                const SizedBox(height: 8),
                if (route.colorName != null)
                  Text(
                    'Markering: ${route.colorName}',
                    style: const TextStyle(color: GuideStyle.muted),
                  ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: GuideStyle.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lengte: circa ${route.distanceLabel}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          distance == null
                              ? 'Afstand tot route: locatie niet beschikbaar'
                              : 'Tot route: circa ${trailDistanceLabel(distance)}',
                          key: const ValueKey('trail-user-distance'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (location != null)
                          Text(
                            widget.locationIsOld
                                ? 'Hemelsbreed vanaf je laatste GPS-locatie'
                                : 'Hemelsbreed vanaf je GPS-locatie',
                            style: const TextStyle(
                              color: GuideStyle.muted,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.controller.entrancesLoading)
                  const Text('Ingangen laden…')
                else if (entrance == null) ...[
                  const Text(
                    'Geen bevestigde ingang beschikbaar.',
                    style: TextStyle(color: GuideStyle.muted),
                  ),
                  if (widget.controller.entrancesFailed)
                    TextButton(
                      onPressed: widget.controller.loadEntrances,
                      child: const Text('Ingangen opnieuw laden'),
                    ),
                ] else ...[
                  if (entrances.length > 1)
                    DropdownButtonFormField<String>(
                      key: const ValueKey('trail-entrance-choice'),
                      initialValue: entrance.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ingang',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          entrances
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.id,
                                  child: Text(
                                    entry.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (id) => setState(() => _entranceId = id),
                    )
                  else
                    Text(
                      'Ingang: ${entrance.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ingang vermeld op de parkkaart',
                    style: TextStyle(color: GuideStyle.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  key: const ValueKey('trail-directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GuideStyle.ink,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed:
                      entrance == null || _opening
                          ? null
                          : () => _directions(entrance),
                  icon:
                      _opening
                          ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.directions_walk),
                  label: const Text(
                    'Naar ingang · Google Maps',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, semanticsLabel: _error),
                  ),
                if (widget.onStartWalk != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('trail-start-walk'),
                    style: GuideStyle.primaryButton,
                    onPressed:
                        widget.walkRecording || widget.walkBusy || _starting
                            ? null
                            : _start,
                    icon:
                        _starting
                            ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.hiking),
                    label: Text(
                      widget.walkRecording
                          ? 'Wandeling wordt opgenomen'
                          : widget.walkActionLabel,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.walkError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.walkError!,
                        style: const TextStyle(color: GuideStyle.muted),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
