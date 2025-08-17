import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:covid19_tracker_flutter/Controllers/map_controller.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';

class LegendWidget extends StatelessWidget {
  final MapController mapController;

  const LegendWidget({
    super.key,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() => Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCard : AppColors.lightCard).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          _buildRiskLevels(isDark),
          _buildMetricInfo(isDark),
          if (mapController.showHeatmap.value) _buildHeatmapLegend(isDark),
        ],
      ),
    ));
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.legend_toggle_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Map Legend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => mapController.toggleLegend(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevels(bool isDark) {
    final riskLevels = [
      {'level': 'CRITICAL', 'color': '#DC2626', 'description': '>100K per million'},
      {'level': 'HIGH', 'color': '#EF4444', 'description': '50K-100K per million'},
      {'level': 'MEDIUM', 'color': '#F59E0B', 'description': '20K-50K per million'},
      {'level': 'LOW', 'color': '#3B82F6', 'description': '5K-20K per million'},
      {'level': 'MINIMAL', 'color': '#10B981', 'description': '<5K per million'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Levels',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          ...riskLevels.map((risk) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${risk['color']!.substring(1)}')),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        risk['level']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        risk['description']!,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildMetricInfo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: Colors.grey.withOpacity(0.3),
            thickness: 1,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getMetricIcon(mapController.selectedMetric.value),
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Metric: ${mapController.selectedMetric.value.capitalize}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getMetricDescription(mapController.selectedMetric.value),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: Colors.grey.withOpacity(0.3),
            thickness: 1,
          ),
          const SizedBox(height: 8),
          Text(
            'Heatmap Intensity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF10B981), // Green (low)
                  Color(0xFF3B82F6), // Blue
                  Color(0xFFF59E0B), // Yellow
                  Color(0xFFEF4444), // Red
                  Color(0xFFDC2626), // Dark red (high)
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                'High',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getMetricIcon(String metric) {
    switch (metric) {
      case 'cases':
        return Icons.coronavirus_rounded;
      case 'deaths':
        return Icons.dangerous_rounded;
      case 'recovered':
        return Icons.health_and_safety_rounded;
      case 'active':
        return Icons.local_hospital_rounded;
      default:
        return Icons.bar_chart_rounded;
    }
  }

  String _getMetricDescription(String metric) {
    switch (metric) {
      case 'cases':
        return 'Total confirmed COVID-19 cases reported in each country';
      case 'deaths':
        return 'Total deaths attributed to COVID-19 in each country';
      case 'recovered':
        return 'Total number of people recovered from COVID-19';
      case 'active':
        return 'Currently active COVID-19 cases (cases - deaths - recovered)';
      default:
        return 'COVID-19 statistical data by country';
    }
  }
}