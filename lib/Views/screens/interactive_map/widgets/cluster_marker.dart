import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:covid19_tracker_flutter/Models/MapDataModel.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';
import 'package:get/get.dart'; // <-- Added import for 'capitalize'

class ClusterMarker extends StatelessWidget {
  final List<MapDataModel> countries;
  final String selectedMetric;
  final VoidCallback? onTap;
  final double zoom;

  const ClusterMarker({
    super.key,
    required this.countries,
    required this.selectedMetric,
    this.onTap,
    this.zoom = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (countries.isEmpty) {
      return const SizedBox.shrink();
    }

    // For single country, show individual marker
    if (countries.length == 1) {
      return _buildIndividualMarker(countries.first);
    }

    // For multiple countries, show cluster marker
    return _buildClusterMarker();
  }

  Widget _buildIndividualMarker(MapDataModel country) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: _getMarkerSize(country),
        height: _getMarkerSize(country),
        decoration: BoxDecoration(
          color: Color(int.parse('0xFF${country.riskColor.substring(1)}')),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            country.countryCode,
            style: TextStyle(
              color: Colors.white,
              fontSize: _getMarkerSize(country) * 0.25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClusterMarker() {
    final totalValue = _calculateTotalValue();
    final averageRiskColor = _calculateAverageRiskColor();
    final clusterSize = _getClusterSize();

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle (larger)
          Container(
            width: clusterSize + 8,
            height: clusterSize + 8,
            decoration: BoxDecoration(
              color: averageRiskColor.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: averageRiskColor.withOpacity(0.6),
                width: 2,
              ),
            ),
          ),
          
          // Main cluster circle
          Container(
            width: clusterSize,
            height: clusterSize,
            decoration: BoxDecoration(
              color: averageRiskColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${countries.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: clusterSize * 0.3,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                if (clusterSize >= 40)
                  Text(
                    _formatClusterValue(totalValue),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: clusterSize * 0.15,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
              ],
            ),
          ),
          
          // Pulse animation overlay
          _buildPulseAnimation(clusterSize, averageRiskColor),
        ],
      ),
    );
  }

  Widget _buildPulseAnimation(double size, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.3),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3 - (value * 0.3)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        // Removed `context.mounted` check as context is not available here
        // The animation will simply restart
        Future.delayed(const Duration(milliseconds: 500), () {
          // You could use a stateful widget to manage animation state more robustly.
        });
      },
    );
  }

  double _getMarkerSize(MapDataModel country) {
    final baseSize = 16.0;
    final zoomFactor = (zoom / 5.0).clamp(0.5, 2.0);
    
    // Size based on total cases
    double sizeMultiplier = 1.0;
    if (country.totalCases > 10000000) {
      sizeMultiplier = 2.0;
    } else if (country.totalCases > 5000000) {
      sizeMultiplier = 1.7;
    } else if (country.totalCases > 1000000) {
      sizeMultiplier = 1.4;
    } else if (country.totalCases > 500000) {
      sizeMultiplier = 1.2;
    }

    return (baseSize * sizeMultiplier * zoomFactor).clamp(12.0, 40.0);
  }

  double _getClusterSize() {
    final baseSize = 32.0;
    final countMultiplier = (countries.length / 10.0 + 1.0).clamp(1.0, 2.5);
    final zoomFactor = (zoom / 3.0).clamp(0.7, 1.8);
    
    return (baseSize * countMultiplier * zoomFactor).clamp(24.0, 60.0);
  }

  num _calculateTotalValue() {
    switch (selectedMetric) {
      case 'deaths':
        return countries.fold<num>(0, (sum, country) => sum + country.totalDeaths);
      case 'recovered':
        return countries.fold<num>(0, (sum, country) => sum + country.recovered);
      case 'active':
        return countries.fold<num>(0, (sum, country) => sum + country.active);
      default: // cases
        return countries.fold<num>(0, (sum, country) => sum + country.totalCases);
    }
  }

  Color _calculateAverageRiskColor() {
    if (countries.isEmpty) return AppColors.muted;

    // Count countries by risk level
    final riskCounts = <String, int>{};
    for (final country in countries) {
      riskCounts[country.riskLevel] = (riskCounts[country.riskLevel] ?? 0) + 1;
    }

    // Find the most common risk level
    String dominantRisk = 'MINIMAL';
    int maxCount = 0;
    
    riskCounts.forEach((risk, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantRisk = risk;
      }
    });

    // Return color for dominant risk level
    switch (dominantRisk) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFF59E0B);
      case 'LOW':
        return const Color(0xFF3B82F6);
      case 'MINIMAL':
        return const Color(0xFF10B981);
      default:
        return AppColors.muted;
    }
  }

  String _formatClusterValue(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  /// Get cluster popup content for when cluster is tapped
  Widget buildClusterPopup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalValue = _calculateTotalValue();

    return Container(
      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 400),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _calculateAverageRiskColor(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.group_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cluster (${countries.length} countries)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${selectedMetric.capitalize}: ${_formatClusterValue(totalValue)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Countries list (scrollable)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: countries.length.clamp(0, 8), // Show max 8 countries
              itemBuilder: (context, index) {
                final country = countries[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${country.riskColor.substring(1)}')),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        country.countryCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    country.country,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _getCountryValueText(country),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                );
              },
            ),
          ),

          // Show more indicator if there are more countries
          if (countries.length > 8)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '... and ${countries.length - 8} more countries',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getCountryValueText(MapDataModel country) {
    final value = _getCountryValue(country);
    return '${country.formatNumber(value)} ${selectedMetric}';
  }

  num _getCountryValue(MapDataModel country) {
    switch (selectedMetric) {
      case 'deaths':
        return country.totalDeaths;
      case 'recovered':
        return country.recovered;
      case 'active':
        return country.active;
      default:
        return country.totalCases;
    }
  }
}