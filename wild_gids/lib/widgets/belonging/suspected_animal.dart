import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildrapport/interfaces/reporting/belonging_damage_report_interface.dart';
import 'package:wildrapport/screens/belonging/belonging_animal_screen.dart';
import 'package:wildrapport/widgets/location/selection_button_group.dart';

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

  void _handleCategorySelection(String category) {
    _belongingDamageReportManager.updateSuspectedAnimal(category);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => const BelongingAnimalScreen(appBarTitle: 'Kies Dier'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionButtonGroup(
      buttons: const [
        (
          text: 'Evenhoevigen',
          icon: null,
          imagePath: 'assets/icons/category/evenhoevigen.png',
        ),
        (
          text: 'Knaagdieren',
          icon: null,
          imagePath: 'assets/icons/category/knaagdieren.png',
        ),
        (
          text: ' Roofdieren',
          icon: Icons.flutter_dash, // Using icon since no vogels.png exists
          imagePath: null,
        ),
        (text: 'Onbekend', icon: Icons.more_horiz, imagePath: null),
      ],
      onStatusSelected: _handleCategorySelection,
      title: 'Selecteer Categorie',
    );
  }
}
