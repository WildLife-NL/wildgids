import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/models/beta_models/polygon_area_model.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/providers/belonging_damage_report_provider.dart';
import 'package:wildgids/constants/app_colors.dart';
// Draggable plugin removed due to dependency issues; implementing tap-to-move editing instead.
import 'package:wildgids/widgets/shared_ui_widgets/app_bar.dart';
import 'package:intl/intl.dart';

class AreaSelectionMap extends StatefulWidget {
  final Function(PolygonArea) onAreaSelected;
  final LatLng? initialCenter;
  final PolygonArea? existingArea;

  const AreaSelectionMap({
    super.key,
    required this.onAreaSelected,
    this.initialCenter,
    this.existingArea,
  });

  @override
  State<AreaSelectionMap> createState() => _AreaSelectionMapState();
}

class _AreaSelectionMapState extends State<AreaSelectionMap> {
  late fm.MapController _mapController;
  List<LatLng> _polygonPoints = [];
  bool _isDrawing = false;
  bool _isGpsRecording = false;
  List<LatLng> _gpsTrack = [];
  final List<LatLng> _recentPositions = [];
  final int _smoothingWindow = 5;
  final double _accuracyThresholdM =
      10; // only accept points with <= 10m accuracy
  final double _minPointDistanceM = 2; // ignore tiny jitter
  late LatLng _centerPoint;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _liveLocationSub;
  double? _unitPricePerM2;
  int? _selectedPointIndex;
  bool _editPinsMode = false;

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();

    if (widget.existingArea != null) {
      _polygonPoints = widget.existingArea!.points;
    }

