import 'package:latlong2/latlong.dart';

abstract class MapServiceInterface {
  LatLng constrainLatLng(LatLng point);
  Future<String> getAddressFromLatLng(LatLng point);
  bool isLocationInNetherlands(double lat, double lon);
}
