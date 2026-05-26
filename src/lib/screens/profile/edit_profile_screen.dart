import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wildgids/interfaces/data_apis/profile_api_interface.dart';
import 'package:wildgids/models/beta_models/profile_model.dart';
import 'package:wildgids/utils/responsive_utils.dart';
import 'package:wildgids/utils/text_display_utils.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile initialProfile;

  const EditProfileScreen({
    super.key,
    required this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

String _genderLabelNl(String? apiValue) {
  switch (apiValue?.toLowerCase()) {
    case 'male':
      return 'man';
    case 'female':
      return 'vrouw';
    case 'other':
      return 'anders';
    default:
      return apiValue ?? '';
  }
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _postcodeController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _notesController;
  late TextEditingController _natureVisitFrequencyController;
  String? _selectedGender;
  bool _isLoading = false;

  /// API-waarden (Engels); we tonen Nederlandse labels.
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
    
    _notesController = TextEditingController(text: widget.initialProfile.notes ?? '');
    _natureVisitFrequencyController = TextEditingController(
      text: widget.initialProfile.natureVisitFrequency?.toString() ?? '',
    );
    _selectedGender = widget.initialProfile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _postcodeController.dispose();
    _dateOfBirthController.dispose();
    _notesController.dispose();
    _natureVisitFrequencyController.dispose();
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

  int? _parseNatureVisitFrequencyInput() {
    final text = _natureVisitFrequencyController.text.trim();
    if (text.isEmpty) {
      return widget.initialProfile.natureVisitFrequency;
    }
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _nameController.text.length < 2) {
      _showErrorSnackBar('Naam moet minstens 2 karakters lang zijn');
      return;
    }

    final natureVisitFrequency = _parseNatureVisitFrequencyInput();
    if (_natureVisitFrequencyController.text.trim().isNotEmpty &&
        natureVisitFrequency == null) {
      _showErrorSnackBar('Natuurbezoekfrequentie moet een geheel getal â‰¥ 0 zijn');
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
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        natureVisitFrequency: _parseNatureVisitFrequencyInput(),
        reportAppTerms: widget.initialProfile.reportAppTerms,
        recreationAppTerms: widget.initialProfile.recreationAppTerms,
        firebaseCloudMessagingToken:
            widget.initialProfile.firebaseCloudMessagingToken,
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
    final fs = responsive.fontSize;

    return Scaffold(
      backgroundColor: Color(0XFFF5F6F4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    color: Colors.grey.shade900,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 16),
                // Card content
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: Color(0xFFB2B2B2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    color: Colors.white,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        // Full Name
                        Text(
                          'Volledige naam',
                          style: TextStyle(
                            fontSize: fs(13),
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          responsive,
                          _nameController,
                          'Mila Pulvirenti',
                        ),
                        const SizedBox(height: 16),

                        // Email
                        Text(
                          'Email adres',
                          style: TextStyle(
                            fontSize: fs(13),
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Tooltip(
                            message: widget.initialProfile.email,
                            waitDuration: const Duration(milliseconds: 400),
                            child: Text(
                              truncateEmail(
                                widget.initialProfile.email,
                                maxLength: 36,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: fs(15),
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Role Dropdown
                        Text(
                          'Rol',
                          style: TextStyle(
                            fontSize: fs(13),
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGenderDropdown(responsive),
                        const SizedBox(height: 16),

                        // Postcode
                        Text(
                          'Postcode',
                          style: TextStyle(
                            fontSize: fs(13),
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          responsive,
                          _postcodeController,
                          '1234AB',
                        ),
                        const SizedBox(height: 16),

                        // Birth Date
                        Text(
                          'Geboortedatum',
                          style: TextStyle(
                            fontSize: fs(13),
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDateField(responsive),
                        const SizedBox(height: 16),

                        Text(
                          'Natuurbezoek per week',
                          style: TextStyle(
                            fontSize: fs(13),
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          responsive,
                          _natureVisitFrequencyController,
                          '0',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Notities',
                          style: TextStyle(
                            fontSize: fs(13),
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          responsive,
                          _notesController,
                          'Optionele notities',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        FilledButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.grey.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                          ),
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
                                    fontSize: fs(15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    ResponsiveUtils responsive,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : maxLines,
      style: TextStyle(
        color: Colors.grey.shade900,
        fontSize: responsive.fontSize(15),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: responsive.fontSize(15),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: const Color(0xFF37A904),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(ResponsiveUtils responsive) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
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
                    ? Colors.grey.shade500
                    : Colors.grey.shade900,
                fontSize: responsive.fontSize(15),
              ),
            ),
            Icon(
              Icons.expand_more,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(ResponsiveUtils responsive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedGender,
        hint: Text(
          'Selecteer geslacht',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: responsive.fontSize(15),
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
              _genderLabelNl(value),
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: responsive.fontSize(15),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

