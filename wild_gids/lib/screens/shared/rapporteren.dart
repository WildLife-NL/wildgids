import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/state/navigation_state_interface.dart';
import 'package:wildgids/models/enums/report_type.dart';
import 'package:wildgids/providers/app_state_provider.dart';
import 'package:wildgids/screens/waarneming/waarneming_start_screen.dart';

class Rapporteren extends StatefulWidget {
  const Rapporteren({super.key});

  @override
  State<Rapporteren> createState() => _RapporterenState();
}

class _RapporterenState extends State<Rapporteren> {
  String selectedCategory = '';
  bool _hasLoadedTypes = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedTypes) {
      _hasLoadedTypes = true;
      // Skip directly to waarneming start screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigationManager = context.read<NavigationStateInterface>();
        final appStateProvider = context.read<AppStateProvider>();
        
        // Initialize the report in the app state
        appStateProvider.initializeReport(ReportType.waarneming);
        
        // Navigate directly to waarneming start screen
        navigationManager.pushForward(context, const WaarnemmingStartScreen());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen navigates to WaarnemmingStartScreen immediately
    // Show a simple loading screen while the navigation happens
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

