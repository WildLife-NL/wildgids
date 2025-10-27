import 'package:flutter/material.dart';
import 'package:widgets/constants/app_colors.dart';

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: _buildButton("âˆ’", _decrement),
          ),
          Container(
            height: widget.height - 20, // Adjust height of divider
            width: 1,
            color: Colors.grey.withValues(
              alpha: 0.7,
            ), // Increased opacity from 0.5 to 0.7
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
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      AppColors
                                          .brown, // Add this line to make text brown when typing
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
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
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                    ),
                    Container(
                      height: 1,
                      width: 40, // Width of the underline
                      color: Colors.grey.withValues(
                        alpha: 0.7,
                      ), // Increased opacity from 0.5 to 0.7
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: widget.height - 20, // Adjust height of divider
            width: 1,
            color: Colors.grey.withValues(
              alpha: 0.7,
            ), // Increased opacity from 0.5 to 0.7
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
    final bool isMinus = symbol == "âˆ’";
    return SizedBox(
      width: 44, // Same width for both buttons
      height: widget.height - 13, // Adjust height based on parent container
      child: Material(
        color: Colors.transparent, // Remove brown background
        child: InkWell(
          onTap: onPressed,
          splashColor: AppColors.brown.withValues(alpha: 0.3),
          highlightColor: AppColors.brown.withValues(alpha: 0.1),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                color: AppColors.brown, // Change text color to brown
                fontSize: 24,
                fontWeight: FontWeight.w400,
                letterSpacing: isMinus ? 2.0 : 0,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
