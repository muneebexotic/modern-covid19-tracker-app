import 'package:flutter/material.dart';
import 'package:covid19_tracker_flutter/Utils/text_styles.dart';

class ChartLegendItem extends StatelessWidget {
  final String title;
  final Color color;

  const ChartLegendItem({Key? key, required this.title, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(title, style: AppTextStyles.smallMuted),
    ]);
  }
}
