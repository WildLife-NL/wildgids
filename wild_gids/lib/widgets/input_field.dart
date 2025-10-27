import 'package:flutter/material.dart';

class ResizableInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final double height;
  final double width;

  const ResizableInputField({
    Key? key,
    this.controller,
    this.hintText = "voorbeeld@gmail.com",
    this.height = 48,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF6B3F1D), // brown border
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF6B3F1D),
              width: 2,
            ),
          ),
        ),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
