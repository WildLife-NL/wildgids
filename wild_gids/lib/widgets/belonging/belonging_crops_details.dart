import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    
    // Initialize controllers with proper text values
    final impactAreaString = formatImpactAreaString();
    final initialImpact = (impactAreaString.isNotEmpty && impactAreaString != "0" && impactAreaString != "0.0") 
        ? impactAreaString 
        : '';
    _impactValueController = TextEditingController(text: initialImpact);
    
    final initialDescription = belongingDamageReportProvider.description.isNotEmpty 
        ? belongingDamageReportProvider.description 
        : '';
    _descriptionController = TextEditingController(text: initialDescription);
    
    final initialCurrentDamage = belongingDamageReportProvider.currentDamage > 0 
        ? belongingDamageReportProvider.currentDamage.round().toString() 
        : '';
    _currentDamageController = TextEditingController(text: initialCurrentDamage);
    
    final initialExpectedDamage = belongingDamageReportProvider.expectedDamage > 0 
        ? belongingDamageReportProvider.expectedDamage.round().toString() 
        : '';
    _expectedDamageController = TextEditingController(text: initialExpectedDamage);
  }
  
  @override
  void dispose() {
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
                  containerHeight: 40,
                  containerWidth: 150,
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
                        decoration: const BoxDecoration(),
                        child: TextField(
                          key: const Key('area-value'),
                          controller: _impactValueController,
                          onChanged: (value) {
                            debugPrint(value);
                            
                            // Handle empty input
                            if (value.isEmpty) {
                              setState(() {
                                belongingDamageReportProvider.resetImpactedArea();
                                belongingDamageReportProvider.updateInputErrorImpactArea('This field is required');
                                belongingDamageReportProvider.setHasErrorImpactedArea(true);
                              });
                              return;
                            }
                            
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
                                      : const BorderSide(
                                        color: AppColors.darkGreen,
                                        width: 2.0,
                                      ),
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
                                      : const BorderSide(
                                        color: AppColors.darkGreen,
                                        width: 2.0,
                                      ),
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
                                      : const BorderSide(
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
                      const SizedBox(height: 5),
                      belongingDamageReportProvider.hasErrorImpactedArea
                          ? Text(
                            belongingDamageReportProvider
                                    .inputErrorImpactArea ??
                                'This field is required',
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'Roboto'),
                          )
                          : const SizedBox.shrink(), // invisible when no error
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Geschatte huidige schade",
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto', fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: const BoxDecoration(),
                        child: TextField(
                          key: const Key('estimated-damage'),
                          controller: _currentDamageController,
                          onChanged: (value) {
                            if (value.isEmpty) {
                              _belongingDamageReportManager.updateCurrentDamage(0);
                            } else {
                              final parsed = double.tryParse(value);
                              if (parsed != null) {
                                _belongingDamageReportManager.updateCurrentDamage(parsed);
                              }
                            }
                          },
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Bedrag in €',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Verwachte toekomstige schade",
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Roboto', fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: const BoxDecoration(),
                        child: TextField(
                          key: const Key('estimated-future-damage'),
                          controller: _expectedDamageController,
                          onChanged: (value) {
                            if (value.isEmpty) {
                              _belongingDamageReportManager.updateExpectedDamage(0);
                            } else {
                              final parsed = double.tryParse(value);
                              if (parsed != null) {
                                _belongingDamageReportManager.updateExpectedDamage(parsed);
                              }
                            }
                          },
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Bedrag in €',
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
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: const BoxDecoration(),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
