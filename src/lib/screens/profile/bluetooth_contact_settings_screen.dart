import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/services/contact_tracing_ble.dart';
import 'package:wildgids/services/contact_tracing_coordinator.dart';
import 'package:wildgids/services/contact_tracing_monitor.dart';
import 'package:wildgids/services/contact_tracing_preferences.dart';
import 'package:wildgids/utils/ble_mac_format.dart';
import 'package:wildgids/utils/snack_bar_utils.dart';
import 'package:wildgids/widgets/contact/contact_info_panel.dart';

/// Interval, status en instellingen voor Bluetooth-contacttracing.
class BluetoothContactSettingsScreen extends StatefulWidget {
  const BluetoothContactSettingsScreen({super.key});

  @override
  State<BluetoothContactSettingsScreen> createState() =>
      _BluetoothContactSettingsScreenState();
}

class _BluetoothContactSettingsScreenState
    extends State<BluetoothContactSettingsScreen> {
  ContactTracingCoordinator get _coordinator =>
      context.read<ContactTracingCoordinator>();

  ContactTracingMonitor get _monitor => _coordinator.monitor;

  @override
  void initState() {
    super.initState();
    _monitor.addListener(_onMonitorChanged);
  }

  @override
  void dispose() {
    _monitor.removeListener(_onMonitorChanged);
    super.dispose();
  }

  void _onMonitorChanged() {
    if (!mounted) return;
    final msg = _monitor.lastAutoEndMessage;
    if (msg != null) {
      _showSnack(msg);
      _monitor.clearAutoEndMessage();
    }
    setState(() {});
  }

  String _buildActiveStatus() {
    final animal = _monitor.activeAnimalLabel;
    final since = _monitor.timeSinceLastSeen;
    if (animal != null && since == null) {
      return 'Contact met $animal — wacht op advertentie…';
    }
    final secs = since?.inSeconds ?? 0;
    final dBm = _monitor.lastAdvertisementRssi;
    final dBmPart = dBm != null ? ' · $dBm dBm' : '';
    if (secs <= _coordinator.signalLossSeconds) {
      return '${animal ?? 'Collar'} — ${secs}s geleden gezien$dBmPart';
    }
    return '${animal ?? 'Collar'} — geen advertentie ($secs s)';
  }

  Future<void> _endContact() async {
    try {
      final ended = await _coordinator.endAllActiveContacts();
      if (!mounted) return;
      _showSnack(
        ended ? 'Contact beëindigd' : 'Geen actief contact gevonden',
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _showSnack('Contact beëindigen mislukt');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        margin: snackBarMarginForContext(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _settingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: Colors.grey.shade700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _intervalSlider({
    required String label,
    required String hint,
    required double min,
    required double max,
    required int divisions,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
        ),
        Slider(
          min: min,
          max: max,
          divisions: divisions,
          value: value.toDouble(),
          label: '${value}s',
          activeColor: AppColors.primaryGreen,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<ContactTracingCoordinator>();
    final monitor = coordinator.monitor;
    final hasActive = monitor.hasActiveSession;
    final devices = coordinator.discoveryDevicesSorted;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF2EF),
      appBar: AppBar(
        title: const Text(
          'Interval & status',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFEFF2EF),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasActive ? _buildActiveStatus() : coordinator.statusMessage,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: coordinator.backgroundScanning
                          ? AppColors.primaryGreen
                          : Colors.black87,
                    ),
                  ),
                  if (coordinator.backgroundScanning && !hasActive) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Color(0xFFE0E8E0),
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Even geduld — scan duurt ongeveer 8 seconden',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (!coordinator.backgroundEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Achtergrondscan staat uit. Zet de schakelaar aan onder Profiel → Voorkeuren.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (hasActive) ...[
                    if (monitor.activeContact != null) ...[
                      const SizedBox(height: 12),
                      ContactInfoPanel(
                        contact: monitor.activeContact!,
                        compact: true,
                      ),
                    ] else if (monitor.activeAnimalLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        monitor.activeAnimalLabel!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                    if (monitor.activeContactMac != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        monitor.activeContactMac!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: monitor.busyEnding ? null : _endContact,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                      ),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Contact beëindigen'),
                    ),
                  ] else if (coordinator.backgroundEnabled) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: coordinator.backgroundScanning
                          ? null
                          : () => coordinator.triggerBackgroundScanNow(
                                force: true,
                              ),
                      icon: Icon(
                        coordinator.backgroundScanning
                            ? Icons.hourglass_top
                            : Icons.radar,
                      ),
                      label: Text(
                        coordinator.backgroundScanning
                            ? 'Scannen…'
                            : 'Nu scannen',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _settingsSectionTitle('Instellingen'),
                  _intervalSlider(
                    label:
                        'Achtergrondscan: ${coordinator.backgroundIntervalSeconds} s',
                    hint:
                        'Hoe vaak op de achtergrond naar collars wordt gezocht (ook buiten dit scherm).',
                    min: ContactTracingPreferences.minBackgroundIntervalSeconds
                        .toDouble(),
                    max: ContactTracingPreferences.maxBackgroundIntervalSeconds
                        .toDouble(),
                    divisions: 4,
                    value: coordinator.backgroundIntervalSeconds,
                    onChanged: (v) {
                      unawaited(coordinator.setBackgroundIntervalSeconds(v));
                    },
                  ),
                  const Divider(height: 20),
                  _intervalSlider(
                    label:
                        'Scan tijdens contact: ${coordinator.activeScanIntervalSeconds} s',
                    hint:
                        'Hoe vaak opnieuw wordt gescand zolang een contact actief is.',
                    min: ContactTracingPreferences.minActiveScanIntervalSeconds
                        .toDouble(),
                    max: ContactTracingPreferences.maxActiveScanIntervalSeconds
                        .toDouble(),
                    divisions: 7,
                    value: coordinator.activeScanIntervalSeconds,
                    onChanged: (v) {
                      unawaited(coordinator.setActiveScanIntervalSeconds(v));
                    },
                  ),
                  const Divider(height: 20),
                  _intervalSlider(
                    label: 'Signaal weg na: ${coordinator.signalLossSeconds} s',
                    hint:
                        'Geen advertentie meer van de collar → contact automatisch beëindigen.',
                    min: ContactTracingPreferences.minSignalLossSeconds
                        .toDouble(),
                    max: ContactTracingPreferences.maxSignalLossSeconds
                        .toDouble(),
                    divisions: 7,
                    value: coordinator.signalLossSeconds,
                    onChanged: (v) {
                      unawaited(coordinator.setSignalLossSeconds(v));
                    },
                  ),
                  const Divider(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Melding bij dier gevonden'),
                    subtitle: const Text(
                      'Pushmelding wanneer een collar-contact is gestart.',
                    ),
                    value: coordinator.notifyOnAnimalFound,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (v) {
                      unawaited(coordinator.setNotifyOnAnimalFound(v));
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Alleen Smart Parks'),
                    subtitle: const Text(
                      'Ranger-service, SP-naam of manufacturer Smart Parks.',
                    ),
                    value: coordinator.onlySmartParks,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryGreen,
                    onChanged: (v) {
                      unawaited(coordinator.setOnlySmartParks(v));
                    },
                  ),
                ],
              ),
            ),
          ),
          if (coordinator.backgroundEnabled && !hasActive) ...[
            const SizedBox(height: 8),
            _settingsSectionTitle('Laatst gezien in buurt'),
            const SizedBox(height: 8),
            if (devices.isEmpty)
              Text(
                'Nog geen collar in de laatste scan.',
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
            ...devices.map((result) {
              final label = ContactTracingBle.deviceLabel(result);
              final mac = formatBleHardwareAddress(result.device.remoteId.str);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.sensors, color: AppColors.primaryGreen),
                  title: Text(label),
                  subtitle: Text('$mac · ${result.rssi} dBm'),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

