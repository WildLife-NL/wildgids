import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';
import 'package:flutter/services.dart';

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
  bool _isEditing = false;
  String? _errorMessage;

  // Add scroll controllers for the wheels
  FixedExtentScrollController? _hourScrollController;
  FixedExtentScrollController? _minuteScrollController;

  @override
  void initState() {
    super.initState();
    _currentTime = TimeOfDay.now();

    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;

    // Initialize scroll controllers
    _hourScrollController = FixedExtentScrollController(
      initialItem: _selectedHour,
    );
    _minuteScrollController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );

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

    if (digitsOnly.length >= 2) {
      // Insert colon after first two digits
      String hours = digitsOnly.substring(0, 2);
      String minutes =
          digitsOnly.length > 2
              ? digitsOnly.substring(2, min(4, digitsOnly.length))
              : '';
      String formattedTime = '$hours:$minutes';

      // Update the text field without triggering onChanged
      _timeController.value = TextEditingValue(
        text: formattedTime,
        selection: TextSelection.collapsed(offset: formattedTime.length),
      );

      // Check hours validity as soon as they're entered
      if (hours.length == 2) {
        final hoursValue = int.tryParse(hours);
        if (hoursValue != null && hoursValue >= 0 && hoursValue < 24) {
          // If today's date is selected, check if hours are in the future
          if (_isToday(widget.selectedDate) && hoursValue > _currentTime.hour) {
            setState(() {
              _errorMessage = 'Tijd kan niet in de toekomst liggen';
            });
            return;
          }
        }
      }

      // If we have a complete time (4 digits)
      if (digitsOnly.length >= 4) {
        final hours = int.tryParse(digitsOnly.substring(0, 2));
        final minutes = int.tryParse(digitsOnly.substring(2, 4));

        if (hours != null &&
            minutes != null &&
            hours >= 0 &&
            hours < 24 &&
            minutes >= 0 &&
            minutes < 60) {
          // Check if the entered time is valid (not in the future)
          if (_isValidTime(hours, minutes)) {
            setState(() {
              _selectedHour = hours;
              _selectedMinute = minutes;
              _errorMessage = null; // Clear error message on valid input

              // Update wheel positions to match typed time
              _updateWheelPositions();
            });
          } else {
            setState(() {
              _errorMessage = 'Tijd kan niet in de toekomst liggen';
            });
          }
        }
      }
    } else {
      // For the first two digits, just update the controller
      _timeController.value = TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
      setState(() {
        _errorMessage = null; // Clear error when starting new input
      });
    }
  }

  void _updateWheelPositions() {
    // We need to add controllers for the wheels
    if (_hourScrollController != null) {
      _hourScrollController!.animateToItem(
        _selectedHour,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (_minuteScrollController != null) {
      _minuteScrollController!.animateToItem(
        _selectedMinute,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _hourScrollController?.dispose();
    _minuteScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kies tijd',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 20),
            _buildCurrentTimeDisplay(),
            const SizedBox(height: 20),
            _buildTimeWheels(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeDisplay() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isEditing = true;
              _errorMessage = null; // Clear error when starting to edit
              _timeController.clear();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.darkGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  _errorMessage != null
                      ? Border.all(color: Colors.red, width: 1.0)
                      : null,
            ),
            child:
                _isEditing
                    ? TextField(
                      controller: _timeController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color:
                            _errorMessage != null
                                ? Colors.red
                                : AppColors.darkGreen,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: _handleTimeInput,
                      onSubmitted: (_) {
                        setState(() {
                          _isEditing = false;
                          if (_timeController.text.isEmpty) {
                            _updateTimeDisplay();
                            _errorMessage = null;
                          }
                        });
                      },
                      autofocus: true,
                    )
                    : Text(
                      '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color:
                            _errorMessage != null
                                ? Colors.red
                                : AppColors.darkGreen,
                      ),
                    ),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeWheels() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWheel(
            value: _selectedHour,
            maxValue: _isToday(widget.selectedDate) ? _currentTime.hour : 23,
            onChanged: (value) {
              setState(() {
                _selectedHour = value;
                // Adjust minutes if necessary
                if (_isToday(widget.selectedDate) &&
                    value == _currentTime.hour &&
                    _selectedMinute > _currentTime.minute) {
                  _selectedMinute = _currentTime.minute;
                  _minuteScrollController?.animateToItem(
                    _selectedMinute,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
                _updateTimeDisplay();
              });
            },
            label: 'uur',
            initialScrollIndex: _selectedHour,
            controller: _hourScrollController,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
          ),
          _buildWheel(
            value: _selectedMinute,
            maxValue:
                _isToday(widget.selectedDate) &&
                        _selectedHour == _currentTime.hour
                    ? _currentTime.minute
                    : 59,
            onChanged: (value) {
              if (_isToday(widget.selectedDate) &&
                  _selectedHour == _currentTime.hour &&
                  value > _currentTime.minute) {
                return;
              }
              setState(() {
                _selectedMinute = value;
                _updateTimeDisplay();
              });
            },
            step: 1,
            label: 'min',
            initialScrollIndex: _selectedMinute,
            controller: _minuteScrollController,
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required int value,
    required int maxValue,
    required Function(int) onChanged,
    int step = 1,
    required String label,
    required int initialScrollIndex,
    FixedExtentScrollController? controller,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 120,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            perspective: 0.003,
            diameterRatio: 1.8,
            physics: const FixedExtentScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            overAndUnderCenterOpacity: 0.7,
            magnification: 1.2,
            useMagnifier: true,
            controller:
                controller ??
                FixedExtentScrollController(initialItem: initialScrollIndex),
            onSelectedItemChanged: (index) => onChanged(index * step),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: (maxValue ~/ step) + 1,
              builder: (context, index) {
                final number = index * step;
                final isSelected = number == value;
                return Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSelected ? 20 : 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected
                              ? AppColors.darkGreen
                              : AppColors.darkGreen.withValues(alpha: 0.5),
                    ),
                    child: Text(number.toString().padLeft(2, '0')),
                  ),
                );
              },
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkGreen.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuleren', style: TextStyle(color: AppColors.darkGreen)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed:
              () => Navigator.of(
                context,
              ).pop(TimeOfDay(hour: _selectedHour, minute: _selectedMinute)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Bevestigen',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
