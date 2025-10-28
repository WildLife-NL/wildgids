import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildrapport/screens/belonging/belonging_animal_screen.dart';
import 'package:wildrapport/widgets/shared_ui_widgets/white_bulk_button.dart';

class SuspectedAnimal extends StatefulWidget {
  const SuspectedAnimal({super.key});

  @override
  State<StatefulWidget> createState() => _SuspectedAnimalState();
}

class _SuspectedAnimalState extends State<SuspectedAnimal> {
  late final BelongingDamageReportInterface _belongingDamageReportManager;

  @override
  void initState() {
    super.initState();
    _belongingDamageReportManager =
        context.read<BelongingDamageReportInterface>();
  }

  Future<dynamic> pressed(String animalType) {
    _belongingDamageReportManager.updateSuspectedAnimal(animalType);
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => const BelongingAnimalScreen(appBarTitle: 'Kies Dier'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: MediaQuery.of(context).size.height * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40), // Optional spacing at top
              _buildButton(
                text: "Onbekend",
                image: Image.asset("assets/icons/questionnaire/arrow_forward.png"),
                height: 63,
                width: 200,
                onPressed: () => pressed("Onbekend"),
              ),
              const SizedBox(height: 24),
              _buildButton(
                text: "Vogels",
                image: Image.asset("assets/icons/questionnaire/arrow_forward.png"),
                height: 63,
                width: 277,
                onPressed: () => pressed("Vogels"),
              ),
              const SizedBox(height: 24),
              _buildButton(
                text: "Knaagdieren",
                image: Image.asset("assets/icons/questionnaire/arrow_forward.png"),
                height: 70,
                width: 339,
                onPressed: () => pressed("Knaagdieren"),
              ),
              const SizedBox(height: 24),
              _buildButton(
                text: "Evenhoevigen",
                image: Image.asset("assets/icons/questionnaire/arrow_forward.png"),
                height: 70,
                width: 339,
                onPressed: () => pressed("Evenhoevigen"),
              ),
              const SizedBox(height: 40), // Optional bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Image image,
    double? height,
    double? width,
    VoidCallback? onPressed,
  }) {
    return WhiteBulkButton(
      text: text,
      rightWidget: SizedBox(width: 24, height: 24, child: image),
      onPressed: onPressed,
    );
  }
}