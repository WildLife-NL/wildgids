import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/walk_recording.dart';
import 'package:wildgids/providers/walk_recorder.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/screens/waarneming/walk_sighting_flow.dart';
import 'package:wildgids/widgets/map/carto_attribution.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/utils/species_icon_utils.dart';

const _walkGreen = Color(0xFF00634D);

String walkDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return duration.inHours == 0
      ? '$minutes:$seconds'
      : '$hours:$minutes:$seconds';
}

String walkDistance(WalkRecording walk) =>
    '${(walk.distanceMeters / 1000).toStringAsFixed(2).replaceAll('.', ',')} km';

String walkPace(WalkRecording walk) {
  final pace = walk.averagePace;
  if (pace == null) return '—';
  return '${pace.inMinutes}:${(pace.inSeconds % 60).toString().padLeft(2, '0')} min/km';
}

/// The live values and the final summary share labels and number hierarchy.
class WalkStats extends StatelessWidget {
  const WalkStats({
    super.key,
    required this.walk,
    required this.elapsed,
    this.summary = false,
  });
  final WalkRecording walk;
  final Duration elapsed;
  final bool summary;

  @override
  Widget build(BuildContext context) {
    final singleColumn = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final metrics = <(String, String)>[
      ('Tijd', walkDuration(elapsed)),
      ('Afstand', walkDistance(walk)),
      if (summary) ...[
        ('Gemiddeld tempo', walkPace(walk)),
        ('Waarnemingen', '${walk.sightings.length}'),
      ],
    ];
    final items = [
      for (final (label, value) in metrics)
        Semantics(
          label: '$label: $value',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: GuideStyle.muted, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: GuideStyle.ink,
                  fontSize: summary ? 21 : 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (singleColumn)
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            items[i],
          ]
        else
          for (var i = 0; i < items.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: items[i]),
                const SizedBox(width: 12),
                Expanded(child: items[i + 1]),
              ],
            ),
          ],
      ],
    );
  }
}

class ActiveWalkMapLayer extends StatelessWidget {
  const ActiveWalkMapLayer({
    super.key,
    this.showRoute = true,
    this.showMarkers = true,
  });
  final bool showRoute;
  final bool showMarkers;
  @override
  Widget build(BuildContext context) => Selector<WalkRecorder, WalkRecording?>(
    selector: (_, recorder) => recorder.current,
    builder:
        (_, walk, _) =>
            walk == null
                ? const SizedBox.shrink()
                : WalkMapLayer(
                  walk: walk,
                  showRoute: showRoute,
                  showMarkers: showMarkers,
                ),
  );
}

