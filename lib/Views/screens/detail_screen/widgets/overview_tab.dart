import 'package:covid19_tracker_flutter/Models/CountryDetailModel.dart';
import 'package:flutter/material.dart';
import 'stat_card.dart';
import 'progress_indicator.dart';
import 'package:covid19_tracker_flutter/Controllers/detail_controller.dart';


class OverviewTab extends StatelessWidget {
  final CountryDetail countryDetail;
  final DetailController controller;

  const OverviewTab({super.key, required this.countryDetail, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to change layout on tablet vs phone
    return LayoutBuilder(builder: (context, constraints) {
      final isTablet = constraints.maxWidth > 700;
      final horizontalPadding = isTablet ? 32.0 : 20.0;

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        child: Column(children: [
          // Primary row
          Row(children: [
            Expanded(child: StatCard(title: 'Total Cases', value: countryDetail.totalCases.toString(), icon: Icons.coronavirus_rounded, color: const Color(0xff6366f1), large: true)),
            const SizedBox(width: 12),
            Expanded(child: StatCard(title: 'Deaths', value: countryDetail.totalDeaths.toString(), icon: Icons.dangerous_rounded, color: const Color(0xffef4444), large: true)),
          ]),
          const SizedBox(height: 12),

          // Secondary
          Row(children: [
            Expanded(child: StatCard(title: 'Recovered', value: countryDetail.totalRecovered.toString(), icon: Icons.health_and_safety_rounded, color: const Color(0xff10b981))),
            const SizedBox(width: 12),
            Expanded(child: StatCard(title: 'Active', value: countryDetail.active.toString(), icon: Icons.local_hospital_rounded, color: const Color(0xfff59e0b))),
          ]),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: StatCard(title: 'Critical', value: countryDetail.critical.toString(), icon: Icons.warning_rounded, color: const Color(0xffec4899))),
            const SizedBox(width: 12),
            Expanded(child: StatCard(title: 'Tests', value: countryDetail.test.toString(), icon: Icons.science_rounded, color: const Color(0xff8b5cf6))),
          ]),
          const SizedBox(height: 20),

          // Recovery analysis card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xff1e293b) : Colors.white,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recovery Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)),
              const SizedBox(height: 16),
              LinearProgressIndicatorCustom(
                label: 'Recovery Rate',
                percentage: countryDetail.totalCases > 0 ? (countryDetail.totalRecovered / countryDetail.totalCases) : 0.0,
                color: const Color(0xff10b981),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicatorCustom(
                label: 'Mortality Rate',
                percentage: countryDetail.totalCases > 0 ? (countryDetail.totalDeaths / countryDetail.totalCases) : 0.0,
                color: const Color(0xffef4444),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicatorCustom(
                label: 'Active Cases',
                percentage: countryDetail.totalCases > 0 ? (countryDetail.active / countryDetail.totalCases) : 0.0,
                color: const Color(0xfff59e0b),
              ),
            ]),
          ),

          const SizedBox(height: 24),
        ]),
      );
    });
  }
}
