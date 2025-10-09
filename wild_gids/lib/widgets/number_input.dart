import 'package:flutter/material.dart';

class NumberInput extends StatefulWidget {
  final List<String> values;
  final int initialIndex;
  final ValueChanged<int>? onChanged;
  final double width;
  final double height;

  const NumberInput({
    Key? key,
    required this.values,
    this.initialIndex = 0,
    this.onChanged,
    this.width = 100,
    this.height = 120,
  }) : super(key: key);

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  late FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B3F1D), width: 2),
      ),
      child: Stack(
        children: [
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.height / 3,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
              if (widget.onChanged != null) widget.onChanged!(index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= widget.values.length) return null;
                return Center(
                  child: Text(
                    widget.values[index],
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.black,
                    ),
                  ),
                );
              },
              childCount: widget.values.length,
            ),
          ),
          // Highlight for selected value
          Align(
            alignment: Alignment.center,
            child: Container(
              height: widget.height / 3,
              width: double.infinity,
              color: const Color.fromARGB(255, 149, 194, 139).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}