class WalkMapLayer extends StatelessWidget {
  const WalkMapLayer({
    super.key,
    required this.walk,
    this.showRoute = true,
    this.showMarkers = true,
  });
  final WalkRecording walk;
  final bool showRoute;
  final bool showMarkers;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (showRoute)
        PolylineLayer(
          polylines: [
            for (final segment in walk.segments)
              if (segment.length > 1)
                Polyline(
                  points: segment,
                  strokeWidth: 5,
                  color: _walkGreen,
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                ),
          ],
        ),
      if (showMarkers)
        MarkerLayer(
          markers: [
            if (walk.points.isNotEmpty) ...[
              Marker(
                point: walk.points.first.latLng,
                width: 32,
                height: 32,
                child: const Tooltip(
                  message: 'Start wandeling',
                  child: CircleAvatar(
                    backgroundColor: _walkGreen,
                    child: Icon(Icons.flag, size: 18, color: Colors.white),
                  ),
                ),
              ),
              Marker(
                point: walk.points.last.latLng,
                width: 22,
                height: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _walkGreen,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
            for (final sighting in walk.sightings)
              Marker(
                point: sighting.point.latLng,
                width: 56,
                height: 56,
                rotate: true,
                child: Tooltip(
                  message: sighting.name,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(
                        side: BorderSide(color: Color(0xFF8613A8), width: 3),
                      ),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: _WalkAnimalSilhouette(name: sighting.name),
                          ),
                        ),
                        onTap:
                            () => showModalBottomSheet<void>(
                              context: context,
                              builder:
                                  (_) => SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: ListTile(
                                        leading: SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: _WalkAnimalImage(
                                            name: sighting.name,
                                          ),
                                        ),
                                        title: Text(sighting.name),
                                        subtitle: Text(
                                          DateFormat('dd-MM-yyyy HH:mm').format(
                                            sighting.point.time.toLocal(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
    ],
  );
}

class _WalkAnimalSilhouette extends StatelessWidget {
  const _WalkAnimalSilhouette({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final path = getSpeciesIconPath(name);
    const fallback = Icon(Icons.pets, color: Colors.black, size: 32);
    if (path == null) return fallback;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        semanticLabel: name,
        cacheWidth: 96,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _WalkAnimalImage extends StatelessWidget {
  const _WalkAnimalImage({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final path = SpeciesImageResolver.drawingForCommonName(name);
    const fallback = Icon(Icons.pets_outlined, color: GuideStyle.ink, size: 32);
    if (path == null) return fallback;
    return ClipOval(
      child: Transform.scale(
        scale: 1.25,
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          semanticLabel: name,
          cacheWidth: 192,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}

class WalkControls extends StatefulWidget {
  const WalkControls({super.key, required this.onStarted});
  final VoidCallback onStarted;
  @override
  State<WalkControls> createState() => _WalkControlsState();
}

class _WalkControlsState extends State<WalkControls> {
  bool _starting = false;
  bool _reporting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalkRecorder>().initialize();
    });
  }

  Future<void> _start(WalkRecorder recorder) async {
    if (_starting) return;
    setState(() => _starting = true);
    if (recorder.current == null) {
      final consent = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              scrollable: true,
              title: const Text('Wandeling opnemen?'),
              content: const Text(
                'WildGids neemt je route op, ook met een vergrendeld scherm. Je wandeling wordt alleen op deze telefoon bewaard. '
                'Pauzeer of stop om de opname te onderbreken. Als je de app volledig afsluit, stopt de opname. '
                'De bestaande locatiedeling van WildGids blijft ongewijzigd.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuleren'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Start wandeling'),
                ),
              ],
            ),
      );
      if (consent != true || !mounted) {
        if (mounted) setState(() => _starting = false);
        return;
      }
    }
    await recorder.start();
    if (!mounted) return;
    setState(() => _starting = false);
    if (recorder.recording) widget.onStarted();
  }

  Future<void> _stop(WalkRecorder recorder) async {
    await recorder.pause();
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            scrollable: true,
            title: const Text('Wandeling afronden'),
            content: SizedBox(
              width: 340,
              child: WalkStats(
                walk: recorder.current!,
                elapsed: recorder.elapsed,
                summary: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Terug'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'discard'),
                child: const Text('Verwijderen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'save'),
                child: const Text('Bewaren'),
              ),
            ],
          ),
    );
    if (choice != null) await recorder.finish(save: choice == 'save');
  }

  Future<void> _report(WalkRecorder recorder) async {
    final walk = recorder.current;
    if (walk == null || _reporting) return;
    setState(() => _reporting = true);
    final moment = DateTime.now();
    final captured = recorder.sightingPosition;
    context.read<AnimalSightingReportingInterface>().createanimalSighting();
    context.read<AppStateProvider>().initializeReport(ReportType.waarneming);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => WalkSightingFlow(
              walkId: walk.id,
              position: captured,
              startedAt: moment,
            ),
      ),
    );
    if (mounted) setState(() => _reporting = false);
  }

  Widget _walkActions(WalkRecorder recorder) => LayoutBuilder(
    builder: (context, constraints) {
      final style = OutlinedButton.styleFrom(
        foregroundColor: GuideStyle.ink,
        backgroundColor: GuideStyle.background,
        side: const BorderSide(color: GuideStyle.border),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      );
      final pause = OutlinedButton.icon(
        key: const ValueKey('pause-walk'),
        style: style,
        onPressed:
            recorder.busy || _starting
                ? null
                : () =>
                    recorder.recording ? recorder.pause() : _start(recorder),
        icon: Icon(
          recorder.recording ? Icons.pause : Icons.play_arrow,
          size: 20,
        ),
        label: Text(
          recorder.recording ? 'Pauzeren' : 'Hervatten',
          textAlign: TextAlign.center,
        ),
      );
      final finish = OutlinedButton.icon(
        key: const ValueKey('stop-walk'),
        style: style,
        onPressed: recorder.busy ? null : () => _stop(recorder),
        icon: const Icon(Icons.stop_outlined, size: 20),
        label: const Text('Afronden', textAlign: TextAlign.center),
      );
      if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [pause, const SizedBox(height: 8), finish],
        );
      }
      return Row(
        children: [
          Expanded(child: pause),
          const SizedBox(width: 8),
          Expanded(child: finish),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) => Consumer<WalkRecorder>(
    builder: (context, recorder, _) {
      final walk = recorder.current;
      return Material(
        color: GuideStyle.background,
        child: SafeArea(
          top: false,
          bottom: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (recorder.error != null) ...[
                    Text(
                      recorder.error!,
                      style: const TextStyle(color: Color(0xFF9B331C)),
                    ),
                    if (recorder.needsLocationSettings)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: Geolocator.openAppSettings,
                          child: const Text('Instellingen'),
                        ),
                      ),
                  ],
                  if (walk == null)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey('start-walk'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _walkGreen,
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed:
                                recorder.busy || _starting
                                    ? null
                                    : () => _start(recorder),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start wandeling'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Mijn wandelingen',
                          icon: const Icon(Icons.history),
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const WalkHistoryScreen(),
                                ),
                              ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GuideStyle.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GuideStyle.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                recorder.recording
                                    ? Icons.fiber_manual_record
                                    : Icons.pause_circle_outline,
                                color: GuideStyle.ink,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  recorder.recording
                                      ? 'Wandeling bezig'
                                      : 'Gepauzeerd',
                                  style: const TextStyle(
                                    color: GuideStyle.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          WalkStats(walk: walk, elapsed: recorder.elapsed),
                          if (recorder.gpsMessage != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_searching,
                                  size: 18,
                                  color: GuideStyle.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recorder.gpsMessage!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: GuideStyle.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: const ValueKey('walk-sighting'),
                            style: FilledButton.styleFrom(
                              backgroundColor: GuideStyle.ink,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onPressed:
                                _reporting || recorder.busy
                                    ? null
                                    : () => _report(recorder),
                            icon: const Icon(
                              Icons.add_location_alt_outlined,
                              size: 20,
                            ),
                            label: const Text(
                              'Waarneming melden',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _walkActions(recorder),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class WalkHistoryScreen extends StatelessWidget {
  const WalkHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final recorder = context.watch<WalkRecorder>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mijn wandelingen')),
      body:
          recorder.saved.isEmpty
              ? const Center(child: Text('Nog geen opgeslagen wandelingen'))
              : ListView.separated(
                itemCount: recorder.saved.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final walk = recorder.saved[index];
                  return ListTile(
                    leading: const Icon(Icons.route, color: _walkGreen),
                    title: Text(
                      DateFormat(
                        'dd-MM-yyyy HH:mm',
                      ).format(walk.startedAt.toLocal()),
                    ),
                    subtitle: Text(
                      '${walkDistance(walk)} · ${walkDuration(Duration(milliseconds: walk.activeMilliseconds))}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SavedWalkScreen(walk: walk),
                          ),
                        ),
                  );
                },
              ),
    );
  }
}

class SavedWalkScreen extends StatelessWidget {
  const SavedWalkScreen({super.key, required this.walk});
  final WalkRecording walk;
  @override
  Widget build(BuildContext context) {
    final mapPoints = [
      ...walk.points.map((point) => point.latLng),
      ...walk.sightings.map((sighting) => sighting.point.latLng),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wandeling'),
        actions: [
          IconButton(
            tooltip: 'Wandeling verwijderen',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final recorder = context.read<WalkRecorder>();
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      scrollable: true,
                      title: const Text('Wandeling verwijderen?'),
                      content: const Text(
                        'Deze route wordt van deze telefoon verwijderd.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuleren'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Verwijderen'),
                        ),
                      ],
                    ),
              );
              if (confirm != true) return;
              await recorder.deleteSaved(walk.id);
              if (!context.mounted) return;
              if (!recorder.saved.any((saved) => saved.id == walk.id)) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verwijderen mislukt. Probeer opnieuw.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: WalkStats(
                  walk: walk,
                  elapsed: Duration(milliseconds: walk.activeMilliseconds),
                  summary: true,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                mapPoints.isEmpty
                    ? const Center(child: Text('Geen GPS-punten opgenomen'))
                    : FlutterMap(
                      options: MapOptions(
                        initialCenter: mapPoints.first,
                        initialZoom: 16,
                        initialCameraFit:
                            mapPoints.length > 1
                                ? CameraFit.bounds(
                                  bounds: LatLngBounds.fromPoints(mapPoints),
                                  padding: const EdgeInsets.all(40),
                                  maxZoom: 17,
                                )
                                : null,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: LocationMapManager.standardTileUrl,
                          subdomains: LocationMapManager.standardTileSubdomains,
                          tileProvider: NetworkTileProvider(
                            headers: LocationMapManager.standardTileHeaders,
                          ),
                          userAgentPackageName: 'com.wildlife.wildgids',
                        ),
                        WalkMapLayer(walk: walk),
                        const CartoAttribution(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
