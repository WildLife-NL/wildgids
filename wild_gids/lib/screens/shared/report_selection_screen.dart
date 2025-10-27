import 'package:flutter/material.dart';
import 'package:widgets/widgets/shared_ui_widgets/app_bar.dart';
import 'package:widgets/screens/shared/category_screen.dart';

class ReportSelectionScreen extends StatelessWidget {
  const ReportSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(
              centerText: 'Rapporteren',
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const CategoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Waarneming melden'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5016),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // If you later re-enable other flows, add buttons here.
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
