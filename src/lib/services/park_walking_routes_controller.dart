import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wildgids/models/park_walking_route.dart';
import 'package:wildgids/models/park_boundary.dart';
import 'package:wildgids/models/confirmed_trail_entrance.dart';

Future<ParkBoundary> loadZuidKennemerlandBoundary() async => parseParkBoundary(
  await rootBundle.loadString(
    'assets/routes/zuid_kennemerland_boundary.geojson',
  ),
);

Future<List<ParkWalkingRoute>> loadParkWalkingRoutes() async {
  final source = await rootBundle.loadString(
    'assets/routes/park_walking_routes.geojson',
  );
  return compute(parseParkWalkingRoutes, source);
}

Future<List<ConfirmedTrailEntrance>> loadConfirmedTrailEntrances() async =>
    parseConfirmedTrailEntrances(
      await rootBundle.loadString('assets/routes/confirmed_entrances.json'),
    );

class ParkWalkingRoutesController extends ChangeNotifier {
  ParkWalkingRoutesController({
    Future<List<ParkWalkingRoute>> Function()? loader,
    Future<ParkBoundary> Function()? boundaryLoader,
    Future<List<ConfirmedTrailEntrance>> Function()? entranceLoader,
  }) : _loader = loader ?? loadParkWalkingRoutes,
       _boundaryLoader = boundaryLoader ?? loadZuidKennemerlandBoundary,
       _entranceLoader = entranceLoader ?? loadConfirmedTrailEntrances;

  static const zuidKennemerlandId = 'np-zuid-kennemerland';
  String? activeLabId;

  final Future<List<ParkWalkingRoute>> Function() _loader;
  final Future<ParkBoundary> Function() _boundaryLoader;
  final Future<List<ConfirmedTrailEntrance>> Function() _entranceLoader;
  List<ConfirmedTrailEntrance> _entrances = const [];
  bool entrancesLoading = false;
  bool entrancesFailed = false;
  bool _entrancesLoaded = false;
  Future<void>? _pendingEntrances;
  ParkBoundary? boundary;
  bool boundaryEnabled = true;
  bool boundaryLoading = false;
  bool boundaryFailed = false;
  Future<void>? _pendingBoundary;
  List<ParkWalkingRoute> _routes = const [];
  List<ParkWalkingRoute> get routes => _routes;
  ParkWalkingRoute? selected;
  bool enabled = false;
  bool loading = false;
  bool failed = false;
  bool _loaded = false;
  bool _disposed = false;
  Future<void>? _pending;

  List<ParkWalkingRoute> get visibleRoutes =>
      !enabled
          ? const []
          : selected == null
          ? _routes
          : [selected!];

  List<ConfirmedTrailEntrance> entrancesFor(ParkWalkingRoute route) =>
      _entrances
          .where((entry) => entry.routeIds.contains(route.id))
          .toList(growable: false);

  Future<void> selectLivingLab(String id) async {
    if (_disposed) return;
    activeLabId = id;
    final isPark = id == zuidKennemerlandId;
    enabled = isPark;
    boundaryEnabled = isPark;
    selected = null;
    notifyListeners();
    if (isPark) await Future.wait([load(), loadBoundary(), loadEntrances()]);
  }

  Future<void> loadEntrances() {
    if (_disposed || _entrancesLoaded) return Future.value();
    return _pendingEntrances ??= _loadEntrances();
  }

  Future<void> _loadEntrances() async {
    entrancesLoading = true;
    entrancesFailed = false;
    notifyListeners();
    try {
      final entries = await Future.sync(_entranceLoader);
      if (_disposed) return;
      _entrances = List.unmodifiable(entries);
      _entrancesLoaded = true;
    } catch (_) {
      if (!_disposed) entrancesFailed = true;
    } finally {
      _pendingEntrances = null;
      if (!_disposed) {
        entrancesLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> load() {
    if (_loaded || _disposed) return Future.value();
    return _pending ??= _load();
  }

  Future<void> _load() async {
    loading = true;
    failed = false;
    notifyListeners();
    try {
      final routes = await Future.sync(_loader);
      if (_disposed) return;
      _routes = List.unmodifiable(routes);
      _loaded = true;
    } catch (_) {
      if (!_disposed) failed = true;
    } finally {
      _pending = null;
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadBoundary() {
    if (boundary != null || _disposed) return Future.value();
    return _pendingBoundary ??= _loadBoundary();
  }

  Future<void> _loadBoundary() async {
    boundaryLoading = true;
    boundaryFailed = false;
    notifyListeners();
    try {
      final loaded = await Future.sync(_boundaryLoader);
      if (!_disposed) boundary = loaded;
    } catch (_) {
      if (!_disposed) boundaryFailed = true;
    } finally {
      _pendingBoundary = null;
      if (!_disposed) {
        boundaryLoading = false;
        notifyListeners();
      }
    }
  }

  void setBoundaryEnabled(bool value) {
    boundaryEnabled = value;
    notifyListeners();
  }

  void setEnabled(bool value) {
    enabled = value;
    notifyListeners();
  }

  void showRoute(ParkWalkingRoute? route) {
    activeLabId = zuidKennemerlandId;
    selected = route;
    enabled = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
