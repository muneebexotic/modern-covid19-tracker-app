import 'package:flutter/material.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';

class LinearProgressIndicatorCustom extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;

  const LinearProgressIndicatorCustom({
    Key? key,
    required this.label,
    required this.percentage,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
        Text('${(percentage * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 8),
      Container(
        height: 8,
        decoration: BoxDecoration(color: isDark ? const Color(0xff334155) : const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(6)),
        child: FractionallySizedBox(
          widthFactor: percentage.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
        ),
      )
    ]);
  }
}
