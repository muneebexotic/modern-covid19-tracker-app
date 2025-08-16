import 'package:covid19_tracker_flutter/Models/CountryDetailModel.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:covid19_tracker_flutter/Controllers/detail_controller.dart';
import 'chart_legend.dart';
import 'package:covid19_tracker_flutter/Utils/constants.dart';
import 'package:covid19_tracker_flutter/Utils/formatters.dart';

class TrendsTab extends StatelessWidget {
  final CountryDetail countryDetail;
  final DetailController controller;

  const TrendsTab({Key? key, required this.countryDetail, required this.controller}) : super(key: key);

  List<FlSpot> _toFlSpots(List<FlSpotData> data) => data.map((d) => FlSpot(d.x, d.y)).toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isTablet = constraints.maxWidth > 700;
      final chartHeight = isTablet ? AppConstants.chartHeightTablet : AppConstants.chartHeightPhone;

      final casesSpots = _toFlSpots(controller.chartSpotsFor(countryDetail.totalCases.toDouble()));
      final deathsSpots = _toFlSpots(controller.chartSpotsFor(countryDetail.totalDeaths.toDouble()));
      final recoveredSpots = _toFlSpots(controller.chartSpotsFor(countryDetail.totalRecovered.toDouble()));

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Historical Trends', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Last ${AppConstants.trendPoints} points (approx)', style: TextStyle(color: const Color(0xff64748b))),
          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1e293b) : Colors.white),
            child: Column(children: [
              SizedBox(
                height: chartHeight,
                child: LineChart(LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xff64748b).withOpacity(0.2), strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) {
                      return Text(formatChartNumber(value), style: const TextStyle(color: Color(0xff64748b), fontSize: 11));
                    })),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                      const days = ['W1', 'W2', 'W3', 'W4'];
                      if (value.toInt() < days.length) return Text(days[value.toInt()], style: const TextStyle(color: Color(0xff64748b), fontSize: 11));
                      return const Text('');
                    }, interval: 1)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(spots: casesSpots, isCurved: true, color: const Color(0xff6366f1), barWidth: 3, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: const Color(0xff6366f1).withOpacity(0.08))),
                    LineChartBarData(spots: deathsSpots, isCurved: true, color: const Color(0xffef4444), barWidth: 3, dotData: const FlDotData(show: false)),
                    LineChartBarData(spots: recoveredSpots, isCurved: true, color: const Color(0xff10b981), barWidth: 3, dotData: const FlDotData(show: false)),
                  ],
                )),
              ),

              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ChartLegendItem(title: 'Cases', color: const Color(0xff6366f1)),
                ChartLegendItem(title: 'Deaths', color: const Color(0xffef4444)),
                ChartLegendItem(title: 'Recovered', color: const Color(0xff10b981)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          Row(children: [
            Expanded(child: Container(height: 100, child: Center(child: Text('Growth Rate Placeholder')))),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 100, child: Center(child: Text('Test Rate Placeholder')))),
          ]),

          const SizedBox(height: 24),
        ]),
      );
    });
  }
}
