import 'dart:math';
import 'package:covid19_tracker_flutter/Controllers/favorites_controller.dart';
import 'package:covid19_tracker_flutter/Models/VaccinationModel.dart';
import 'package:covid19_tracker_flutter/Services/vaccination_service.dart';
import 'package:covid19_tracker_flutter/Views/widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';

class DetailScreen extends StatefulWidget {
  String name;
  String image;
  int totalCases,
      totalRecovered,
      todayRecovered,
      totalDeaths,
      active,
      critical,
      test;
  
  DetailScreen({
    super.key,
    required this.name,
    required this.image,
    required this.totalCases,
    required this.totalRecovered,
    required this.totalDeaths,
    required this.todayRecovered,
    required this.active,
    required this.critical,
    required this.test,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final favoritesController = Get.find<FavoritesController>();
  final VaccinationService vaccinationService = VaccinationService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff1e293b) : Colors.white,
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
                children: [
                  // Top Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xff334155) : const Color(0xfff1f5f9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: isDark ? Colors.white : const Color(0xff0f172a),
                            size: 18,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _shareCountryData,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xff334155) : const Color(0xfff1f5f9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.share_rounded,
                                color: isDark ? Colors.white : const Color(0xff0f172a),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Obx(() => GestureDetector(
                            onTap: () {
                              favoritesController.toggleFavorite(widget.name);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: favoritesController.isFavorite(widget.name)
                                    ? const Color(0xffef4444).withOpacity(0.1)
                                    : (isDark ? const Color(0xff334155) : const Color(0xfff1f5f9)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                favoritesController.isFavorite(widget.name)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: favoritesController.isFavorite(widget.name)
                                    ? const Color(0xffef4444)
                                    : (isDark ? Colors.white : const Color(0xff0f172a)),
                                size: 18,
                              ),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Country Info
                  Row(
                    children: [
                      // Flag
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.image,
                            width: 70,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xff64748b).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.flag_rounded, color: Color(0xff64748b)),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Country Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xff0f172a),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getRiskColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRiskColor().withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Risk Level: ${_getRiskLevel()}',
                                style: TextStyle(
                                  color: _getRiskColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Modern Tab Bar
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff1e293b) : Colors.white,
                borderRadius: BorderRadius.circular(16),
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
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xff6366f1),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? const Color(0xff64748b) : const Color(0xff64748b),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Trends'),
                  Tab(text: 'Vaccination'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildTrendsTab(),
                  _buildVaccinationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Primary Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Cases',
                  widget.totalCases.toString(),
                  Icons.coronavirus_rounded,
                  const Color(0xff6366f1),
                  isLarge: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Deaths',
                  widget.totalDeaths.toString(),
                  Icons.dangerous_rounded,
                  const Color(0xffef4444),
                  isLarge: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Secondary Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Recovered',
                  widget.totalRecovered.toString(),
                  Icons.health_and_safety_rounded,
                  const Color(0xff10b981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  widget.active.toString(),
                  Icons.local_hospital_rounded,
                  const Color(0xfff59e0b),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Tertiary Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Critical',
                  widget.critical.toString(),
                  Icons.warning_rounded,
                  const Color(0xffec4899),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tests',
                  widget.test.toString(),
                  Icons.science_rounded,
                  const Color(0xff8b5cf6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recovery Analysis Card
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
                  'Recovery Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildProgressIndicator(
                  'Recovery Rate',
                  widget.totalRecovered,
                  widget.totalCases,
                  const Color(0xff10b981),
                ),
                
                const SizedBox(height: 16),
                
                _buildProgressIndicator(
                  'Mortality Rate',
                  widget.totalDeaths,
                  widget.totalCases,
                  const Color(0xffef4444),
                ),
                
                const SizedBox(height: 16),
                
                _buildProgressIndicator(
                  'Active Cases',
                  widget.active,
                  widget.totalCases,
                  const Color(0xfff59e0b),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Chart Container
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
                  'Historical Trends',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last 30 days (Simulated data)',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xff64748b),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Line Chart
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: const Color(0xff64748b).withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatChartNumber(value),
                                style: TextStyle(
                                  color: const Color(0xff64748b),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const days = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
                              if (value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: const Color(0xff64748b),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateMockDataPoints(widget.totalCases.toDouble()),
                          isCurved: true,
                          color: const Color(0xff6366f1),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xff6366f1).withOpacity(0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: _generateMockDataPoints(widget.totalDeaths.toDouble()),
                          isCurved: true,
                          color: const Color(0xffef4444),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: _generateMockDataPoints(widget.totalRecovered.toDouble()),
                          isCurved: true,
                          color: const Color(0xff10b981),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Cases', const Color(0xff6366f1)),
                    _buildLegendItem('Deaths', const Color(0xffef4444)),
                    _buildLegendItem('Recovered', const Color(0xff10b981)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Growth Rate Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Growth Rate',
                  '+${Random().nextInt(5) + 1}%',
                  Icons.trending_up_rounded,
                  const Color(0xff10b981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Test Rate',
                  '${((widget.test / widget.totalCases) * 100).toStringAsFixed(1)}%',
                  Icons.speed_rounded,
                  const Color(0xff6366f1),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVaccinationTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<VaccinationModel>(
      future: vaccinationService.getCountryVaccination(widget.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff6366f1)),
          );
        }
        
        final vaccination = snapshot.data ?? VaccinationModel();
        
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
                                    value: (vaccination.peopleVaccinated ?? 0).toDouble(),
                                    color: const Color(0xff10b981),
                                    title: '${((vaccination.peopleVaccinated ?? 0) / (vaccination.population ?? 1) * 100).toStringAsFixed(1)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: (vaccination.peoplePartiallyVaccinated ?? 0).toDouble() - 
                                           (vaccination.peopleVaccinated ?? 0).toDouble(),
                                    color: const Color(0xff6366f1),
                                    title: '${(((vaccination.peoplePartiallyVaccinated ?? 0) - (vaccination.peopleVaccinated ?? 0)) / (vaccination.population ?? 1) * 100).toStringAsFixed(1)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    radius: 50,
                                  ),
                                  PieChartSectionData(
                                    value: (vaccination.population ?? 1000000).toDouble() - 
                                           (vaccination.peoplePartiallyVaccinated ?? 0).toDouble(),
                                    color: const Color(0xff64748b).withOpacity(0.3),
                                    title: '${(((vaccination.population ?? 1000000) - (vaccination.peoplePartiallyVaccinated ?? 0)) / (vaccination.population ?? 1000000) * 100).toStringAsFixed(1)}%',
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
                                  vaccination.peopleVaccinated ?? 0,
                                  const Color(0xff10b981),
                                ),
                                const SizedBox(height: 12),
                                _buildVaccinationLegend(
                                  'Partially Vaccinated',
                                  (vaccination.peoplePartiallyVaccinated ?? 0) - 
                                  (vaccination.peopleVaccinated ?? 0),
                                  const Color(0xff6366f1),
                                ),
                                const SizedBox(height: 12),
                                _buildVaccinationLegend(
                                  'Unvaccinated',
                                  (vaccination.population ?? 1000000) - 
                                  (vaccination.peoplePartiallyVaccinated ?? 0),
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
                      (vaccination.peopleVaccinated ?? 0).toString(),
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
                      (vaccination.population ?? 0).toString(),
                      Icons.people_rounded,
                      const Color(0xff8b5cf6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVaccinationStatCard(
                      'Coverage',
                      '${(((vaccination.peopleVaccinated ?? 0) / (vaccination.population ?? 1) * 100)).toStringAsFixed(1)}%',
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isLarge = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
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
          Container(
            width: isLarge ? 40 : 32,
            height: isLarge ? 40 : 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: isLarge ? 22 : 18,
            ),
          ),
          SizedBox(height: isLarge ? 16 : 12),
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: isLarge ? 24 : 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xff0f172a),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff64748b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xff0f172a),
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xff64748b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff64748b),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String title, int value, int total, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = total > 0 ? (value / total) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xff0f172a),
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff334155) : const Color(0xfff1f5f9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xff64748b),
          ),
        ),
      ],
    );
  }

  Widget _buildVaccinationLegend(String title, int value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff64748b),
                ),
              ),
              Text(
                _formatNumber(value.toString()),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xff0f172a),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateMockDataPoints(double maxValue) {
    final random = Random();
    return List.generate(4, (index) {
      final baseValue = maxValue * (0.7 + (index * 0.1));
      final variance = maxValue * 0.1;
      final value = baseValue + (random.nextDouble() - 0.5) * variance;
      return FlSpot(index.toDouble(), value.clamp(0, double.infinity));
    });
  }

  Color _getRiskColor() {
    if (widget.totalCases > 10000000) return const Color(0xffef4444);
    if (widget.totalCases > 1000000) return const Color(0xfff59e0b);
    if (widget.totalCases > 100000) return const Color(0xff3b82f6);
    return const Color(0xff10b981);
  }

  String _getRiskLevel() {
    if (widget.totalCases > 10000000) return 'HIGH';
    if (widget.totalCases > 1000000) return 'MEDIUM';
    if (widget.totalCases > 100000) return 'LOW';
    return 'MINIMAL';
  }

  void _shareCountryData() {
    final text = '''
🦠 COVID-19 Data for ${widget.name}

📊 Statistics:
• Total Cases: ${_formatNumber(widget.totalCases.toString())}
• Deaths: ${_formatNumber(widget.totalDeaths.toString())}
• Recovered: ${_formatNumber(widget.totalRecovered.toString())}
• Active: ${_formatNumber(widget.active.toString())}
• Critical: ${_formatNumber(widget.critical.toString())}

📱 Shared from COVID-19 Tracker App
    ''';
    
    Share.share(text);
  }

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

  String _formatChartNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toInt().toString();
  }
}