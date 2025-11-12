import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wildrapport/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/widgets/overlay/error_overlay.dart';

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
      showDialog(
        context: context,
        builder: (_) => const ErrorOverlay(
          messages: [
            'Kan voorwaarden niet accepteren',
            'Controleer je internetverbinding en probeer het opnieuw.',
          ],
        ),
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
        title: const Text('Terms & Conditions'),
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
                    'Here are the Terms & Conditions...\n\n'
                    'This app is provided by WildlifeNL to facilitate wildlife reporting. By using this app, you agree to comply with all applicable laws and regulations regarding wildlife protection and data privacy. You acknowledge that any data you submit through this app may be used by WildlifeNL for research purposes.',
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
                      'I have read and accept the Terms & Conditions',
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
                      : const Text('Accept & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
