import 'package:flutter/material.dart';

class PictureFrame extends StatelessWidget {
  final String label;
  final double width;
  final double height;

  const PictureFrame({
    Key? key,
    this.label = "Bever",          // Default label set to 'Bever'
    this.width = 80,
    this.height = 130,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        children: [
          // Image display
          ClipRRect(
            borderRadius: BorderRadius.only(
  topLeft: Radius.circular(12),
  topRight: Radius.circular(12),
),

            child: SizedBox(
              width: width,
              height: height - 32,   // Leave space for label
              child: Image.asset(
                'assets/images/bever.png',   
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Show placeholder X if image not available
                  return CustomPaint(
                    size: Size(width, height - 32),
                    painter: _XCrossPainter(),
                  );
                },
              ),
            ),
          ),
          // Label at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
