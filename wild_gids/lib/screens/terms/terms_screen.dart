import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:widgets/interfaces/data_apis/profile_api_interface.dart';

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

      // 3) Navigate to waarneming flow (CategoryScreen)
      Navigator.of(context).pushNamedAndRemoveUntil('/category', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept terms: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Here are the Terms & Conditions...\n\n'
                    '1) ...\n2) ...\n3) ...',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _checked,
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _checked = v ?? false),
                  ),
                  const Expanded(
                    child: Text('I have read and accept the Terms & Conditions'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_checked && !_submitting) ? _onAcceptPressed : null,
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
