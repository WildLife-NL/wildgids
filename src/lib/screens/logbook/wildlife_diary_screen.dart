import 'package:wildgids/widgets/shared_ui_widgets/category_picker.dart';
import 'package:wildgids/models/enums/animal_count_mode.dart';
import 'package:wildgids/widgets/guide/animal_name.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/data_managers/api_client.dart';
import 'package:wildgids/data_managers/my_interaction_api.dart';
import 'package:wildgids/models/api_models/my_interaction.dart';
import 'package:wildgids/models/enums/nav_tab.dart';
import 'package:wildgids/screens/shared/interaction_detail_screen.dart';
import 'package:wildgids/utils/api_datetime.dart';
import 'package:wildgids/utils/location_label.dart';
import 'package:wildgids/utils/species_image_resolver.dart';
import 'package:wildgids/widgets/guide/guide_style.dart';
import 'package:wildgids/widgets/shared_ui_widgets/custom_nav_bar.dart';

class WildlifeDiaryScreen extends StatefulWidget {
  const WildlifeDiaryScreen({
    super.key,
    required this.onTabSelected,
    this.loadSightings,
    this.showReportFilters = false,
  });

  final ValueChanged<NavTab> onTabSelected;
  final bool showReportFilters;
  final Future<List<MyInteraction>> Function()? loadSightings;

  @override
  State<WildlifeDiaryScreen> createState() => _WildlifeDiaryScreenState();
}

