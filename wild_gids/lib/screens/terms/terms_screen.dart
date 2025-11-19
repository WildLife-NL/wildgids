import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wildrapport/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _checked = false;
  bool _submitting = false;

  Future<void> _onAcceptPressed() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final profileApi = context.read<ProfileApiInterface>();

      // 1) Persist acceptance on the server
      await profileApi.updateReportAppTerms(true);

      // 2) (Optional) Pull fresh profile to update local cache
      // If your API already caches in updateReportAppTerms, you can skip this.
      await profileApi.setProfileDataInDeviceStorage();

      if (!mounted) return;

      // 3) Navigate to the home screen (no local flags involved)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OverzichtScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kon voorwaarden niet accepteren: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      appBar: AppBar(
        title: const Text('Algemene Voorwaarden'),
        backgroundColor: AppColors.lightMintGreen,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Algemene Voorwaarden\n\n'
                    'Deze app wordt geleverd door WildlifeNL om wildlifemelding te vergemakkelijken. Door gebruik te maken van deze app, gaat u ermee akkoord dat u zich houdt aan alle toepasselijke wet- en regelgeving met betrekking tot de bescherming van wilde dieren en gegevensprivacy. U erkent dat alle gegevens die u via deze app indient, door WildlifeNL kunnen worden gebruikt voor onderzoeksdoeleinden.',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _checked,
                    activeColor: AppColors.darkGreen,
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _checked = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Ik heb de Algemene Voorwaarden gelezen en accepteer deze',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_checked && !_submitting) ? _onAcceptPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accepteren & Doorgaan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
