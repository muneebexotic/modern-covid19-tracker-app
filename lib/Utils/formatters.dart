import 'package:intl/intl.dart';

String formatNumber(int number) {
  if (number >= 1000000) return (number / 1000000).toStringAsFixed(1) + 'M';
  if (number >= 1000) return (number / 1000).toStringAsFixed(1) + 'K';
  return number.toString();
}

String formatChartNumber(double value) {
  if (value >= 1000000) return (value / 1000000).toStringAsFixed(0) + 'M';
  if (value >= 1000) return (value / 1000).toStringAsFixed(0) + 'K';
  return value.toInt().toString();
}

String formatPercent(double numerator, double denominator) {
  if (denominator == 0) return '0%';
  return (numerator / denominator * 100).toStringAsFixed(1) + '%';
}