class _WildlifeDiaryScreenState extends State<WildlifeDiaryScreen> {
  late Future<List<MyInteraction>> _future;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _showAll = false;
  int _reportType = 1;
  static const _reportTypes = {
    1: 'Waarnemingen',
    2: 'Schade',
    3: 'Aanrijdingen',
    0: 'Alle',
  };
  static const _months = [
    'januari',
    'februari',
    'maart',
    'april',
    'mei',
    'juni',
    'juli',
    'augustus',
    'september',
    'oktober',
    'november',
    'december',
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MyInteraction>> _load() async {
    final items =
        await (widget.loadSightings?.call() ??
            MyInteractionApi(context.read<ApiClient>()).getMyInteractions());
    return List<MyInteraction>.of(items)
      ..sort((a, b) => b.moment.compareTo(a.moment));
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    // FutureBuilder renders the error and offers retry.
    try {
      await _future;
    } catch (_) {}
  }

  String _monthLabel(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';

  Future<void> _chooseMonth(List<MyInteraction> items) async {
    final now = DateTime.now();
    final months =
        <DateTime>{
            DateTime(now.year, now.month),
            _month,
            ...items.map((item) {
              final date = ApiDateTime.toLocal(item.moment);
              return DateTime(date.year, date.month);
            }),
          }.toList()
          ..sort((a, b) => b.compareTo(a));
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: GuideStyle.background,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Kies een maand',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: GuideStyle.ink,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        months
                            .map(
                              (month) => ListTile(
                                title: Text(_monthLabel(month)),
                                selected: month == _month,
                                trailing:
                                    month == _month
                                        ? const Icon(
                                          Icons.check,
                                          color: GuideStyle.ink,
                                        )
                                        : null,
                                onTap: () => Navigator.pop(context, month),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
    if (selected != null && mounted) {
      setState(() {
        _month = selected;
        _showAll = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GuideStyle.background,
    appBar: AppBar(
      backgroundColor: GuideStyle.background,
      foregroundColor: GuideStyle.ink,
      title: const GuideBrand(),
      leading: BackButton(onPressed: () => Navigator.pop(context)),
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: FutureBuilder<List<MyInteraction>>(
        future: _future,
        builder: (context, snapshot) {
          final items =
              (snapshot.data ?? <MyInteraction>[]).where((item) {
                if (widget.showReportFilters && _reportType == 0) return true;
                if (_reportType == 1) {
                  return item.type.id == 1 || item.reportOfSighting != null;
                }
                return item.type.id == _reportType;
              }).toList();
          final monthly =
              items.where((item) {
                final date = ApiDateTime.toLocal(item.moment);
                return date.year == _month.year && date.month == _month.month;
              }).toList();
          final speciesCount =
              monthly
                  .map(
                    (item) =>
                        item.species.id.isNotEmpty
                            ? item.species.id
                            : _name(item),
                  )
                  .toSet()
                  .length;
          return RefreshIndicator(
            onRefresh: _refresh,
            color: GuideStyle.ink,
            child: LayoutBuilder(
              builder:
                  (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Your Wildlife Diary',
                                style: TextStyle(
                                  fontSize: 36,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                  color: GuideStyle.ink,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Momenten om te onthouden',
                                style: TextStyle(
                                  fontSize: 19,
                                  color: GuideStyle.muted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: GuideStyle.ink,
                                        side: const BorderSide(
                                          color: GuideStyle.border,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14,
                                        ),
                                      ),
                                      onPressed:
                                          snapshot.hasData
                                              ? () => _chooseMonth(items)
                                              : null,
                                      icon: const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 20,
                                      ),
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              _monthLabel(_month),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.expand_more,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.showReportFilters) ...[
                                    const SizedBox(width: 12),
                                    CategoryPicker(
                                      categories: _reportTypes.values.toList(),
                                      selected: _reportTypes[_reportType]!,
                                      compact: true,
                                      label: 'Type melding',
                                      sheetTitle: 'Filter je dagboek',
                                      allLabel: 'Alle meldingen',
                                      onChanged:
                                          (value) => setState(() {
                                            _reportType =
                                                _reportTypes.entries
                                                    .firstWhere(
                                                      (entry) =>
                                                          entry.value == value,
                                                    )
                                                    .key;
                                            _showAll = false;
                                          }),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting)
                                const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: GuideStyle.ink,
                                    ),
                                  ),
                                )
                              else if (snapshot.hasError)
                                _message(
                                  Icons.cloud_off_outlined,
                                  'Je dagboek kon niet worden geladen.',
                                  action: TextButton(
                                    onPressed: _refresh,
                                    child: const Text('Opnieuw proberen'),
                                  ),
                                )
                              else if (monthly.isEmpty)
                                _message(
                                  Icons.auto_stories_outlined,
                                  _reportType == 1
                                      ? 'Nog geen ontmoetingen in deze maand.'
                                      : 'Geen meldingen van dit type in deze maand.',
                                  detail:
                                      'Kies een andere maand of leg je volgende waarneming vast via Waarneming.',
                                )
                              else ...[
                                ...(_showAll ? monthly : monthly.take(3)).map(
                                  (item) => _entry(item),
                                ),
                                const SizedBox(height: 8),
                                Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: GuideStyle.card,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.bar_chart_rounded,
                                          color: GuideStyle.ink,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            '${monthly.length} ${_reportType == 1 ? (monthly.length == 1 ? 'ontmoeting' : 'ontmoetingen') : (monthly.length == 1 ? 'melding' : 'meldingen')} · $speciesCount ${speciesCount == 1 ? 'soort' : 'soorten'} deze maand',
                                            style: const TextStyle(
                                              color: GuideStyle.ink,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (monthly.length > 3) ...[
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    style: GuideStyle.primaryButton,
                                    onPressed:
                                        () => setState(
                                          () => _showAll = !_showAll,
                                        ),
                                    label: Text(
                                      _showAll
                                          ? 'Toon minder'
                                          : 'Bekijk volledig dagboek',
                                    ),
                                    icon: Icon(
                                      _showAll
                                          ? Icons.expand_less
                                          : Icons.arrow_forward,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          );
        },
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: CustomNavBar(
        currentTab: NavTab.logboek,
        onTabSelected: widget.onTabSelected,
      ),
    ),
  );

  String _name(MyInteraction item) =>
      item.species.commonName.isNotEmpty
          ? item.species.commonName
          : item.species.name.isNotEmpty
          ? item.species.name
          : 'Onbekend dier';

  Widget _entry(MyInteraction item) {
    final name = _name(item);
    final countMode = AnimalCountMode.fromNotes(item.description);
    final image = SpeciesImageResolver.drawingForCommonName(name);
    final count =
        item.reportOfSighting?.involvedAnimals.length ??
        item.reportOfCollision?.involvedAnimals.length ??
        0;
    final place =
        item.place.latitude == 0 && item.place.longitude == 0
            ? item.location
            : item.place;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: GuideStyle.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InteractionDetailScreen(interaction: item),
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 110,
                  decoration: BoxDecoration(
                    color: GuideStyle.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(6),
                  child:
                      image == null
                          ? const Icon(
                            Icons.pets_outlined,
                            color: GuideStyle.ink,
                          )
                          : Image.asset(
                            image,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                            errorBuilder:
                                (_, _, _) => const Icon(
                                  Icons.pets_outlined,
                                  color: GuideStyle.ink,
                                ),
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimalName(
                        '$name${countMode != AnimalCountMode.exact
                            ? ' · ${countMode.label}'
                            : count > 0
                            ? ' · $count ${count == 1 ? 'dier' : 'dieren'}'
                            : ''}',
                        style: const TextStyle(
                          color: GuideStyle.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.showReportFilters && _reportType != 1) ...[
                        const SizedBox(height: 4),
                        Text(
                          switch (item.type.id) {
                            1 => 'Waarneming',
                            2 => 'Schademelding',
                            3 => 'Dieraanrijding',
                            _ => item.type.name,
                          },
                          style: const TextStyle(
                            color: GuideStyle.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '${ApiDateTime.formatSummary(item.moment).replaceAll('|', '·')}\n${formatFriendlyLocation(place.latitude, place.longitude)}',
                        style: const TextStyle(
                          color: GuideStyle.muted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      if (item.species.category.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: GuideStyle.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.species.category,
                            style: const TextStyle(
                              color: GuideStyle.ink,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: GuideStyle.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title, {
    String? detail,
    Widget? action,
  }) => Card(
    elevation: 0,
    color: GuideStyle.surface,
    shape: GuideStyle.card,
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 36, color: GuideStyle.ink),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GuideStyle.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: GuideStyle.muted),
            ),
          ],
          if (action != null) action,
        ],
      ),
    ),
  );
}
