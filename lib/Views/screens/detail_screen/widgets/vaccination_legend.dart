import 'package:flutter/material.dart';
import 'package:covid19_tracker_flutter/Utils/formatters.dart';

class VaccinationLegend extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const VaccinationLegend({Key? key, required this.title, required this.value, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xff64748b), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(formatNumber(value), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
        ]),
      ),
    ]);
  }
}
