import 'package:flutter/material.dart';

class IntensitySlider extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;

  const IntensitySlider({
    Key? key,
    this.value = 0.3,
    this.onChanged,
  }) : super(key: key);

  @override
  State<IntensitySlider> createState() => _IntensitySliderState();
}

class _IntensitySliderState extends State<IntensitySlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Intensiteit",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(
              child: Text("Low", textAlign: TextAlign.left),
            ),
            Expanded(
              child: Text("High", textAlign: TextAlign.right),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 10,
            inactiveTrackColor: Colors.grey[300],
            activeTrackColor: const Color(0xFFF4D1B7),
            thumbColor: const Color(0xFFF4D1B7),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 18),
            overlayShape: SliderComponentShape.noOverlay,
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            min: 0,
            max: 1,
            value: _currentValue,
            onChanged: (v) {
              setState(() {
                _currentValue = v;
              });
              if (widget.onChanged != null) widget.onChanged!(v);
            },
          ),
        ),
      ],
    );
  }
}
