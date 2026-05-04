import 'package:geolocator/geolocator.dart';

abstract class LocationServiceInterface {
  Future<Position?> determinePosition();
  Future<String> getAddressFromPosition(Position position); // renamed here
  bool isLocationInNetherlands(double lat, double lon);
}
