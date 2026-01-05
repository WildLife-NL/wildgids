import 'package:flutter/material.dart';
import 'package:wildrapport/constants/app_colors.dart';

class AnimalCounter extends StatefulWidget {
  final String name;
  final double height;
  final Function(String name, int count)? onCountChanged;

  const AnimalCounter({
    super.key,
    required this.name,
    this.height = 49,
    this.onCountChanged,
  });

  @override
  AnimalCounterState createState() => AnimalCounterState();
}

class AnimalCounterState extends State<AnimalCounter> {
  int _count = 0;
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = false;

  // Add this method to reset the counter
  void reset() {
    setState(() {
      _count = 0;
      _controller.text = '0';
    });
    widget.onCountChanged?.call(widget.name, _count);
  }

  @override
  void initState() {
    super.initState();
    _controller.text = _count.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increment() {
    setState(() {
      _count++;
      _controller.text = _count.toString();
    });
    widget.onCountChanged?.call(widget.name, _count);
  }

  void _decrement() {
    setState(() {
      if (_count > 0) {
        _count--;
        _controller.text = _count.toString();
      }
    });
    widget.onCountChanged?.call(widget.name, _count);
  }

  void _handleTextSubmitted(String value) {
    final newCount = int.tryParse(value) ?? 0;
    setState(() {
      _count = newCount < 0 ? 0 : newCount;
      _controller.text = _count.toString();
      _isEditing = false;
    });
    widget.onCountChanged?.call(widget.name, _count);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(15),
        // Removed boxShadow to match the no-dropshadow requirement
        boxShadow: null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: _buildButton("−", _decrement),
          ),
          Container(
            height: widget.height - 20, // Adjust height of divider
            width: 1,
            color: Colors.grey.withValues(alpha: 0.7),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isEditing = true;
                  _controller.text = ""; // Clear the text when starting to edit
                });
              },
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child:
                          _isEditing
                              ? TextField(
                                controller: _controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Roboto',
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: _handleTextSubmitted,
                                autofocus: true,
                              )
                              : Text(
                                '$_count',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                    ),
                    Container(
                      height: 1,
                      width: 40, // Width of the underline
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: widget.height - 20, // Adjust height of divider
            width: 1,
            color: Colors.grey.withValues(alpha: 0.7),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: _buildButton("+", _increment),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String symbol, VoidCallback onPressed) {
    final bool isMinus = symbol == "−";
    return SizedBox(
      width: 44, // Same width for both buttons
      height: widget.height - 13, // Adjust height based on parent container
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColors.brown.withValues(alpha: 0.3),
          highlightColor: AppColors.brown.withValues(alpha: 0.1),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w400,
                letterSpacing: isMinus ? 2.0 : 0,
                height: 1,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
