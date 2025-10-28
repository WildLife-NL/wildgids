import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:wildrapport/widgets/belonging/belonging_dropdown.dart';

class BelongingCropsDetails extends StatefulWidget {
  const BelongingCropsDetails({super.key});

  @override
  State<BelongingCropsDetails> createState() => _BelongingCropsDetailsState();
}

class _BelongingCropsDetailsState extends State<BelongingCropsDetails> {
  final TextEditingController _impactValueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late final BelongingDamageReportInterface _belongingDamageReportManager;
  final greenLog = '\x1B[32m';
  final redLog = '\x1B[31m';
  final yellowLog = '\x1B[93m';

  @override
  void initState() {
    super.initState();
    _belongingDamageReportManager =
        context.read<BelongingDamageReportInterface>();

    // Initialize the controller with the value from the provider
    _impactValueController.text = formatImpactAreaString();
    
    final belongingDamageReportProvider =
      Provider.of<BelongingDamageReportProvider>(context, listen: false);
    _descriptionController.text = belongingDamageReportProvider.description;
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
    final euroFormat = NumberFormat.currency(
      locale: 'nl_NL',
      symbol: '€',
      decimalDigits: 0,
    );
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
                BelongingDropdown(
                  key: const Key('impacted-crop'),
                  onChanged: (value) {
                    _belongingDamageReportManager.updateImpactedCrop(value);
                    belongingDamageReportProvider.setErrorState(
                      "impactedCrop",
                      false,
                    );
                  },
                  getSelectedValue: belongingDamageReportProvider.impactedCrop,
                  getSelectedText: capitalize(
                    belongingDamageReportProvider.impactedCrop,
                  ),
                  dropdownItems: [
                    {'text': 'Mais', 'value': 'mais'},
                    {'text': 'Bieten', 'value': 'bieten'},
                    {'text': 'Granen', 'value': 'granen'},
                    {'text': 'Bloementeelt', 'value': 'bloementeelt'},
                    {'text': 'Grasvelden', 'value': 'grasvelden'},
                    {'text': 'Boomteelt', 'value': 'boomteelt'},
                    {'text': 'Tuinbouw', 'value': 'tuinbouw'},
                  ],
                  containerHeight: 50,
                  containerWidth: 400,
                  startingValue: "mais",
                  defaultValue: "Kies Gewas",
                  hasDropdownSideDescription: false,
                  hasError: belongingDamageReportProvider.hasErrorImpactedCrop,
                  useIcons: true,
                ),
                const SizedBox(height: 10),

                BelongingDropdown(
                  key: const Key('impacted-area-type'),
                  onChanged: (value) {
                    // Update the impacted area type
                    switch (value) {
                      case "vierkante meters":
                        belongingDamageReportProvider.updateSelectedText("m2");
                      case "hectare":
                        belongingDamageReportProvider.updateSelectedText("ha");
                      default:
                        belongingDamageReportProvider.updateSelectedText(
                          "Type",
                        );
                    }
                    convertImpactArea(value);
                    _belongingDamageReportManager.updateImpactedAreaType(value);
                    belongingDamageReportProvider.setErrorState(
                      "impactedAreaType",
                      false,
                    );

                    // If impactedArea is not null or empty, validate the input
                    if (_impactValueController.text.isNotEmpty) {
                      final areaType = value;
                      String cleanedValue = _impactValueController.text.replaceAll(
                        ',',
                        '.',
                      );

                      bool isValid = false;
                      double? parsed;

                      if (areaType == "vierkante meters") {
                        // Only allow full integers
                        final intRegex = RegExp(r'^\d+$');
                        if (intRegex.hasMatch(_impactValueController.text)) {
                          parsed = double.tryParse(_impactValueController.text);
                          isValid = parsed != null;
                        }
                      } else if (areaType == "hectare") {
                        // Allow decimals with comma or dot
                        final decimalRegex = RegExp(r'^\d+([.,]\d+)?$');
                        if (decimalRegex.hasMatch(cleanedValue)) {
                          parsed = double.tryParse(cleanedValue);
                          isValid = parsed != null;
                        }
                      }
                      debugPrint("$isValid");
                      if (isValid) {
                        setState(() {});
                        debugPrint("$yellowLog is valid = $isValid");
                        debugPrint("$yellowLog parsed = $parsed");

                        _belongingDamageReportManager.updateImpactedArea(
                          parsed!,
                        );
                        belongingDamageReportProvider.setHasErrorImpactedArea(
                          false,
                        ); // Clear error in provider
                        belongingDamageReportProvider
                            .resetInputErrorImpactArea();

                        debugPrint(
                          "$yellowLog ErrorImpactedArea = ${belongingDamageReportProvider.hasErrorImpactedArea}",
                        );
                      } else {
                        setState(() {
                          belongingDamageReportProvider
                              .updateInputErrorImpactArea(
                                areaType == "vierkante meters"
                                    ? "Alleen gehele getallen toegestaan"
                                    : "Gebruik een geldig getal (bv. 1,5 of 1.5)",
                              );
                        });
                        belongingDamageReportProvider.setHasErrorImpactedArea(
                          true,
                        ); // Set error in provider
                      }
                    }
                  },
                  getSelectedValue:
                      belongingDamageReportProvider.impactedAreaType,
                  getSelectedText:
                      belongingDamageReportProvider.selectedText ?? "Type",
                  dropdownItems: [
                    {'text': 'ha', 'value': 'hectare'},
                    {'text': 'm2', 'value': 'vierkante meters'},
                  ],
                  startingValue: "vierkante meters",
                  defaultValue: "Type",
                  hasDropdownSideDescription: true,
                  dropdownSideDescriptionText: "Getroffen Gebied",
                  hasError:
                      belongingDamageReportProvider.hasErrorImpactedAreaType,
                  useIcons: false,
                ),

                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: TextField(
                          key: const Key('area-value'),
                          controller: _impactValueController,
                          onChanged: (value) {
                            debugPrint(value);
                            final areaType =
                                belongingDamageReportProvider.impactedAreaType;
                            String cleanedValue = value.replaceAll(',', '.');

                            bool isValid = false;
                            double? parsed;

                            if (areaType == "vierkante meters") {
                              // Only allow full integers
                              final intRegex = RegExp(r'^\d+$');
                              if (intRegex.hasMatch(value)) {
                                parsed = double.tryParse(value);
                                isValid = parsed != null;
                              }
                            } else if (areaType == "hectare") {
                              // Allow decimals with comma or dot
                              final decimalRegex = RegExp(r'^\d+([.,]\d+)?$');
                              if (decimalRegex.hasMatch(cleanedValue)) {
                                parsed = double.tryParse(cleanedValue);
                                isValid = parsed != null;
                              }
                            }

                            if (isValid) {
                              setState(() {
                                belongingDamageReportProvider
                                    .resetInputErrorImpactArea(); // Clear the error if the input is valid
                              });
                              _belongingDamageReportManager.updateImpactedArea(
                                parsed!,
                              );
                              belongingDamageReportProvider
                                  .setHasErrorImpactedArea(
                                    false,
                                  ); // Clear error in provider
                            } else {
                              // Only show 'This field is required' when input is empty
                              setState(() {
                                if (value.isNotEmpty &&
                                    areaType != "vierkante meters" &&
                                    areaType != "hectare") {
                                  debugPrint(
                                    "$greenLog [GewasschadeDetails]: Line 198",
                                  );
                                  belongingDamageReportProvider
                                      .updateInputErrorImpactArea(
                                        "Vul Getroffen Gebied in",
                                      );
                                } else if (value.isEmpty) {
                                  debugPrint(
                                    "$greenLog [GewasschadeDetails]: Line 197, value = $value",
                                  );
                                  belongingDamageReportProvider
                                      .resetImpactedArea();
                                  belongingDamageReportProvider
                                      .updateInputErrorImpactArea(
                                        "This field is required",
                                      ); // Show error if the input is empty
                                } else {
                                  belongingDamageReportProvider
                                      .updateInputErrorImpactArea(
                                        areaType == "vierkante meters"
                                            ? "Alleen gehele getallen toegestaan"
                                            : "Gebruik een geldig getal (bv. 1,5 of 1.5)",
                                      );
                                }
                              });
                              belongingDamageReportProvider
                                  .setHasErrorImpactedArea(
                                    true,
                                  ); // Set error in provider
                            }
                          },
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'hoe groot',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  (belongingDamageReportProvider
                                                  .inputErrorImpactArea !=
                                              null ||
                                          belongingDamageReportProvider
                                              .hasErrorImpactedArea)
                                      ? const BorderSide(
                                        color: Colors.red,
                                        width: 2.0,
                                      )
                                      : BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  (belongingDamageReportProvider
                                                  .inputErrorImpactArea !=
                                              null ||
                                          belongingDamageReportProvider
                                              .hasErrorImpactedArea)
                                      ? const BorderSide(
                                        color: Colors.red,
                                        width: 2.0,
                                      )
                                      : BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  (belongingDamageReportProvider
                                                  .inputErrorImpactArea !=
                                              null ||
                                          belongingDamageReportProvider
                                              .hasErrorImpactedArea)
                                      ? const BorderSide(
                                        color: Colors.red,
                                        width: 2.0,
                                      )
                                      : BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.brown,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      belongingDamageReportProvider.hasErrorImpactedArea
                          ? Text(
                            belongingDamageReportProvider
                                    .inputErrorImpactArea ??
                                'This field is required',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          )
                          : const SizedBox.shrink(), // invisible when no error
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "Geschatte huidige schade: ${euroFormat.format(belongingDamageReportProvider.currentDamage)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Slider(
                      key: const Key('estimated-damage'),
                      value: belongingDamageReportProvider.currentDamage,
                      onChanged:
                          (value) => _belongingDamageReportManager
                              .updateCurrentDamage(value),
                      min: 0,
                      max: 10000,
                      divisions: 1000, // so each step is €10
                      label:
                          belongingDamageReportProvider.currentDamage
                              .round()
                              .toString(),
                      activeColor: AppColors.brown,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "Verwachte toekomstige schade: ${euroFormat.format(belongingDamageReportProvider.expectedDamage)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Slider(
                      key: const Key('estimated-future-damage'),
                      value: belongingDamageReportProvider.expectedDamage,
                      onChanged:
                          (value) => _belongingDamageReportManager
                              .updateExpectedDamage(value),
                      min: 0,
                      max: 10000,
                      divisions: 1000, // so each step is €10
                      label:
                          belongingDamageReportProvider.expectedDamage
                              .round()
                              .toString(),
                      activeColor: AppColors.brown,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: TextField(
                      key: const Key('description'),
                      controller: _descriptionController,
                      onChanged:
                          (val) => _belongingDamageReportManager
                              .updateDescription(val),
                      maxLines: 5,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'opmerkingen...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.brown,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}