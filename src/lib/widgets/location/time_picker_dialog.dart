import 'package:flutter/material.dart';
import 'package:wildgids/constants/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:wildgids/utils/responsive_utils.dart';

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Remove any non-digit characters
    String digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 4 digits
    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    // Format as HH:MM
    String formatted;
    if (digitsOnly.isEmpty) {
      formatted = '';
    } else if (digitsOnly.length <= 2) {
      formatted = digitsOnly;
    } else {
      formatted = '${digitsOnly.substring(0, 2)}:${digitsOnly.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CustomTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final DateTime selectedDate; // Add this parameter

  const CustomTimePickerDialog({
    super.key,
    required this.initialTime,
    required this.selectedDate, // Add this parameter
  });

  @override
  State<CustomTimePickerDialog> createState() => _CustomTimePickerDialogState();
}

class _CustomTimePickerDialogState extends State<CustomTimePickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;
  final TextEditingController _timeController = TextEditingController();
  late TimeOfDay _currentTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentTime = TimeOfDay.now();

    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;

    _updateTimeDisplay();
  }

  bool _isValidTime(int hour, int minute) {
    // Only check for future time if the selected date is today
    if (_isToday(widget.selectedDate)) {
      if (hour > _currentTime.hour) return false;
      if (hour == _currentTime.hour && minute > _currentTime.minute) {
        return false;
      }
    }
    return true;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _updateTimeDisplay() {
    _timeController.text =
        '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
  }

  void _handleTimeInput(String value) {
    // Remove any non-digit characters
    String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() {
      _errorMessage = null; // Clear error when typing
    });

    // If we have a complete time (4 digits), validate and apply it
    if (digitsOnly.length == 4) {
      final hours = int.tryParse(digitsOnly.substring(0, 2));
      final minutes = int.tryParse(digitsOnly.substring(2, 4));

      if (hours == null || hours < 0 || hours > 23) {
        setState(() {
          _errorMessage = 'Ongeldige uren (0-23)';
        });
        return;
      }

      if (minutes == null || minutes < 0 || minutes > 59) {
        setState(() {
          _errorMessage = 'Ongeldige minuten (0-59)';
        });
        return;
      }

      if (!_isValidTime(hours, minutes)) {
        setState(() {
          _errorMessage = 'Tijd kan niet in de toekomst liggen';
        });
        return;
      }

      // Valid time - apply it
      setState(() {
        _selectedHour = hours;
        _selectedMinute = minutes;
      });
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.sp(3.75)),
      ),
      child: Container(
        width: responsive.wp(75),
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kies tijd',
              style: TextStyle(
                fontSize: responsive.fontSize(20),
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            SizedBox(height: responsive.spacing(20)),
            _buildCurrentTimeDisplay(responsive),
            SizedBox(height: responsive.spacing(20)),
            _buildActionButtons(responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeDisplay(ResponsiveUtils responsive) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(responsive.spacing(16)),
          decoration: BoxDecoration(
            color: AppColors.lightMintGreen100,
            borderRadius: BorderRadius.circular(responsive.sp(3)),
            border: Border.all(
              color: _errorMessage != null ? Colors.red : AppColors.darkGreen,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Type tijd',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGreen,
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              Container(
                width: responsive.wp(60),
                padding: EdgeInsets.symmetric(
                  vertical: responsive.spacing(12),
                  horizontal: responsive.spacing(8),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(responsive.sp(2)),
                  border: Border.all(color: AppColors.darkGreen, width: 2),
                ),
                child: TextField(
                  controller: _timeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: responsive.fontSize(32),
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                    letterSpacing: 4,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'HH:MM',
                    hintStyle: TextStyle(
                      color: AppColors.darkGreen.withValues(alpha: 0.3),
                      fontSize: responsive.fontSize(32),
                    ),
                  ),
                  inputFormatters: [TimeInputFormatter()],
                  onChanged: _handleTimeInput,
                  autofocus: true,
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: EdgeInsets.only(top: responsive.spacing(8)),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(12),
                vertical: responsive.spacing(6),
              ),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(responsive.sp(2)),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: responsive.fontSize(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(ResponsiveUtils responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(20),
              vertical: responsive.spacing(12),
            ),
          ),
          child: Text(
            'Annuleren',
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed:
              () => Navigator.of(
                context,
              ).pop(TimeOfDay(hour: _selectedHour, minute: _selectedMinute)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightMintGreen100,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(28),
              vertical: responsive.spacing(14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(responsive.sp(2.5)),
              side: BorderSide(color: AppColors.darkGreen, width: 2),
            ),
            elevation: 2,
          ),
          child: Text(
            'Bevestigen',
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

