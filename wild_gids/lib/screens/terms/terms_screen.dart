import 'package:wildrapport/widgets/shared_ui_widgets/white_bulk_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wildrapport/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildrapport/models/beta_models/profile_model.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:wildrapport/screens/shared/overzicht_screen.dart';
import 'package:wildrapport/utils/responsive_utils.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _checked = false;
  bool _submitting = false;
  bool _loadingProfile = true;

  final TextEditingController _displayNameController = TextEditingController();
  Profile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadInitialProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialProfile() async {
    try {
      final profileApi = context.read<ProfileApiInterface>();
      final profile = await profileApi.fetchMyProfile();
      if (!mounted) return;
      _currentProfile = profile;

      // Prefer existing display name, otherwise derive from email prefix
      final email = profile.email;
      final derived = (email.contains('@'))
          ? email.split('@').first
          : email;
      final initialName = (profile.userName.isNotEmpty)
          ? profile.userName
          : derived;
      _displayNameController.text = initialName;
    } catch (_) {
      // Fallback: leave empty; user must fill manually
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _onAcceptPressed() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final profileApi = context.read<ProfileApiInterface>();

      final newName = _displayNameController.text.trim();
      if (newName.isEmpty) {
        throw Exception('Voer alstublieft een geldige gebruikersnaam in.');
      }

      // Build updated profile payload, preserving existing fields when available
      final base = _currentProfile;
      final updated = Profile(
        userID: base?.userID ?? '',
        email: base?.email ?? '',
        gender: base?.gender,
        userName: newName,
        postcode: base?.postcode,
        reportAppTerms: true,
        recreationAppTerms: base?.recreationAppTerms,
        dateOfBirth: base?.dateOfBirth,
        description: base?.description,
        location: base?.location,
        locationTimestamp: base?.locationTimestamp,
      );

      // 1) Persist display name + acceptance on the server
      await profileApi.updateMyProfile(updated);

      // 2) Refresh local cache (defensive; updateMyProfile also caches)
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
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: AppColors.lightMintGreen,
      appBar: AppBar(
        title: Text(
          'Algemene Voorwaarden',
          style: TextStyle(fontSize: responsive.fontSize(18)),
        ),
        backgroundColor: AppColors.lightMintGreen,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(16)),
          child: Column(
            children: [
              // Display name input
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gebruikersnaam',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(6)),
              TextField(
                controller: _displayNameController,
                enabled: !_submitting && !_loadingProfile,
                decoration: InputDecoration(
                  hintText: 'Voer uw weergavenaam in',
                  filled: true,
                  fillColor: AppColors.lightMintGreen100,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.brown),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.darkGreen),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(10),
                    horizontal: responsive.spacing(12),
                  ),
                ),
                style: TextStyle(fontSize: responsive.fontSize(14)),
              ),
              SizedBox(height: responsive.spacing(12)),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Algemene Voorwaarden\n\n'
                    'Deze app wordt geleverd door WildlifeNL om wildlifemelding te vergemakkelijken. Door gebruik te maken van deze app, gaat u ermee akkoord dat u zich houdt aan alle toepasselijke wet- en regelgeving met betrekking tot de bescherming van wilde dieren en gegevensprivacy. U erkent dat alle gegevens die u via deze app indient, door WildlifeNL kunnen worden gebruikt voor onderzoeksdoeleinden.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Transform.scale(
                    scale: responsive.sp(0.15),
                    child: Checkbox(
                      value: _checked,
                      activeColor: AppColors.darkGreen,
                      onChanged:
                          _submitting
                              ? null
                              : (v) => setState(() => _checked = v ?? false),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Ik heb de Algemene Voorwaarden gelezen en accepteer deze',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: responsive.fontSize(14),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(8)),
              SizedBox(
                width: double.infinity,
                child: WhiteBulkButton(
                  text: 'Accepteren & Doorgaan',
                  showIcon: false,
                  backgroundColor: AppColors.lightMintGreen100,
                  borderColor: AppColors.brown,
                  textStyle: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.black,
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed:
                      (_checked && !_submitting && !_loadingProfile) ? _onAcceptPressed : null,
                  showShadow: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
