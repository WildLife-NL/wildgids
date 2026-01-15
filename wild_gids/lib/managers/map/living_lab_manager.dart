import 'package:latlong2/latlong.dart';
import 'package:wildgids/interfaces/location/living_lab_interface.dart';
import 'package:wildgids/models/ui_models/living_lab_area.dart';

class LivingLabManager implements LivingLabInterface {
  final List<LivingLabArea> _livingLabs = [
    LivingLabArea(
      id: "np-zuid-kennemerland",
      name: "Nationaal Park Zuid-Kennemerland",
      center: LatLng(52.4114, 4.5733), // Use this as map center
      areaKm2: 38.0,
      boundary: [
        LatLng(52.4280, 4.5400), // maxLat = 52.4280
        LatLng(52.4200, 4.5800),
        LatLng(52.4100, 4.6000), // maxLng = 4.6000
        LatLng(52.4000, 4.5800),
        LatLng(52.3900, 4.5500), // minLat = 52.3900
        LatLng(52.3980, 4.5200),
        LatLng(52.4100, 4.5100), // minLng = 4.5100
        LatLng(52.4280, 4.5400),
      ],
    ),
    LivingLabArea(
      id: "grenspark-kempenbroek",
      name: "Grenspark Kempen~Broek",
      center: LatLng(51.1950, 5.7230), // Use this as map center
      areaKm2: 250.0,
      boundary: [
        LatLng(51.2200, 5.7000), // maxLat = 51.2200
        LatLng(51.2100, 5.7400), // maxLng = 5.7500
        LatLng(51.1900, 5.7500),
        LatLng(51.1800, 5.7300),
        LatLng(51.1700, 5.6900), // minLat = 51.1700
        LatLng(51.1850, 5.6700), // minLng = 5.6700
        LatLng(51.2000, 5.6800),
        LatLng(51.2200, 5.7000),
      ],
    ),
  ];

  /// Returns all living lab areas
  /// Simply returns the private _livingLabs list without modification
  @override
  List<LivingLabArea> getAllLivingLabs() {
    return _livingLabs;
  }

  /// Finds a living lab by its ID
  /// Uses firstWhere to search through the _livingLabs list
  /// Returns null if no living lab with the given ID is found
  @override
  LivingLabArea? getLivingLabById(String id) {
    try {
      return _livingLabs.firstWhere((lab) => lab.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Finds a living lab that contains the given location
  /// Iterates through all living labs and checks if the location
  /// is inside any of their boundaries using _isPointInPolygon
  /// Returns the first matching living lab or null if none found
  @override
  LivingLabArea? getLivingLabByLocation(LatLng location) {
    for (var lab in _livingLabs) {
      if (_isPointInPolygon(location, lab.boundary)) {
        return lab;
      }
    }
    return null;
  }

  /// Checks if a location is within any living lab area
  /// Uses getLivingLabByLocation and returns true if it finds a match
  @override
  bool isLocationInAnyLivingLab(LatLng location) {
    return getLivingLabByLocation(location) != null;
  }

  /// Determines if a point is inside a polygon using ray casting algorithm
  /// Works by counting how many times a ray from the point crosses the polygon boundary
  /// If the number of crossings is odd, the point is inside; if even, the point is outside
  /// This is a standard algorithm for point-in-polygon testing
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude < point.longitude &&
              polygon[j].longitude >= point.longitude) ||
          (polygon[j].longitude < point.longitude &&
              polygon[i].longitude >= point.longitude)) {
        if (polygon[i].latitude +
                (point.longitude - polygon[i].longitude) /
                    (polygon[j].longitude - polygon[i].longitude) *
                    (polygon[j].latitude - polygon[i].latitude) <
            point.latitude) {
          isInside = !isInside;
        }
      }
      j = i;
    }
    return isInside;
  }
}