    _centerPoint = widget.initialCenter ?? const LatLng(51.7, 5.27);
    _loadCurrentLocation();
    _startLiveLocationUpdates();
  }

  @override
  void dispose() {
    _liveLocationSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    // If editing pins, move the selected pin to tap location
    if (_editPinsMode && _selectedPointIndex != null) {
      setState(() {
        _polygonPoints[_selectedPointIndex!] = point;
      });
      return;
    }

    if (!_isDrawing || _isGpsRecording) return;

    setState(() {
      _polygonPoints.add(point);
    });
  }

  void _startDrawing() {
    setState(() {
      _isDrawing = !_isDrawing;
      if (!_isDrawing) {
        _gpsTrack.clear();
      }
    });
  }

  void _startGpsRecording() async {
    if (_isGpsRecording) {
      // Stop recording
      setState(() {
        _isGpsRecording = false;
      });
      if (_gpsTrack.length >= 3) {
        widget.onAreaSelected(
          PolygonArea(points: _gpsTrack, areaType: 'gps_recording'),
        );
      }
      return;
    }

    // Start recording
    setState(() {
      _isGpsRecording = true;
      _gpsTrack.clear();
      _polygonPoints.clear();
    });

    try {
      final positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1, // Update roughly every 1 meter
        ),
      );

      positionStream.listen((Position position) {
        if (!_isGpsRecording) return;
        // Accuracy filter
        if (position.accuracy > _accuracyThresholdM) return;

        final newPoint = LatLng(position.latitude, position.longitude);
        // Distance filter (to last accepted point)
        if (_gpsTrack.isNotEmpty) {
          final last = _gpsTrack.last;
          final meters = const Distance().distance(last, newPoint);
          if (meters < _minPointDistanceM) return;
        }

        // Smoothing: maintain recent positions and add averaged point
        _recentPositions.add(newPoint);
        if (_recentPositions.length > _smoothingWindow) {
          _recentPositions.removeAt(0);
        }
        final averaged = _averageLatLng(_recentPositions);

        setState(() {
          _gpsTrack.add(averaged);
          _polygonPoints = List.from(_gpsTrack);
        });
      });
    } catch (e) {
      debugPrint('GPS recording error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('GPS-fout: $e')));
      setState(() {
        _isGpsRecording = false;
      });
    }
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
      });
    }
  }

  void _clearArea() {
    setState(() {
      _polygonPoints.clear();
      _gpsTrack.clear();
      _isDrawing = false;
      _isGpsRecording = false;
      _selectedPointIndex = null;
      _editPinsMode = false;
    });
  }

  void _completeArea() {
    if (_polygonPoints.length >= 3) {
      widget.onAreaSelected(
        PolygonArea(
          points: _polygonPoints,
          areaType: _isGpsRecording ? 'gps_recording' : 'polygon',
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teken minimaal 3 punten om een gebied te maken'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final here = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _currentLocation = here;
        if (widget.initialCenter == null) {
          _centerPoint = here;
        }
      });
      // Move map to current location if no explicit initial center provided
      if (widget.initialCenter == null) {
        _mapController.move(here, 16);
      }
    } catch (e) {
      debugPrint('Current location error: $e');
    }
  }

  Future<void> _startLiveLocationUpdates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _liveLocationSub?.cancel();
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1,
        ),
      );
      _liveLocationSub = stream.listen((pos) {
        // Ignore low-accuracy points (> threshold)
        if (pos.accuracy > _accuracyThresholdM) {
          return;
        }
        final here = LatLng(pos.latitude, pos.longitude);
        if (!mounted) return;
        setState(() {
          _currentLocation = here;
        });
      });
    } catch (e) {
      debugPrint('Live location stream error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final areaFmt = NumberFormat('#,##0', 'nl_NL');
    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: CustomAppBar(
              leftIcon: Icons.arrow_back_ios,
              centerText: 'Selecteer beschadigd gebied',
              rightIcon: null,
              showUserIcon: true,
              onLeftIconPressed: () {
                Navigator.of(context).pop();
              },
              iconColor: Colors.white,
              textColor: Colors.white,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
              useFixedText: true,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Map
                fm.FlutterMap(
                  mapController: _mapController,
                  options: fm.MapOptions(
                    initialCenter: _centerPoint,
                    initialZoom: 16,
                    onTap: (tapPosition, point) => _onMapTap(point),
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wildgids.app',
                    ),
                    // Current location marker
                    if (_currentLocation != null)
                      fm.MarkerLayer(
                        markers: [
                          fm.Marker(
                            point: _currentLocation!,
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Optional accuracy circle around current location
                    if (_currentLocation != null)
                      fm.CircleLayer(
                        circles: [
                          fm.CircleMarker(
                            point: _currentLocation!,
                            color: Colors.blue.withOpacity(0.12),
                            borderStrokeWidth: 1,
                            useRadiusInMeter: true,
                            radius:
                                _accuracyThresholdM, // visualize acceptable radius
                          ),
                        ],
                      ),
                    // Draw polygon
                    if (_polygonPoints.isNotEmpty)
                      fm.PolygonLayer(
                        polygons: [
                          fm.Polygon(
                            points: _polygonPoints,
                            color: Colors.blue.withOpacity(0.3),
                            borderStrokeWidth: 2,
                            borderColor: Colors.blue,
                          ),
                        ],
                      ),
                    // Live GPS track visuals (polyline + small points), similar to Kaart
                    if (_isGpsRecording && _gpsTrack.isNotEmpty)
                      fm.PolylineLayer(
                        polylines: [
                          fm.Polyline(
                            points: _gpsTrack,
                            color: Colors.blue.withOpacity(0.6),
                            strokeWidth: 2.0,
                          ),
                        ],
                      ),
                    if (_isGpsRecording && _gpsTrack.isNotEmpty)
                      fm.CircleLayer(
                        circles:
                            _gpsTrack.map((p) {
                              return fm.CircleMarker(
                                point: p,
                                radius: 3,
                                color: Colors.blue.withOpacity(0.8),
                                borderColor: Colors.white,
                                borderStrokeWidth: 1,
                                useRadiusInMeter: false,
                              );
                            }).toList(),
                      ),
                    // Points with tap-to-select for editing
                    fm.MarkerLayer(
                      markers:
                          _polygonPoints.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final point = entry.value;
                            final isSelected =
                                _selectedPointIndex == idx && _editPinsMode;
                            return fm.Marker(
                              point: point,
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPointIndex = idx;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Pin ${idx + 1} geselecteerd. Tik op de kaart om te verplaatsen.',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.orange
                                            : Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),

                // Control panel at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: AppColors.darkGreen.withOpacity(0.95),
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 44),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Info text
                        Text(
                          _isGpsRecording
                              ? 'GPS-opname actief... Punten: ${_polygonPoints.length}'
                              : _isDrawing
                              ? 'Tik op de kaart om punten toe te voegen (${_polygonPoints.length} punten)'
                              : 'Kies een manier om het beschadigde gebied aan te geven',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Area info if polygon exists
                        if (_polygonPoints.length >= 3) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Oppervlakte: ${areaFmt.format(PolygonArea(points: _polygonPoints).calculateAreaInSquareMeters())} mÂ²',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_unitPricePerM2 != null)
                            _buildEstimatedCost(context),
                          const SizedBox(height: 12),
                        ],

                        // Action buttons
                        Row(
                          children: [
                            // Manual drawing button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _startDrawing,
                                icon: Icon(
                                  _isDrawing
                                      ? Icons.check
                                      : Icons.edit_location,
                                ),
                                label: Text(
                                  _isDrawing ? 'Tekenen' : 'Gebied tekenen',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _isDrawing
                                          ? AppColors.lightGreen
                                          : AppColors.lightMintGreen,
                                  foregroundColor:
                                      _isDrawing
                                          ? AppColors.offWhite
                                          : AppColors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // GPS recording button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _startGpsRecording,
                                icon: Icon(
                                  _isGpsRecording
                                      ? Icons.stop_circle
                                      : Icons.my_location,
                                ),
                                label: Text(
                                  _isGpsRecording ? 'Stop GPS' : 'GPS opnemen',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _isGpsRecording
                                          ? Colors.red
                                          : AppColors.lightMintGreen,
                                  foregroundColor:
                                      _isGpsRecording
                                          ? AppColors.offWhite
                                          : AppColors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Secondary action buttons
                        Row(
                          children: [
                            // Edit pins toggle
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _editPinsMode = !_editPinsMode;
                                    if (!_editPinsMode)
                                      _selectedPointIndex = null;
                                  });
                                },
                                icon: Icon(
                                  _editPinsMode ? Icons.edit_off : Icons.edit,
                                ),
                                label: Text(
                                  _editPinsMode
                                      ? 'Bewerken stoppen'
                                      : 'Bewerken',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Undo button
                            if (_polygonPoints.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _undoLastPoint,
                                  icon: const Icon(Icons.undo),
                                  label: const Text('Ongedaan maken'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white),
                                  ),
                                ),
                              ),
                            if (_polygonPoints.isNotEmpty)
                              const SizedBox(width: 8),

                            // Clear button
                            if (_polygonPoints.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _clearArea,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Wissen'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Unit price button (placed under Undo/Clear)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _promptUnitPrice,
                            icon: const Icon(Icons.euro),
                            label: Text(
                              _unitPricePerM2 == null
                                  ? 'Prijs instellen (â‚¬/mÂ²)'
                                  : 'Prijs: â‚¬${_formatPrice(_unitPricePerM2!)}/mÂ²',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightMintGreen,
                              foregroundColor: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Confirm button
                        if (_polygonPoints.length >= 3)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _completeArea,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Gebied bevestigen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        // Extra spacing to make the bottom container feel larger
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedCost(BuildContext context) {
    final areaM2 =
        (_polygonPoints.length >= 3)
            ? PolygonArea(points: _polygonPoints).calculateAreaInSquareMeters()
            : 0.0;
    final price = _unitPricePerM2 ?? 0.0;
    final total = areaM2 * price;

    // Persist in provider so it carries back to the form
    if (total > 0) {
      final provider = context.read<BelongingDamageReportProvider>();
      provider.setEstimatedDamage(total);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Geschatte kosten',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'â‚¬ ${NumberFormat('#,##0.00', 'nl_NL').format(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptUnitPrice() async {
    final controller = TextEditingController(
      // Show existing value without forced trailing zeros, using comma decimal
      text:
          _unitPricePerM2 != null
              ? _unitPricePerM2!.toString().replaceAll('.', ',')
              : '',
    );
    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Prijs per mÂ²'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: 'â‚¬ ',
              hintText: 'bijv. 2,50',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                Navigator.pop(ctx, parsed);
              },
              child: const Text('Opslaan'),
            ),
          ],
        );
      },
    );

    if (result != null && result > 0) {
      setState(() {
        _unitPricePerM2 = result;
      });
    }
  }

  LatLng _averageLatLng(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    double lat = 0, lng = 0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  String _formatPrice(double value) {
    // Format with up to 4 decimals, trim trailing zeros, and use comma decimal
    String s = value.toStringAsFixed(4); // e.g., 2.0000 or 2.5000
    s = s.replaceAll('.', ',');
    // Trim trailing zeros
    while (s.contains(',') && s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    // If ends with comma after trimming all zeros, remove the comma
    if (s.endsWith(',')) {
      s = s.substring(0, s.length - 1);
    }
    // Add thousands separators for integer part
    final parts = s.split(',');
    final intPart = parts[0].replaceAll('.', '');
    final formattedInt = NumberFormat(
      '#,##0',
      'nl_NL',
    ).format(int.parse(intPart));
    return parts.length == 2 && parts[1].isNotEmpty
        ? '$formattedInt,${parts[1]}'
        : formattedInt;
  }
}

