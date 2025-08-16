import 'package:covid19_tracker_flutter/Views/screens/detail_screen/widgets/empty_state.dart';
import 'package:covid19_tracker_flutter/Views/screens/detail_screen/widgets/vaccination_legend.dart';
import 'package:covid19_tracker_flutter/Services/vaccination_service.dart';
import 'package:covid19_tracker_flutter/Models/VaccinationModel.dart';
import 'package:flutter/material.dart';
import 'package:covid19_tracker_flutter/Controllers/detail_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:covid19_tracker_flutter/Utils/formatters.dart';
import 'package:covid19_tracker_flutter/Utils/constants.dart';
import 'package:get/get.dart';

class VaccinationTab extends StatelessWidget {
  final DetailController controller;

  const VaccinationTab({Key? key, required this.controller}) : super(key: key);

  String _formatNumber(String number) {
    if (number == 'null' || number.isEmpty) return '0';
    int num = int.tryParse(number) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  Widget _buildVaccinationLegend(String title, int value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff64748b),
                ),
              ),
              Text(
                _formatNumber(value.toString()),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0f172a),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaccinationStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title.contains('%') ? value : _formatNumber(value),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xff0f172a),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xff64748b),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use FutureBuilder directly like in the working version
    return FutureBuilder<VaccinationModel>(
      future: VaccinationService().getCountryVaccination(controller.countryDetail.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff6366f1)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Trigger rebuild
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final vaccination = snapshot.data ?? VaccinationModel();
        
        // Debug prints
        print('🔍 Vaccination data for ${controller.countryDetail.name}:');
        print('   Country: ${vaccination.country}');
        print('   Population: ${vaccination.population}');
        print('   Fully vaccinated: ${vaccination.peopleVaccinated}');
        print('   Partially vaccinated: ${vaccination.peoplePartiallyVaccinated}');
        print('   Administered: ${vaccination.administered}');

        // Check if we have any vaccination data
        if (vaccination.population == null || vaccination.population == 0) {
          return const EmptyState(message: 'No vaccination data available');
        }

        final population = vaccination.population ?? 1000000;
        final fully = vaccination.peopleVaccinated ?? 0;
        final partial = (vaccination.peoplePartiallyVaccinated ?? 0) - fully;
        final unvaccinated = (population - (vaccination.peoplePartiallyVaccinated ?? 0)).clamp(0, population);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Vaccination Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1e293b) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vaccination Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Pie Chart
                    SizedBox(
                      height: 160,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: fully.toDouble(),
                                    color: const Color(0xff10b981),
                                    title: '${((fully / population) * 100).toStringAsFixed(1)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: partial.toDouble().clamp(0, population.toDouble()),
                                    color: const Color(0xff6366f1),
                                    title: '${((partial / population) * 100).toStringAsFixed(1)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: unvaccinated.toDouble(),
                                    color: const Color(0xff64748b).withOpacity(0.3),
                                    title: '${((unvaccinated / population) * 100).toStringAsFixed(1)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    radius: 50,
                                  ),
                                ],
                                sectionsSpace: 2,
                                centerSpaceRadius: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildVaccinationLegend(
                                  'Fully Vaccinated',
                                  fully,
                                  const Color(0xff10b981),
                                ),
                                const SizedBox(height: 12),
                                _buildVaccinationLegend(
                                  'Partially Vaccinated',
                                  partial,
                                  const Color(0xff6366f1),
                                ),
                                const SizedBox(height: 12),
                                _buildVaccinationLegend(
                                  'Unvaccinated',
                                  unvaccinated,
                                  const Color(0xff64748b).withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Vaccination Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildVaccinationStatCard(
                      'Total Doses',
                      (vaccination.administered ?? 0).toString(),
                      Icons.vaccines_rounded,
                      const Color(0xff6366f1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVaccinationStatCard(
                      'Fully Vaccinated',
                      fully.toString(),
                      Icons.shield_rounded,
                      const Color(0xff10b981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildVaccinationStatCard(
                      'Population',
                      population.toString(),
                      Icons.people_rounded,
                      const Color(0xff8b5cf6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVaccinationStatCard(
                      'Coverage',
                      '${((fully / population) * 100).toStringAsFixed(1)}%',
                      Icons.analytics_rounded,
                      const Color(0xfff59e0b),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}