import 'package:flutter/material.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';
import 'package:covid19_tracker_flutter/Utils/formatters.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool large;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.large = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double padding = large ? 20 : 16;
    final double iconSize = large ? 22 : 18;
    final double fontSize = large ? 24 : 18;
    final double subtitleSize = large ? 14 : 12;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: large ? 40 : 32,
          height: large ? 40 : 32,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: iconSize),
        ),
        SizedBox(height: large ? 16 : 12),
        Text(formatNumber(int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0),
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontSize: subtitleSize, fontWeight: FontWeight.w600, color: AppColors.muted)),
      ]),
    );
  }
}
