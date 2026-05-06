import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    String dateOfBirthStr = '';
    if (widget.initialProfile.dateOfBirth != null &&
        widget.initialProfile.dateOfBirth!.isNotEmpty) {
      String raw = widget.initialProfile.dateOfBirth!;
      if (raw.contains('T')) {
        raw = raw.split('T')[0];
      }
      dateOfBirthStr = _formatDateForDisplay(raw);
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

  String _formatDateForDisplay(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return yyyyMmDd;
  }

  String _formatDateForApi(String ddMmYyyy) {
    final parts = ddMmYyyy.split('-');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return ddMmYyyy;
  }

  Future<void> _selectDate() async {
    DateTime? initialDate;

    if (_dateOfBirthController.text.isNotEmpty) {
      try {
        String dateStr = _dateOfBirthController.text;
        if (dateStr.contains('T')) {
          dateStr = dateStr.split('T')[0];
        }
        if (dateStr.contains('-')) {
          final parts = dateStr.split('-');
          if (parts.length == 3 && parts[0].length == 2) {
            dateStr = '${parts[2]}-${parts[1]}-${parts[0]}';
          }
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
        _dateOfBirthController.text =
            '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
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
        dateOfBirth: _dateOfBirthController.text.isNotEmpty
            ? _formatDateForApi(_dateOfBirthController.text)
            : null,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        reportAppTerms: widget.initialProfile.reportAppTerms,
        recreationAppTerms: widget.initialProfile.recreationAppTerms,
        location: widget.initialProfile.location,
        locationTimestamp: widget.initialProfile.locationTimestamp,
      );

      await profileApi.updateMyProfile(updatedProfile);

      if (!mounted) return;
      _showSuccessSnackBar('Profiel succesvol bijgewerkt');
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
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool compact = constraints.maxHeight < 760;
            final double topGap = compact ? 6 : 10;
            final double midGap = compact ? 8 : 10;
            final double buttonHeight = compact ? 56 : 64;
            final double avatarSize = compact ? 44 : 52;

            return Padding(
              padding: EdgeInsets.fromLTRB(14, topGap, 14, compact ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(14, compact ? 8 : 10, 14, compact ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: compact ? 18 : 20,
                            color: const Color(0xFF111827),
                          ),
                          splashRadius: 20,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F1F1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, size: compact ? 22 : 26, color: Colors.black45),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Profiel Bewerken',
                            style: TextStyle(
                              color: const Color(0xFF111827),
                              fontSize: responsive.fontSize(compact ? 21 : 24),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: midGap),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildSectionCard(
                            compact: compact,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  responsive,
                                  'Persoonlijke informatie',
                                  compact: compact,
                                ),
                                SizedBox(height: compact ? 6 : 8),
                                _buildLabel(responsive, 'Naam *'),
                                const SizedBox(height: 6),
                                _buildTextField(
                                  responsive,
                                  _nameController,
                                  'Voer uw naam in',
                                  minLength: 2,
                                ),
                                SizedBox(height: compact ? 6 : 8),
                                _buildLabel(responsive, 'Geslacht'),
                                const SizedBox(height: 6),
                                _buildGenderDropdown(responsive),
                                SizedBox(height: compact ? 6 : 8),
                                _buildLabel(responsive, 'Geboortedatum'),
                                const SizedBox(height: 6),
                                _buildDateField(responsive),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: midGap),
                        Expanded(
                          child: _buildSectionCard(
                            compact: compact,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  responsive,
                                  'Extra informatie',
                                  compact: compact,
                                ),
                                SizedBox(height: compact ? 6 : 8),
                                _buildLabel(responsive, 'Postcode'),
                                const SizedBox(height: 6),
                                _buildTextField(
                                  responsive,
                                  _postcodeController,
                                  'Voer uw postcode in',
                                ),
                                SizedBox(height: compact ? 6 : 8),
                                _buildLabel(responsive, 'Beschrijving'),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: _buildTextField(
                                    responsive,
                                    _descriptionController,
                                    'Voer een beschrijving in',
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: midGap),
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF103D1E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Opslaan',
                              style: TextStyle(
                                fontSize: responsive.fontSize(compact ? 18 : 20),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child, required bool compact}) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 12 : 16, 16, compact ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(
    ResponsiveUtils responsive,
    String title, {
    required bool compact,
  }) {
    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFF111827),
        fontSize: responsive.fontSize(compact ? 17 : 19),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildLabel(ResponsiveUtils responsive, String text) {
    return Text(
      text,
      style: TextStyle(
        color: const Color(0xFF374151),
        fontSize: 16,
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
      textAlignVertical: maxLines > 1 ? TextAlignVertical.top : TextAlignVertical.center,
      style: TextStyle(
        color: const Color(0xFF111827),
        fontSize: responsive.fontSize(16),
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xFF9CA3AF),
          fontSize: responsive.fontSize(15),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: responsive.wp(4),
          vertical: maxLines > 1 ? 10 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF103D1E), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateField(ResponsiveUtils responsive) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.wp(4),
          vertical: responsive.hp(1.35),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF111827),
                fontSize: responsive.fontSize(16),
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: const Color(0xFF103D1E),
              size: responsive.sp(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedGender,
        hint: Text(
          'Selecteer geslacht',
          style: TextStyle(
            color: const Color(0xFF9CA3AF),
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
              value.toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: responsive.fontSize(16),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

