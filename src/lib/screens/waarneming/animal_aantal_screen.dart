import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:wildgids/interfaces/waarneming_flow/animal_sighting_reporting_interface.dart';
import 'package:wildgids/models/enums/animal_count_mode.dart';
import 'package:wildgids/models/enums/location_source.dart';
import 'package:wildgids/screens/waarneming/animal_activity_screen.dart';
import 'package:wildgids/screens/waarneming/location_selection_screen.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/widgets/guide/animal_artwork.dart';
import 'package:wildgids/widgets/guide/animal_name.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:wildgids/widgets/reporting/report_layout.dart';

class AnimalAantalScreen extends StatefulWidget {
  const AnimalAantalScreen({super.key});
  @override
  State<AnimalAantalScreen> createState() => _AnimalAantalScreenState();
}

class _AnimalAantalScreenState extends State<AnimalAantalScreen> {
  late int currentCount;
  late AnimalCountMode _mode;
  late TextEditingController _countController;
  bool get _validCount =>
      int.tryParse(_countController.text) != null && currentCount > 0;
  AnimalSightingReportingInterface get _manager =>
      context.read<AnimalSightingReportingInterface>();

  @override
  void initState() {
    super.initState();
    final sighting = _manager.getCurrentanimalSighting();
    currentCount =
        (sighting?.animalCount ?? 1) > 0 ? (sighting?.animalCount ?? 1) : 1;
    _mode = sighting?.countMode ?? AnimalCountMode.exact;
    _countController = TextEditingController(text: '$currentCount');
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _setCount(int value) => setState(() {
    currentCount = value;
    _countController.text = '$value';
  });

  void _saveAnimalCount() {
    final sighting = _manager.getCurrentanimalSighting();
    if (sighting == null) return;
    _manager.updateCurrentanimalSighting(
      sighting.copyWith(
        animalCount: _mode == AnimalCountMode.exact ? currentCount : 0,
        countMode: _mode,
        animals:
            _mode == AnimalCountMode.exact &&
                    sighting.countMode == AnimalCountMode.exact &&
                    sighting.animalCount == currentCount
                ? sighting.animals
                : [],
      ),
    );
  }

  void _handleBackNavigation() {
    _saveAnimalCount();
    if (Navigator.of(context).canPop()) Navigator.pop(context);
  }

  void _continue({bool details = false}) {
    if (_mode == AnimalCountMode.exact && !_validCount) return;
    FocusScope.of(context).unfocus();
    _saveAnimalCount();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AnimalActivityScreen(
              totalCount: _mode == AnimalCountMode.exact ? currentCount : 0,
              proceedToDetails: details && _mode == AnimalCountMode.exact,
            ),
      ),
    );
  }

  DateTime get _moment =>
      _manager.getCurrentanimalSighting()?.dateTime?.dateTime ?? DateTime.now();

  Future<void> _pickDate() async {
    final moment = _moment;
    final picked = await showDatePicker(
      context: context,
      initialDate: moment,
      firstDate: DateTime(moment.year - 5),
      lastDate: DateTime(moment.year + 5),
    );
    if (picked == null || !mounted) return;
    _manager.updateDateTime(
      DateTime(
        picked.year,
        picked.month,
        picked.day,
        moment.hour,
        moment.minute,
      ),
    );
    setState(() {});
  }

  Future<void> _pickTime() async {
    final moment = _moment;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(moment),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (picked == null || !mounted) return;
    _manager.updateDateTime(
      DateTime(
        moment.year,
        moment.month,
        moment.day,
        picked.hour,
        picked.minute,
      ),
    );
    setState(() {});
  }

  Future<void> _changeLocation() async {
    _saveAnimalCount();
    final locations = _manager.getCurrentanimalSighting()?.locations ?? [];
    final place =
        locations.isEmpty
            ? null
            : locations.lastWhere(
              (location) => location.source == LocationSource.manual,
              orElse: () => locations.first,
            );
    final initial =
        place?.latitude != null && place?.longitude != null
            ? LatLng(place!.latitude!, place.longitude!)
            : null;
    await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder:
            (_) => LocationSelectionScreen(
              initialLocation: initial,
              returnSelection: true,
            ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sighting = _manager.getCurrentanimalSighting();
    final animal = sighting?.animalSelected;
    final moment = _moment;
    final locations = sighting?.locations ?? [];
    final place =
        locations.isEmpty
            ? null
            : locations.lastWhere(
              (location) => location.source == LocationSource.manual,
              orElse: () => locations.first,
            );
    final locationLabel =
        place?.cityName?.isNotEmpty == true
            ? place!.cityName!
            : place?.streetName?.isNotEmpty == true
            ? place!.streetName!
            : place?.latitude != null && place?.longitude != null
            ? '${place!.latitude!.toStringAsFixed(2)}, ${place.longitude!.toStringAsFixed(2)}'
            : 'Kies een locatie';
    return ReportLayout(
      title: 'Wat zag je?',
      stage: 'Je ontmoeting',
      onBack: _handleBackNavigation,
      footer:
          animal == null
              ? null
              : ReportAction(
                label: 'Verder',
                onPressed:
                    _mode != AnimalCountMode.exact || _validCount
                        ? () => _continue()
                        : null,
              ),
      child:
          animal == null
              ? const Text('Kies eerst een dier.')
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportSurface(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          height: 85,
                          child: AnimalArtwork(
                            imagePath:
                                SpeciesImageResolver.drawingForCommonName(
                                  animal.animalName,
                                ) ??
                                animal.animalImagePath,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimalName(
                            animal.animalName,
                            style: const TextStyle(
                              color: GuideStyle.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              Navigator.of(context).canPop()
                                  ? _handleBackNavigation
                                  : null,
                          style: TextButton.styleFrom(
                            foregroundColor: GuideStyle.ink,
                          ),
                          child: const Text('Wijzig'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ReportSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Hoeveel?',
                          style: TextStyle(
                            color: GuideStyle.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_mode == AnimalCountMode.exact) ...[
                          Row(
                            children: [
                              IconButton.filledTonal(
                                tooltip: 'Minder dieren',
                                onPressed:
                                    currentCount > 0
                                        ? () => _setCount(currentCount - 1)
                                        : null,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(52, 52),
                                  backgroundColor: GuideStyle.surface,
                                  foregroundColor: GuideStyle.ink,
                                ),
                                icon: const Icon(Icons.remove, size: 28),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _countController,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w800,
                                    color: GuideStyle.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    border: InputBorder.none,
                                    semanticCounterText: 'Exact aantal dieren',
                                  ),
                                  onChanged:
                                      (value) => setState(
                                        () =>
                                            currentCount =
                                                int.tryParse(value) ?? 0,
                                      ),
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: 'Meer dieren',
                                onPressed: () => _setCount(currentCount + 1),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(52, 52),
                                  backgroundColor: GuideStyle.surface,
                                  foregroundColor: GuideStyle.ink,
                                ),
                                icon: const Icon(Icons.add, size: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children:
                                [10, 20, 50]
                                    .map(
                                      (amount) => ActionChip(
                                        label: Text('+ $amount'),
                                        side: const BorderSide(
                                          color: GuideStyle.border,
                                        ),
                                        backgroundColor: GuideStyle.surface,
                                        onPressed:
                                            () => _setCount(
                                              currentCount + amount,
                                            ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Icon(
                                  _mode == AnimalCountMode.group
                                      ? Icons.groups_outlined
                                      : Icons.help_outline,
                                  size: 36,
                                  color: GuideStyle.ink,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _mode == AnimalCountMode.group
                                      ? 'Groep gezien, niet geteld'
                                      : 'Aantal onbekend',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: GuideStyle.muted,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const labelStyle = TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            );
                            final stacked =
                                constraints.maxWidth < 220 ||
                                MediaQuery.textScalerOf(context).scale(1) > 1.3;
                            final choices =
                                AnimalCountMode.values
                                    .map(
                                      (mode) => ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 48,
                                        ),
                                        child: ChoiceChip(
                                          key: ValueKey(
                                            'count-mode-${mode.name}',
                                          ),
                                          label: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                mode.label,
                                                textAlign: TextAlign.center,
                                                softWrap: false,
                                              ),
                                            ),
                                          ),
                                          showCheckmark: false,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 4,
                                          ),
                                          labelPadding: EdgeInsets.zero,
                                          selected: _mode == mode,
                                          selectedColor: GuideStyle.ink,
                                          backgroundColor: GuideStyle.surface,
                                          checkmarkColor: Colors.white,
                                          labelStyle: labelStyle.copyWith(
                                            color:
                                                _mode == mode
                                                    ? Colors.white
                                                    : GuideStyle.ink,
                                          ),
                                          side: const BorderSide(
                                            color: GuideStyle.border,
                                          ),
                                          onSelected:
                                              (_) =>
                                                  setState(() => _mode = mode),
                                        ),
                                      ),
                                    )
                                    .toList();
                            if (stacked) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var i = 0; i < choices.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 8),
                                    choices[i],
                                  ],
                                ],
                              );
                            }
                            return Row(
                              children: [
                                for (var i = 0; i < choices.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Expanded(child: choices[i]),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _field(
                    Icons.calendar_today_outlined,
                    'Datum',
                    '${moment.day}-${moment.month}-${moment.year}',
                    _pickDate,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    Icons.schedule_outlined,
                    'Tijd',
                    '${moment.hour.toString().padLeft(2, '0')}:${moment.minute.toString().padLeft(2, '0')}',
                    _pickTime,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    Icons.place_outlined,
                    'Locatie',
                    locationLabel,
                    _changeLocation,
                  ),
                  if (_mode == AnimalCountMode.exact) ...[
                    const SizedBox(height: 16),
                    ReportAction(
                      label: 'Details per dier toevoegen',
                      secondary: true,
                      onPressed:
                          _validCount ? () => _continue(details: true) : null,
                    ),
                  ],
                ],
              ),
    );
  }

  Widget _field(
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: GuideStyle.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: GuideStyle.ink),
      title: Text(
        title,
        style: const TextStyle(
          color: GuideStyle.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(value, style: const TextStyle(color: GuideStyle.muted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: GuideStyle.ink),
    ),
  );
}
