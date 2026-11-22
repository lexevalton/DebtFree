import 'package:flutter/material.dart';

class GradientColorSlider extends StatelessWidget {
  final double value;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  const GradientColorSlider({
    super.key,
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  void _updateFromOffset(Offset localPosition, double width) {
    if (width <= 0) return;
    final clamped = (localPosition.dx / width).clamp(0.0, 1.0);
    onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbX = (value.clamp(0.0, 1.0) * width).clamp(8.0, width - 8.0);

        return GestureDetector(
          onPanDown: (d) => _updateFromOffset(d.localPosition, width),
          onPanUpdate: (d) => _updateFromOffset(d.localPosition, width),
          child: SizedBox(
            height: 20,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
                Positioned(
                  left: thumbX - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black87, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
