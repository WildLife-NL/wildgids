import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:flutter/services.dart';
import 'package:wildrapport/screens/belonging/area_selection_map.dart';
import 'package:wildrapport/models/beta_models/polygon_area_model.dart';

class BelongingCropsDetails extends StatefulWidget {
  const BelongingCropsDetails({super.key});

  @override
  State<BelongingCropsDetails> createState() => _BelongingCropsDetailsState();
}

class _BelongingCropsDetailsState extends State<BelongingCropsDetails> {
  late final TextEditingController _belongingController;
  late final TextEditingController _impactValueController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _currentDamageController;
  late final TextEditingController _expectedDamageController;
  late final BelongingDamageReportInterface _belongingDamageReportManager;
  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';

  @override
  void initState() {
    super.initState();
    _belongingDamageReportManager =
        context.read<BelongingDamageReportInterface>();

    final belongingDamageReportProvider =
        Provider.of<BelongingDamageReportProvider>(context, listen: false);

    // STEP A: Legacy normalization — if old state stored 'hectare', convert to m²
    if (belongingDamageReportProvider.impactedAreaType == 'hectare' &&
        belongingDamageReportProvider.impactedArea != null) {
      final ha = belongingDamageReportProvider.impactedArea!;
      belongingDamageReportProvider.setImpactedAreaType('vierkante meters');
      belongingDamageReportProvider.updateSelectedText('m2');
      belongingDamageReportProvider.setImpactedArea(ha * 10000); // ha -> m²
    }

    // Initialize controllers with proper text values
    final initialBelonging =
        belongingDamageReportProvider.impactedCrop.isNotEmpty
            ? belongingDamageReportProvider.impactedCrop
            : '';
    _belongingController = TextEditingController(text: initialBelonging);

    final impactAreaString = formatImpactAreaString();
    final initialImpact =
        (impactAreaString.isNotEmpty &&
                impactAreaString != "0" &&
                impactAreaString != "0.0")
            ? impactAreaString
            : '';
    _impactValueController = TextEditingController(text: initialImpact);

    final initialDescription =
        belongingDamageReportProvider.description.isNotEmpty
            ? belongingDamageReportProvider.description
            : '';
    _descriptionController = TextEditingController(text: initialDescription);

    final initialCurrentDamage =
        belongingDamageReportProvider.currentDamage > 0
            ? belongingDamageReportProvider.currentDamage.round().toString()
            : '';
    _currentDamageController = TextEditingController(
      text: initialCurrentDamage,
    );

    final initialExpectedDamage =
        belongingDamageReportProvider.expectedDamage > 0
            ? belongingDamageReportProvider.expectedDamage.round().toString()
            : '';
    _expectedDamageController = TextEditingController(
      text: initialExpectedDamage,
    );
  }

