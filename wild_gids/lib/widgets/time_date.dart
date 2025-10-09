import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateTimePicker extends StatefulWidget {
  @override
  State<CustomDateTimePicker> createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(hour: 11, minute: 30);

  void _openCalendarDialog() async {
    DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _CalendarDialog(
        initialDate: selectedDate,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

 void _openTimeDialog() async {
  TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: selectedTime,
    initialEntryMode: TimePickerEntryMode.input, // Open in input mode directly
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.green[800]!, // Sets field borders, button, cursor
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            dayPeriodColor: MaterialStateColor.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.green[800]!; // Selected AM/PM background
              }
              return Colors.grey.shade200; // Unselected AM/PM background
            }),
            dayPeriodTextColor: MaterialStateColor.resolveWith((states) {
              return states.contains(MaterialState.selected)
                  ? Colors.white // Selected text color
                  : Colors.black; // Unselected text color
            }),
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() => selectedTime = picked);
  }
}


  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
    String timeStr = selectedTime.hour.toString().padLeft(2, '0') +
        ":" +
        selectedTime.minute.toString().padLeft(2, '0');

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PickerButton(
            text: dateStr,
            icon: Icons.calendar_today,
            onPressed: _openCalendarDialog,
          ),
          const SizedBox(width: 8),
          _PickerButton(
            text: timeStr,
            icon: Icons.access_time,
            onPressed: _openTimeDialog,
          ),
        ],
      ),
    );
  }
}

// Button used for date/time selection
class _PickerButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _PickerButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: const Color.fromARGB(255, 98, 57, 3), width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'RobotoMono',
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.black, size: 22),
          ],
        ),
      );
}

// Custom Calendar Dialog
class _CalendarDialog extends StatefulWidget {
  final DateTime initialDate;

  const _CalendarDialog({required this.initialDate});

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime displayedDate;
  late DateTime selected;

  @override
  void initState() {
    displayedDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    selected = widget.initialDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int year = displayedDate.year;
    int month = displayedDate.month;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(18),
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select date', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            SizedBox(height: 12),
            Text(
              DateFormat('EEEE, d MMMM').format(selected),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  value: month,
                  items: List.generate(12, (i) {
                    final m = DateFormat.MMMM().format(DateTime(year, i + 1));
                    return DropdownMenuItem(value: i + 1, child: Text(m));
                  }),
                  onChanged: (val) {
                    setState(() {
                      displayedDate = DateTime(year, val!);
                    });
                  },
                  underline: Container(),
                ),
                DropdownButton<int>(
                  value: year,
                  items: List.generate(3, (i) {
                    final val = DateTime.now().year + i;
                    return DropdownMenuItem(value: val, child: Text(val.toString()));
                  }),
                  onChanged: (val) {
                    setState(() {
                      displayedDate = DateTime(val!, month);
                    });
                  },
                  underline: Container(),
                ),
              ],
            ),
            SizedBox(height: 8),
            _CalendarGrid(
              year: displayedDate.year,
              month: displayedDate.month,
              selectedDate: selected,
              onSelect: (date) => setState(() => selected = date),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context, selected),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Render the calendar days grid
class _CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime selectedDate;
  final Function(DateTime) onSelect;

  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    int startWeekday = firstDayOfMonth.weekday % 7; // Sunday == 0

    List<Widget> dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        .map((d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(d, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ))
        .toList();

    int daysInMonth = DateTime(year, month + 1, 0).day;

    List<Widget> dayWidgets = [];
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(SizedBox(width: 32, height: 32));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime curr = DateTime(year, month, day);
      bool isSelected = curr.year == selectedDate.year &&
          curr.month == selectedDate.month &&
          curr.day == selectedDate.day;

      dayWidgets.add(
        InkWell(
          onTap: () => onSelect(curr),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? const Color.fromARGB(255, 19, 82, 10) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayHeaders,
        ),
        SizedBox(height: 4),
        Wrap(children: dayWidgets),
      ],
    );
  }
}
