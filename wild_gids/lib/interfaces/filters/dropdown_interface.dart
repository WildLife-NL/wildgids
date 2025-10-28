import 'package:flutter/material.dart';
import 'package:wildrapport/models/enums/dropdown_type.dart';

abstract class DropdownInterface {
  Widget buildDropdown({
    required DropdownType type,
    required String selectedValue,
    required bool isExpanded,
    required Function(bool) onExpandChanged,
    required Function(String) onOptionSelected,
    required BuildContext context,
  });
}
