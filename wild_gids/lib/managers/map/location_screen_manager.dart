import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/interfaces/location/location_screen_interface.dart';
import 'package:wildgids/interfaces/map/location_service_interface.dart';
import 'package:wildgids/managers/map/location_map_manager.dart';
import 'package:wildgids/models/enums/location_type.dart';
import 'package:wildgids/models/enums/date_time_type.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/providers/map_provider.dart';
import 'package:wildgids/providers/app_state_provider.dart';

class LocationScreenManager implements LocationScreenInterface {
  final bool _isLocationDropdownExpanded = false;
  final bool _isDateTimeDropdownExpanded = false;
  // Default to picking on map; only use current location if user selects it
  final String _selectedLocation = LocationType.custom.displayText;
  String _selectedDateTime = DateTimeType.current.displayText;
  final String _currentLocationText = 'Huidige locatie wordt geladen...';
  DateTime? _customDateTime;

  @override
  bool get isLocationDropdownExpanded => _isLocationDropdownExpanded;

  @override
  bool get isDateTimeDropdownExpanded => _isDateTimeDropdownExpanded;

  @override
  String get selectedLocation => _selectedLocation;

  @override
  String get selectedDateTime => _selectedDateTime;

  @override
  String get currentLocationText => _currentLocationText;

  @override
  DateTime? get customDateTime => _customDateTime;

  @override
  Future<void> handleNextPressed(BuildContext context) async {
    await getLocationAndDateTime(context);
  }

  @override
  Future<Map<String, dynamic>> getLocationAndDateTime(
    BuildContext context,
  ) async {
    final mapProvider = context.read<MapProvider>();
    final appState = context.read<AppStateProvider>();
    final LocationServiceInterface locationService = LocationMapManager();

    Position? currentPosition;
    Map<String, dynamic>? currentGpsLocation;

    final wantsCurrent = _selectedLocation == LocationType.current.displayText;
    if (wantsCurrent) {
      // Only touch GPS when the user explicitly chose current location
      if (appState.isLocationCacheValid) {
        currentPosition = appState.cachedPosition;
        currentGpsLocation = currentPosition != null
            ? {
                'latitude': currentPosition.latitude,
                'longitude': currentPosition.longitude,
                'address': appState.cachedAddress,
              }
            : null;
      } else {
        currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        ).catchError((error) {
          throw error;
        });

        final address = await locationService.getAddressFromPosition(
          currentPosition,
        );
        currentGpsLocation = {
          'latitude': currentPosition.latitude,
          'longitude': currentPosition.longitude,
          'address': address,
        };

        // Update cache in background (avoid direct calls not to block process)
        appState.updateLocationCache();
      }
    }

    // Get user selected location
    final selectedLocation =
        mapProvider.selectedPosition != null
            ? {
              'latitude': mapProvider.selectedPosition!.latitude,
              'longitude': mapProvider.selectedPosition!.longitude,
              'address': mapProvider.selectedAddress,
            }
            : null;

    // Getting date time information
    final dateTimeInfo = {
      'dateTime': _selectedDateTime == DateTimeType.current.displayText
        ? DateTime.now().toIso8601String()
        : _customDateTime?.toIso8601String(),
      'type': _selectedDateTime == DateTimeType.current.displayText
        ? 'current'
        : 'custom',
    };

    final result = {
      'currentGpsLocation': currentGpsLocation,
      'selectedLocation': selectedLocation,
      'dateTime': dateTimeInfo,
      'isLocationUnknown':
          selectedLocation == null || mapProvider.selectedAddress.isEmpty,
      'isDateTimeUnknown': false,
    };

    return result;
  }

  Future<void> printLocationAndDateTime(BuildContext context) async {
    await getLocationAndDateTime(context);
  }

  void updateDateTime(String option, {DateTime? date, DateTime? time}) {
    _selectedDateTime = option;

    if (option == DateTimeType.current.displayText) {
      _customDateTime = null;
    } else if (date != null || time != null) {
      // This combines the date and time if both are provided
      final currentCustom = _customDateTime ?? DateTime.now();
      if (date != null && time != null) {
        _customDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      } else if (date != null) {
        _customDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          currentCustom.hour,
          currentCustom.minute,
        );
      } else if (time != null) {
        _customDateTime = DateTime(
          currentCustom.year,
          currentCustom.month,
          currentCustom.day,
          time.hour,
          time.minute,
        );
      }
    }
  }
}

