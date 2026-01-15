import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/models/beta_models/profile_model.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile initialProfile;

  const EditProfileScreen({
    super.key,
    required this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _postcodeController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _descriptionController;
  String? _selectedGender;
  bool _isLoading = false;

  final List<String> _genderOptions = ['female', 'male', 'other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.userName);
    _postcodeController = TextEditingController(text: widget.initialProfile.postcode ?? '');
    
    // Handle dateOfBirth - extract YYYY-MM-DD from ISO 8601 if needed
    String dateOfBirthStr = '';
    if (widget.initialProfile.dateOfBirth != null && widget.initialProfile.dateOfBirth!.isNotEmpty) {
      dateOfBirthStr = widget.initialProfile.dateOfBirth!.contains('T')
          ? widget.initialProfile.dateOfBirth!.split('T')[0]
          : widget.initialProfile.dateOfBirth!;
    }
    _dateOfBirthController = TextEditingController(text: dateOfBirthStr);
    
    _descriptionController = TextEditingController(text: widget.initialProfile.description ?? '');
    _selectedGender = widget.initialProfile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _postcodeController.dispose();
    _dateOfBirthController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? initialDate;
    
    if (_dateOfBirthController.text.isNotEmpty) {
      try {
        // Handle both formats: YYYY-MM-DD and ISO 8601
        String dateStr = _dateOfBirthController.text;
        if (dateStr.contains('T')) {
          // ISO 8601 format: 2001-10-29T00:00:00Z
          dateStr = dateStr.split('T')[0];
        }
        initialDate = DateTime.parse(dateStr);
      } catch (e) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        // Format as YYYY-MM-DD
        _dateOfBirthController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _nameController.text.length < 2) {
      _showErrorSnackBar('Naam moet minstens 2 karakters lang zijn');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profileApi = context.read<ProfileApiInterface>();

      final updatedProfile = Profile(
        userID: widget.initialProfile.userID,
        email: widget.initialProfile.email,
        userName: _nameController.text,
        postcode: _postcodeController.text.isNotEmpty ? _postcodeController.text : null,
        gender: _selectedGender,
        dateOfBirth: _dateOfBirthController.text.isNotEmpty ? _dateOfBirthController.text : null,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        reportAppTerms: widget.initialProfile.reportAppTerms,
        recreationAppTerms: widget.initialProfile.recreationAppTerms,
        location: widget.initialProfile.location,
        locationTimestamp: widget.initialProfile.locationTimestamp,
      );

      await profileApi.updateMyProfile(updatedProfile);

      if (!mounted) return;
      _showSuccessSnackBar('Profiel succesvol bijgewerkt');

      // Navigate back after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pop(updatedProfile);
    } catch (e) {
      _showErrorSnackBar('Fout bij bijwerken: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.wp(4)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.only(top: responsive.hp(1)),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.offWhite,
                      iconSize: responsive.sp(3),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Profiel Bijwerken',
                          style: TextStyle(
                            color: AppColors.offWhite,
                            fontSize: responsive.fontSize(24),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.wp(12)),
                  ],
                ),
              ),

              SizedBox(height: responsive.spacing(24)),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      _buildLabel(responsive, 'Naam *'),
                      SizedBox(height: responsive.spacing(8)),
                      _buildTextField(
                        responsive,
                        _nameController,
                        'Voer uw naam in',
                        minLength: 2,
                      ),

                      SizedBox(height: responsive.spacing(20)),

                      // Gender dropdown
                      _buildLabel(responsive, 'Geslacht'),
                      SizedBox(height: responsive.spacing(8)),
                      _buildGenderDropdown(responsive),

                      SizedBox(height: responsive.spacing(20)),

                      // Date of birth field
                      _buildLabel(responsive, 'Geboortedatum'),
                      SizedBox(height: responsive.spacing(8)),
                      _buildDateField(responsive),

                      SizedBox(height: responsive.spacing(20)),

                      // Postcode field
                      _buildLabel(responsive, 'Postcode'),
                      SizedBox(height: responsive.spacing(8)),
                      _buildTextField(
                        responsive,
                        _postcodeController,
                        'Voer uw postcode in',
                      ),

                      SizedBox(height: responsive.spacing(20)),

                      // Description field
                      _buildLabel(responsive, 'Beschrijving'),
                      SizedBox(height: responsive.spacing(8)),
                      _buildTextField(
                        responsive,
                        _descriptionController,
                        'Voer een beschrijving in',
                        maxLines: 4,
                      ),

                      SizedBox(height: responsive.spacing(32)),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                              (states) {
                                if (states.contains(MaterialState.hovered) ||
                                    states.contains(MaterialState.pressed)) {
                                  return AppColors.lightGreen;
                                }
                                return AppColors.lightMintGreen;
                              },
                            ),
                            foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                              (states) {
                                if (states.contains(MaterialState.hovered) ||
                                    states.contains(MaterialState.pressed)) {
                                  return AppColors.offWhite;
                                }
                                return AppColors.black;
                              },
                            ),
                            padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(vertical: responsive.hp(1.75)),
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(responsive.sp(3)),
                              ),
                            ),
                          ),
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Opslaan',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: responsive.spacing(20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(ResponsiveUtils responsive, String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.offWhite,
        fontSize: responsive.fontSize(14),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField(
    ResponsiveUtils responsive,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    int minLength = 0,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : maxLines,
      style: TextStyle(
        color: AppColors.black,
        fontSize: responsive.fontSize(14),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: responsive.fontSize(14),
        ),
        filled: true,
        fillColor: AppColors.lightMintGreen,
        contentPadding: EdgeInsets.symmetric(
          horizontal: responsive.wp(3),
          vertical: responsive.hp(1),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.sp(2)),
          borderSide: const BorderSide(color: AppColors.lightMintGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.sp(2)),
          borderSide: const BorderSide(color: AppColors.lightMintGreen),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.sp(2)),
          borderSide: BorderSide(
            color: AppColors.darkGreen,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(ResponsiveUtils responsive) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.wp(3),
          vertical: responsive.hp(1),
        ),
        decoration: BoxDecoration(
          color: AppColors.lightMintGreen,
          borderRadius: BorderRadius.circular(responsive.sp(2)),
          border: Border.all(color: AppColors.lightMintGreen),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _dateOfBirthController.text.isEmpty
                  ? 'Selecteer geboortedatum'
                  : _dateOfBirthController.text,
              style: TextStyle(
                color: _dateOfBirthController.text.isEmpty
                    ? Colors.grey[600]
                    : AppColors.black,
                fontSize: responsive.fontSize(14),
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: AppColors.darkGreen,
              size: responsive.sp(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: responsive.wp(3)),
      decoration: BoxDecoration(
        color: AppColors.lightMintGreen,
        borderRadius: BorderRadius.circular(responsive.sp(2)),
        border: Border.all(color: AppColors.lightMintGreen),
      ),
      child: DropdownButton<String>(
        value: _selectedGender,
        hint: Text(
          'Selecteer geslacht',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: responsive.fontSize(14),
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedGender = newValue;
          });
        },
        items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                color: AppColors.black,
                fontSize: responsive.fontSize(14),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

