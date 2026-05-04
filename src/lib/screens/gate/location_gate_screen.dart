import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wildgids/constants/app_colors.dart';

class LocationGateScreen extends StatefulWidget {
  final Widget next;
  const LocationGateScreen({super.key, required this.next});

  @override
  State<LocationGateScreen> createState() => _LocationGateScreenState();
}

class _LocationGateScreenState extends State<LocationGateScreen> {
  bool _checking = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _ensureLocationReady();
  }

  Future<void> _ensureLocationReady() async {
    setState(() {
      _checking = true;
      _message = null;
    });

    // 1) Location services enabled?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _checking = false;
        _message = 'Schakel uw locatievoorzieningen in om door te gaan.';
      });
      return;
    }

    // 2) Permissions granted?
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _checking = false;
        _message = 'Locatietoestemming is vereist om de app te gebruiken.';
      });
      return;
    }

    // All good — proceed
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _ensureLocationReady();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _ensureLocationReady();
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.lightMintGreen,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.darkGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Locatie vereist',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _message ??
                    'Deze app heeft toegang tot uw locatie nodig om te functioneren.',
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      // Try both: service and permission paths
                      await _openLocationSettings();
                    },
                    child: const Text('Locatie inschakelen'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.darkGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openAppSettings,
                    child: const Text('App-instellingen openen'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _exitApp,
                    child: const Text(
                      'App afsluiten',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
