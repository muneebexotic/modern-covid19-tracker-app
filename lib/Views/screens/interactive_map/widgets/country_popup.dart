import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:covid19_tracker_flutter/Models/MapDataModel.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';
import 'package:covid19_tracker_flutter/Utils/text_styles.dart';

class CountryPopup extends StatefulWidget {
  final MapDataModel country;
  final VoidCallback onClose;

  const CountryPopup({
    super.key,
    required this.country,
    required this.onClose,
  });

  @override
  State<CountryPopup> createState() => _CountryPopupState();
}

class _CountryPopupState extends State<CountryPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isDark),
                  _buildStats(isDark),
                  _buildRiskInfo(isDark),
                  _buildActions(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${widget.country.riskColor.substring(1)}')),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Flag or Country Code
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: widget.country.flag.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.country.flag,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                widget.country.countryCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.country.countryCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Country Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.country.country,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.country.latitude.toStringAsFixed(2)}, ${widget.country.longitude.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Close Button
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COVID-19 Statistics',
            style: AppTextStyles.heading(context, size: 18),
          ),
          
          const SizedBox(height: 16),
          
          // Main Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Total Cases',
                widget.country.formattedCases,
                Icons.coronavirus_rounded,
                AppColors.primary,
                isDark,
              ),
              _buildStatCard(
                'Deaths',
                widget.country.formattedDeaths,
                Icons.dangerous_rounded,
                AppColors.danger,
                isDark,
              ),
              _buildStatCard(
                'Recovered',
                widget.country.formattedRecovered,
                Icons.health_and_safety_rounded,
                AppColors.accent,
                isDark,
              ),
              _buildStatCard(
                'Active',
                widget.country.formattedActive,
                Icons.local_hospital_rounded,
                AppColors.warning,
                isDark,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Today's Stats
          if (widget.country.todayCases > 0 || widget.country.todayDeaths > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey[800]?.withOpacity(0.5) 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Update',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: AppColors.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.country.formatNumber(widget.country.todayCases)} cases',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.country.todayDeaths > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.remove_circle_outline,
                              color: AppColors.muted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.country.formatNumber(widget.country.todayDeaths)} deaths',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskInfo(bool isDark) {
    final riskColor = Color(int.parse('0xFF${widget.country.riskColor.substring(1)}'));
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: riskColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: riskColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: riskColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getRiskIcon(widget.country.riskLevel),
                color: Colors.white,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Risk Level: ${widget.country.riskLevel}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getRiskDescription(widget.country.riskLevel),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _shareCountryData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text(
                'Share',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _viewDetails();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: const Text(
                'Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel) {
      case 'CRITICAL':
        return Icons.dangerous_rounded;
      case 'HIGH':
        return Icons.warning_rounded;
      case 'MEDIUM':
        return Icons.info_rounded;
      case 'LOW':
        return Icons.check_circle_outline_rounded;
      case 'MINIMAL':
        return Icons.verified_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getRiskDescription(String riskLevel) {
    switch (riskLevel) {
      case 'CRITICAL':
        return 'Very high case density - extreme caution advised';
      case 'HIGH':
        return 'High case density - enhanced precautions recommended';
      case 'MEDIUM':
        return 'Moderate case density - standard precautions advised';
      case 'LOW':
        return 'Low case density - basic precautions recommended';
      case 'MINIMAL':
        return 'Very low case density - minimal risk';
      default:
        return 'Risk level assessment unavailable';
    }
  }

  void _shareCountryData() {
    HapticFeedback.lightImpact();
    
    final shareText = '''
🦠 COVID-19 Data for ${widget.country.country}

📊 Statistics:
• Total Cases: ${widget.country.formattedCases}
• Deaths: ${widget.country.formattedDeaths}
• Recovered: ${widget.country.formattedRecovered}
• Active: ${widget.country.formattedActive}

🚨 Risk Level: ${widget.country.riskLevel}

📱 Shared from COVID-19 Global Tracker
''';

    // You can implement share functionality here
    // For now, copy to clipboard
    Clipboard.setData(ClipboardData(text: shareText));
    
    Get.snackbar(
      'Copied!',
      'Country data copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.accent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }

  void _viewDetails() {
    HapticFeedback.lightImpact();
    widget.onClose();
    
    // Navigate to detailed country view
    // This would integrate with your existing detail screen
    Get.snackbar(
      'Coming Soon',
      'Detailed country view will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }
}