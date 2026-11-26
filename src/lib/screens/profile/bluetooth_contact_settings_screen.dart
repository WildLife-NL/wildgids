import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/services/collar_identity_store.dart';
import 'package:wildgids/services/contact_tracing_ble.dart';
import 'package:wildgids/services/contact_tracing_coordinator.dart';
import 'package:wildgids/services/contact_tracing_monitor.dart';
import 'package:wildgids/services/contact_tracing_preferences.dart';
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
  late final ContactTracingMonitor _listenedMonitor;
  ContactTracingCoordinator get _coordinator =>
      context.read<ContactTracingCoordinator>();

  ContactTracingMonitor get _monitor => _coordinator.monitor;

  @override
  void initState() {
    super.initState();
    _listenedMonitor = _monitor;
    _listenedMonitor.addListener(_onMonitorChanged);
  }

  @override
  void dispose() {
    _listenedMonitor.removeListener(_onMonitorChanged);
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
      if (!ended) {
        _showSnack('Geen actief contact gevonden');
      } else {
        final contact = _monitor.lastEndedContact;
        final label = contact?.animalDisplayLabel;
        _showSnack(
          label != null ? 'Contact met $label beëindigd' : 'Contact beëindigd',
        );
      }
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

  Future<void> _registerTracker(ScanResult result) async {
    final coordinator = _coordinator;
    String? address;
    if (coordinator.hardwareAddressFor(result) == null) {
      address = await showDialog<String>(
        context: context,
        builder:
            (_) => _TrackerAddressDialog(
              label: ContactTracingBle.deviceLabel(result),
            ),
      );
      if (address == null || !mounted) return;
    }
    try {
      await coordinator.registerDevice(result, hardwareAddress: address);
    } catch (_) {
      if (mounted) _showSnack('Tracker koppelen mislukt. Probeer opnieuw.');
    }
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            height: 1.3,
          ),
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
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      hasActive
                          ? _buildActiveStatus()
                          : coordinator.statusMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color:
                            coordinator.backgroundScanning
                                ? AppColors.primaryGreen
                                : Colors.black87,
                      ),
                    ),
                  ),
                  if (coordinator.needsBluetoothPermission && !hasActive) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Open telefooninstellingen'),
                      onPressed: () async {
                        if (!await openAppSettings() && mounted) {
                          _showSnack(
                            'Open Instellingen op je telefoon en geef WildGids toegang tot Bluetooth.',
                          );
                        }
                      },
                    ),
                  ],
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
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed:
                          coordinator.backgroundScanning ||
                                  coordinator.registeringContact
                              ? null
                              : () => coordinator.triggerBackgroundScanNow(
                                force: true,
                              ),
                      icon: Icon(
                        coordinator.backgroundScanning ||
                                coordinator.registeringContact
                            ? Icons.hourglass_top
                            : Icons.radar,
                      ),
                      label: Text(
                        coordinator.registeringContact
                            ? 'Contact starten…'
                            : coordinator.backgroundScanning
                            ? 'Scannen…'
                            : 'Nu scannen',
                      ),
                    ),
                  ],
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
              final mac = coordinator.hardwareAddressFor(result);
              final separateAction =
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              final action = TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed:
                    coordinator.backgroundScanning ||
                            coordinator.registeringContact
                        ? null
                        : () => _registerTracker(result),
                child: Text(mac == null ? 'Koppel tracker' : 'Start contact'),
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.sensors,
                        color: AppColors.primaryGreen,
                      ),
                      title: Text(label),
                      subtitle: Text(
                        mac == null
                            ? 'Koppelen nodig · ${result.rssi} dBm'
                            : '$mac · ${result.rssi} dBm',
                      ),
                      trailing: separateAction ? null : action,
                    ),
                    if (separateAction)
                      Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: action,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
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
                    min:
                        ContactTracingPreferences.minBackgroundIntervalSeconds
                            .toDouble(),
                    max:
                        ContactTracingPreferences.maxBackgroundIntervalSeconds
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
                    min:
                        ContactTracingPreferences.minActiveScanIntervalSeconds
                            .toDouble(),
                    max:
                        ContactTracingPreferences.maxActiveScanIntervalSeconds
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
                    min:
                        ContactTracingPreferences.minSignalLossSeconds
                            .toDouble(),
                    max:
                        ContactTracingPreferences.maxSignalLossSeconds
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
                      'Pushmelding bij start en einde van een collar-contact.',
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
        ],
      ),
    );
  }
}

class _TrackerAddressDialog extends StatefulWidget {
  const _TrackerAddressDialog({required this.label});
  final String label;

  @override
  State<_TrackerAddressDialog> createState() => _TrackerAddressDialogState();
}

class _TrackerAddressDialogState extends State<_TrackerAddressDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Koppel ${widget.label}'),
    scrollable: true,
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Je iPhone toont het Bluetooth-adres van de tracker niet. '
            'Vul het volledige adres van deze tracker in. '
            'Vraag dit zo nodig aan de beheerder van de tracker.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Bluetooth-MAC-adres',
              hintText: 'AA:BB:CC:DD:EE:FF',
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => CollarIdentityStore.validate(
                  value ?? '',
                  advertisedName: widget.label,
                ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annuleren'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.of(context).pop(_controller.text.trim());
          }
        },
        child: const Text('Koppelen'),
      ),
    ],
  );
}