  @override
  void dispose() {
    _belongingController.dispose();
    _impactValueController.dispose();
    _descriptionController.dispose();
    _currentDamageController.dispose();
    _expectedDamageController.dispose();
    super.dispose();
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String formatImpactAreaString() {
    final belongingDamageReportProvider =
        Provider.of<BelongingDamageReportProvider>(context, listen: false);
    debugPrint(belongingDamageReportProvider.impactedAreaType);
    try {
      if (belongingDamageReportProvider.impactedAreaType.isNotEmpty &&
          belongingDamageReportProvider.impactedAreaType == "hectare") {
        debugPrint("FIRST");
        return belongingDamageReportProvider.impactedArea?.toString() ?? '';
      } else {
        debugPrint("SECOND");
        return belongingDamageReportProvider.impactedArea?.toInt().toString() ??
            '';
      }
    } catch (e, stackTrace) {
      debugPrint("Message: ${e.toString()}");
      debugPrint("stackTrace: $stackTrace");
      rethrow;
    }
  }

  void convertImpactArea(String value) {
    debugPrint("convertImpactArea: value = $value");
    final belongingDamageReportProvider =
        Provider.of<BelongingDamageReportProvider>(context, listen: false);

    if (belongingDamageReportProvider.impactedAreaType.isNotEmpty &&
        belongingDamageReportProvider.impactedArea != null &&
        belongingDamageReportProvider.impactedAreaType != value) {
      switch (value) {
        case "vierkante meters":
          belongingDamageReportProvider.setImpactedArea(
            belongingDamageReportProvider.impactedArea! * 10000,
          );
          break;
        case "hectare":
          belongingDamageReportProvider.setImpactedArea(
            belongingDamageReportProvider.impactedArea! / 10000,
          );
          break;
      }

      final impacted = belongingDamageReportProvider.impactedArea!;
      if (impacted == impacted.roundToDouble()) {
        _impactValueController.text = impacted.round().toString();
      } else {
        _impactValueController.text = impacted.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final belongingDamageReportProvider =
        Provider.of<BelongingDamageReportProvider>(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        belongingDamageReportProvider.updateExpanded(true);
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Beschrijf uw schade",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('belonging-field'),
                        controller: _belongingController,
                        minLines: 1,
                        maxLines: null,
                        onChanged: (value) {
                          _belongingDamageReportManager.updateImpactedCrop(
                            value,
                          );
                          belongingDamageReportProvider.setErrorState(
                            "impactedCrop",
                            false,
                          );
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Typ hier...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              color:
                                  belongingDamageReportProvider
                                          .hasErrorImpactedCrop
                                      ? Colors.red
                                      : AppColors.darkGreen,
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              color:
                                  belongingDamageReportProvider
                                          .hasErrorImpactedCrop
                                      ? Colors.red
                                      : AppColors.darkGreen,
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              color:
                                  belongingDamageReportProvider
                                          .hasErrorImpactedCrop
                                      ? Colors.red
                                      : AppColors.darkGreen,
                              width: 2.0,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.brown,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      if (belongingDamageReportProvider.hasErrorImpactedCrop)
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            'Dit veld is verplicht',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Category selector (Crops/Livestock)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Categorie",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                belongingDamageReportProvider.setDamageCategory(
                                  'crops',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      belongingDamageReportProvider
                                                  .damageCategory ==
                                              'crops'
                                          ? AppColors.darkGreen
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.darkGreen,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Gewassen',
                                    style: TextStyle(
                                      color:
                                          belongingDamageReportProvider
                                                      .damageCategory ==
                                                  'crops'
                                              ? Colors.white
                                              : AppColors.darkGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                belongingDamageReportProvider.setDamageCategory(
                                  'livestock',
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      belongingDamageReportProvider
                                                  .damageCategory ==
                                              'livestock'
                                          ? AppColors.darkGreen
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.darkGreen,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Vee',
                                    style: TextStyle(
                                      color:
                                          belongingDamageReportProvider
                                                      .damageCategory ==
                                                  'livestock'
                                              ? Colors.white
                                              : AppColors.darkGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ── CONDITIONAL: CROPS - MAP AREA SELECTION ──────────────────
                if (belongingDamageReportProvider.damageCategory == 'crops')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selecteer beschadigd gebied op de kaart",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(
                                context,
                              ).push<PolygonArea>(
                                MaterialPageRoute(
                                  builder:
                                      (context) => AreaSelectionMap(
                                        onAreaSelected: (area) {
                                          belongingDamageReportProvider
                                              .setPolygonArea(area);
                                        },
                                        existingArea:
                                            belongingDamageReportProvider
                                                .polygonArea,
                                      ),
                                ),
                              );
                              if (result != null) {
                                belongingDamageReportProvider.setPolygonArea(
                                  result,
                                );
                              }
                            },
                            icon: const Icon(Icons.map),
                            label: const Text(
                              'Selecteer gebied op kaart',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (belongingDamageReportProvider.polygonArea == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Geen gebied geselecteerd',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              belongingDamageReportProvider.polygonArea == null
                                  ? const Text(
                                    "Hier kiest u hoe u gewasschade aangeeft: loop de schade af of plaats pinnen op de kaart. Na het invullen van een waarde per eenheid berekent de kaart ook de kosten van uw schade.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Oppervlakte: ${belongingDamageReportProvider.polygonArea!.calculateAreaInSquareMeters().toStringAsFixed(0)} m²',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          height: 1.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        (belongingDamageReportProvider
                                                    .estimatedDamage >
                                                0)
                                            ? 'Kosten: € ${belongingDamageReportProvider.estimatedDamage.toStringAsFixed(2)}'
                                            : 'Kosten:',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          height: 1.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                // ── CONDITIONAL: LIVESTOCK - AMOUNT FIELD ───────────────────
                if (belongingDamageReportProvider.damageCategory == 'livestock')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Aantal",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final amount = int.tryParse(value);
                              if (amount != null && amount > 0) {
                                belongingDamageReportProvider
                                    .setLivestockAmount(amount);
                              }
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Voer aantal in...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: AppColors.darkGreen,
                                width: 2.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: AppColors.darkGreen,
                                width: 2.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: AppColors.darkGreen,
                                width: 2.0,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.brown,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                // Scope of Damage field removed
                const SizedBox(height: 6),
                if (belongingDamageReportProvider.damageCategory == 'livestock')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Geschatte huidige schade",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: const BoxDecoration(),
                          child: TextField(
                            key: const Key('estimated-damage'),
                            controller: _currentDamageController,
                            minLines: 1,
                            maxLines: null,
                            onChanged: (value) {
                              if (value.isEmpty) {
                                _belongingDamageReportManager
                                    .updateCurrentDamage(0);
                              } else {
                                final parsed = double.tryParse(value);
                                if (parsed != null) {
                                  _belongingDamageReportManager
                                      .updateCurrentDamage(parsed);
                                }
                              }
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              label: const Text('Bedrag in €'),
                              prefixText: '€ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: AppColors.darkGreen,
                                  width: 2.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: AppColors.darkGreen,
                                  width: 2.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: AppColors.darkGreen,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.brown,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                if (belongingDamageReportProvider.damageCategory == 'livestock')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Verwachte inkomstenderving",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: const BoxDecoration(),
                          child: TextField(
                            key: const Key('estimated-future-damage'),
                            controller: _expectedDamageController,
                            minLines: 1,
                            maxLines: null,
                            onChanged: (value) {
                              if (value.isEmpty) {
                                _belongingDamageReportManager
                                    .updateExpectedDamage(0);
                              } else {
                                final parsed = double.tryParse(value);
                                if (parsed != null) {
                                  _belongingDamageReportManager
                                      .updateExpectedDamage(parsed);
                                }
                              }
                            },
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              label: const Text('Bedrag in €'),
                              prefixText: '€ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: AppColors.darkGreen,
                                  width: 2.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: AppColors.darkGreen,
                                  width: 2.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: AppColors.darkGreen,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.brown,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Comment field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Opmerking",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: null,
                        onChanged: (value) {
                          // Keep both provider and manager in sync
                          final provider = Provider.of<BelongingDamageReportProvider>(
                            context,
                            listen: false,
                          );
                          provider.setDescription(value);
                          _belongingDamageReportManager.updateDescription(value);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Typ hier...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.darkGreen,
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.darkGreen,
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.darkGreen,
                              width: 2.0,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.brown,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
