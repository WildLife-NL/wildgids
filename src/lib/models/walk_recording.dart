import 'package:latlong2/latlong.dart';

class WalkPoint {
  const WalkPoint(
    this.latitude,
    this.longitude,
    this.time, {
    this.newSegment = false,
  });
  final double latitude;
  final double longitude;
  final DateTime time;
  final bool newSegment;
  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'time': time.toUtc().toIso8601String(),
    'newSegment': newSegment,
  };

  factory WalkPoint.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num).toDouble();
    final lon = (json['longitude'] as num).toDouble();
    if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180) {
      throw const FormatException('Invalid walk coordinate');
    }
    return WalkPoint(
      lat,
      lon,
      DateTime.parse(json['time'] as String),
      newSegment: json['newSegment'] as bool? ?? false,
    );
  }
}

class WalkSighting {
  const WalkSighting({
    required this.id,
    required this.name,
    required this.point,
  });
  final String id;
  final String name;
  final WalkPoint point;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'point': point.toJson(),
  };
  factory WalkSighting.fromJson(Map<String, dynamic> json) => WalkSighting(
    id: json['id'] as String,
    name: json['name'] as String,
    point: WalkPoint.fromJson(json['point'] as Map<String, dynamic>),
  );
}

class WalkRecording {
  WalkRecording({
    required this.id,
    required this.startedAt,
    this.updatedAt,
    this.finishedAt,
    this.activeMilliseconds = 0,
    List<WalkPoint> points = const [],
    List<WalkSighting> sightings = const [],
  }) : points = List.unmodifiable(points),
       sightings = List.unmodifiable(sightings);
  final String id;
  final DateTime startedAt;
  final DateTime? updatedAt;
  final DateTime? finishedAt;
  final int activeMilliseconds;
  final List<WalkPoint> points;
  final List<WalkSighting> sightings;

  List<List<LatLng>> get segments {
    final result = <List<LatLng>>[];
    for (final point in points) {
      if (result.isEmpty || point.newSegment) result.add([]);
      result.last.add(point.latLng);
    }
    return result;
  }

  double get distanceMeters {
    double distance = 0;
    for (var i = 1; i < points.length; i++) {
      if (!points[i].newSegment) {
        distance += const Distance().as(
          LengthUnit.Meter,
          points[i - 1].latLng,
          points[i].latLng,
        );
      }
    }
    return distance;
  }

  /// Average recorded pace, excluding time spent paused. Short traces are too
  /// sensitive to GPS noise to present a useful pace.
  Duration? get averagePace {
    final meters = distanceMeters;
    if (meters < 100 || activeMilliseconds <= 0) return null;
    return Duration(
      seconds: (activeMilliseconds / 1000 / (meters / 1000)).round(),
    );
  }

  WalkRecording copyWith({
    DateTime? updatedAt,
    DateTime? finishedAt,
    int? activeMilliseconds,
    List<WalkPoint>? points,
    List<WalkSighting>? sightings,
  }) => WalkRecording(
    id: id,
    startedAt: startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    activeMilliseconds: activeMilliseconds ?? this.activeMilliseconds,
    points: points ?? this.points,
    sightings: sightings ?? this.sightings,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'activeMilliseconds': activeMilliseconds,
    'points': points.map((p) => p.toJson()).toList(),
    'sightings': sightings.map((s) => s.toJson()).toList(),
  };

  factory WalkRecording.fromJson(Map<String, dynamic> json) {
    final elapsed = json['activeMilliseconds'] as int;
    if (elapsed < 0) throw const FormatException('Invalid walk duration');
    final points =
        (json['points'] as List)
            .map((p) => WalkPoint.fromJson(p as Map<String, dynamic>))
            .toList();
    for (var i = 1; i < points.length; i++) {
      if (!points[i].time.isAfter(points[i - 1].time)) {
        throw const FormatException('Unordered walk points');
      }
    }
    return WalkRecording(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      updatedAt:
          json['updatedAt'] == null
              ? null
              : DateTime.parse(json['updatedAt'] as String),
      finishedAt:
          json['finishedAt'] == null
              ? null
              : DateTime.parse(json['finishedAt'] as String),
      activeMilliseconds: elapsed,
      points: points,
      sightings:
          (json['sightings'] as List)
              .map((s) => WalkSighting.fromJson(s as Map<String, dynamic>))
              .toList(),
    );
  }
}
