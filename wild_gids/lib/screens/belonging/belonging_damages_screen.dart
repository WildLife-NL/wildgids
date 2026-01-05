import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/state/navigation_state_interface.dart';
import 'package:wildrapport/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildrapport/providers/belonging_damage_report_provider.dart';
import 'package:wildrapport/screens/belonging/belonging_animal_screen.dart';
import 'package:wildrapport/screens/belonging/belonging_location_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/app_bar.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/bottom_app_bar.dart';
import 'package:wildrapport/widgets/location/invisible_map_preloader.dart';

class BelongingDamagesScreen extends StatefulWidget {
  const BelongingDamagesScreen({super.key});

  @override
  State<BelongingDamagesScreen> createState() => _PossesionDamageScreenState();
}

class _PossesionDamageScreenState extends State<BelongingDamagesScreen> {
  late final BelongingDamageReportInterface _belongingDamageReportManager;
  late List<dynamic> belongingDamagesWidgetList;
  late int currentIndex;
  late int maxIndex;

  @override
  void initState() {
    super.initState();
    _belongingDamageReportManager =
        context.read<BelongingDamageReportInterface>();
    _loadPossesionWidgets();
    currentIndex = 0;
    maxIndex = belongingDamagesWidgetList.length - 1;
  }

  bool validateImpactedCrop(BelongingDamageReportProvider formProvider) {
    bool isValid = true;
    if (formProvider.impactedCrop.isEmpty) {
      isValid = false;
      debugPrint("impactedCrop has error");
      formProvider.setErrorState('impactedCrop', true);
      return isValid;
    } else {
      return isValid;
    }
  }

  bool validateImpactedAreaType(BelongingDamageReportProvider formProvider) {
    bool isValid = true;
    if (formProvider.impactedAreaType.isEmpty) {
      isValid = false;
      debugPrint("impactedAreaType has error");
      formProvider.setErrorState('impactedAreaType', true);
      return isValid;
    } else {
      return isValid;
    }
  }

  bool validateImpactedArea(BelongingDamageReportProvider formProvider) {
    bool isValid = true;
    debugPrint("${formProvider.impactedArea}");

    debugPrint("validateImpactedArea: ${formProvider.hasErrorImpactedArea}");
    debugPrint("validateImpactedArea: ${formProvider.impactedAreaType}");

    // For crops damage: validate polygon area with minimum 3 points
    if (formProvider.damageCategory == 'crops') {
      if (formProvider.polygonArea == null || 
          formProvider.polygonArea!.points.isEmpty ||
          formProvider.polygonArea!.points.length < 3) {
        isValid = false;
        debugPrint("Polygon area invalid or has fewer than 3 points");
        formProvider.setErrorState('impactedArea', true);
        return isValid;
      }
      return isValid;
    }

    // For livestock damage: validate amount > 0
    if (formProvider.damageCategory == 'livestock') {
      if (formProvider.livestockAmount == null || formProvider.livestockAmount! <= 0) {
        isValid = false;
        debugPrint("Livestock amount invalid");
        formProvider.setErrorState('impactedArea', true);
        return isValid;
      }
      return isValid;
    }

    // Legacy validation for when damage category is not set
    if (formProvider.impactedArea == null) {
      isValid = false;
      debugPrint("impactedArea has error");
      formProvider.setErrorState('impactedArea', true);
      //formProvider.updateInputErrorImpactArea("This field is required");
      return isValid;
    } else if (formProvider.hasErrorImpactedArea &&
        formProvider.impactedAreaType == "vierkante meters") {
      debugPrint(
        "formProvider.hasErrorImpactedArea && formProvider.impactedAreaType == vierkante meters",
      );
      isValid = false;
      formProvider.updateInputErrorImpactArea(
        "Alleen gehele getallen toegestaan",
      );
      return isValid;
    } else {
      debugPrint("isValid");
      return isValid;
    }
  }

  // Method to check if all required fields are filled
  bool validateForm() {
    final formProvider = Provider.of<BelongingDamageReportProvider>(
      context,
      listen: false,
    );
    //formProvider.resetErrors();

    bool isValid = true;
    bool isValidImpactedCrop = true;
    bool isValidImpactedAreaType = true;
    bool isValidImpactedArea = true;

    // Check if each required field is filled
    isValidImpactedCrop = validateImpactedCrop(formProvider);
    isValidImpactedAreaType = validateImpactedAreaType(formProvider);
    isValidImpactedArea = validateImpactedArea(formProvider);

    if (isValidImpactedCrop == false ||
        isValidImpactedAreaType == false ||
        isValidImpactedArea == false) {
      isValid = false;
    }

    return isValid;
  }

  void nextScreen() {
    if (validateForm()) {
      final provider = Provider.of<BelongingDamageReportProvider>(
        context,
        listen: false,
      );
      provider.resetInputErrorImpactArea();
      provider.hasErrorImpactedArea = false;
      debugPrint("Form is valid!");
      if (currentIndex < maxIndex) {
        setState(() {
          currentIndex++;
        });
      } else {
        // Navigate to BelongingLocationScreen when form is complete
        final navigationManager = context.read<NavigationStateInterface>();
        navigationManager.pushReplacementForward(
          context,
          const BelongingLocationScreen(),
        );
      }
    } else {
      // Handle invalid form state, display error messages, or highlight fields
      debugPrint("Form is not valid!!!");
      setState(() {
        // Optionally trigger state changes to show inline errors
      });
    }
  }

  void previousScreen() {
    if (currentIndex > 0) {
      // When navigating back to the first page, clear all entered values so the form restarts
      if (currentIndex == 1) {
        final provider = Provider.of<BelongingDamageReportProvider>(
          context,
          listen: false,
        );
        provider.clearStateOfValues();
        provider.resetErrors();
      }
      setState(() {
        currentIndex--;
      });
    } else {
      final provider = Provider.of<BelongingDamageReportProvider>(
        context,
        listen: false,
      );
      final navigationManager = context.read<NavigationStateInterface>();
      provider.clearStateOfValues();
      provider.resetErrors();
      navigationManager.pushReplacementBack(context, const BelongingAnimalScreen(appBarTitle: 'Selecteer Dier'));
    }
  }

  void _loadPossesionWidgets() {
    final widgetList = _belongingDamageReportManager.buildPossesionWidgetList();
    setState(() {
      belongingDamagesWidgetList = widgetList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leftIcon: null,
              centerText: "Schademelding",
              rightIcon: null,
              showUserIcon: true,
              iconColor: Colors.black,
              textColor: Colors.black,
              fontScale: 1.15,
              iconScale: 1.15,
              userIconScale: 1.15,
            ),
            Expanded(child: belongingDamagesWidgetList[currentIndex]),
            CustomBottomAppBar(
              onNextPressed: nextScreen,
              onBackPressed: previousScreen,
              showNextButton: currentIndex < 1,
              showBackButton: true,
            ),
            const InvisibleMapPreloader(),
          ],
        ),
      ),
    );
  }
}
