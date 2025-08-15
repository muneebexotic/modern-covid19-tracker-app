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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xff1a1a2e),
                    const Color(0xff16213e),
                    const Color(0xff0f3460),
                  ]
                : [
                    const Color(0xff4285F4).withOpacity(0.1),
                    const Color(0xff1aa260).withOpacity(0.1),
                    const Color(0xffde5246).withOpacity(0.1),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar with Hero Image
              Container(
                height: 200,
                child: Stack(
                  children: [
                    // Background with blur effect
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: Container(
                          color: isDark 
                              ? Colors.grey[900]?.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Top bar with back button and actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _shareCountryData,
                                    icon: Icon(
                                      Icons.share,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Obx(() => IconButton(
                                    onPressed: () {
                                      favoritesController.toggleFavorite(widget.name);
                                    },
                                    icon: Icon(
                                      favoritesController.isFavorite(widget.name)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red[400],
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Country info
                          Row(
                            children: [
                              // Flag
                              Hero(
                                tag: 'flag_${widget.name}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      widget.image,
                                      width: 80,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 80,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.flag, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Country name and risk level
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRiskColor(),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Risk Level: ${_getRiskLevel()}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
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
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.all(16),
                child: GlassmorphismCard(
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xff4285F4),
                    indicatorWeight: 3,
                    labelColor: const Color(0xff4285F4),
                    unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.bar_chart),
                        text: 'Overview',
                      ),
                      Tab(
                        icon: Icon(Icons.trending_up),
                        text: 'Trends',
                      ),
                      Tab(
                        icon: Icon(Icons.vaccines),
                        text: 'Vaccination',
                      ),
                    ],
                  ),
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
      ),
    );
  }

  Widget _buildOverviewTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Quick Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Total Cases',
                widget.totalCases.toString(),
                Icons.coronavirus,
                const Color(0xff4285F4),
              ),
              _buildStatCard(
                'Deaths',
                widget.totalDeaths.toString(),
                Icons.dangerous,
                const Color(0xffde5246),
              ),
              _buildStatCard(
                'Recovered',
                widget.totalRecovered.toString(),
                Icons.health_and_safety,
                const Color(0xff1aa260),
              ),
              _buildStatCard(
                'Active',
                widget.active.toString(),
                Icons.local_hospital,
                const Color(0xffff9800),
              ),
              _buildStatCard(
                'Critical',
                widget.critical.toString(),
                Icons.warning,
                const Color(0xfff44336),
              ),
              _buildStatCard(
                'Tests',
                widget.test.toString(),
                Icons.science,
                const Color(0xff9c27b0),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recovery Rate Card
          GlassmorphismCard(
            child: Column(
              children: [
                Text(
                  'Recovery Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Recovery Rate Progress
                _buildProgressIndicator(
                  'Recovery Rate',
                  widget.totalRecovered,
                  widget.totalCases,
                  const Color(0xff1aa260),
                ),
                
                const SizedBox(height: 12),
                
                // Mortality Rate Progress
                _buildProgressIndicator(
                  'Mortality Rate',
                  widget.totalDeaths,
                  widget.totalCases,
                  const Color(0xffde5246),
                ),
                
                const SizedBox(height: 12),
                
                // Active Cases Progress
                _buildProgressIndicator(
                  'Active Cases',
                  widget.active,
                  widget.totalCases,
                  const Color(0xffff9800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GlassmorphismCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historical Trends (Mock Data)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Line Chart
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatChartNumber(value),
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['7d', '14d', '21d', '30d'];
                              if (value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontSize: 10,
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
                        // Cases line
                        LineChartBarData(
                          spots: _generateMockDataPoints(widget.totalCases.toDouble()),
                          isCurved: true,
                          color: const Color(0xff4285F4),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xff4285F4).withOpacity(0.1),
                          ),
                        ),
                        // Deaths line
                        LineChartBarData(
                          spots: _generateMockDataPoints(widget.totalDeaths.toDouble()),
                          isCurved: true,
                          color: const Color(0xffde5246),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                        // Recovered line
                        LineChartBarData(
                          spots: _generateMockDataPoints(widget.totalRecovered.toDouble()),
                          isCurved: true,
                          color: const Color(0xff1aa260),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Cases', const Color(0xff4285F4)),
                    _buildLegendItem('Deaths', const Color(0xffde5246)),
                    _buildLegendItem('Recovered', const Color(0xff1aa260)),
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
                child: GlassmorphismCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 30,
                        color: Colors.green[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Growth Rate',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${Random().nextInt(5) + 1}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: GlassmorphismCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.speed,
                        size: 30,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Test Rate',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((widget.test / widget.totalCases) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            child: CircularProgressIndicator(),
          );
        }
        
        final vaccination = snapshot.data ?? VaccinationModel();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Vaccination Progress Card
              GlassmorphismCard(
                child: Column(
                  children: [
                    Text(
                      'Vaccination Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Vaccination Chart
                    SizedBox(
                      height: 120,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: PieChart(
                              PieChartData(
                                sections: [
                                  PieChartSectionData(
                                    value: (vaccination.peopleVaccinated ?? 0).toDouble(),
                                    color: const Color(0xff1aa260),
                                    title: 'Vaccinated',
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: (vaccination.peoplePartiallyVaccinated ?? 0).toDouble() - 
                                           (vaccination.peopleVaccinated ?? 0).toDouble(),
                                    color: const Color(0xff4285F4),
                                    title: 'Partial',
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    value: (vaccination.population ?? 1000000).toDouble() - 
                                           (vaccination.peoplePartiallyVaccinated ?? 0).toDouble(),
                                    color: Colors.grey[400]!,
                                    title: 'Unvaccinated',
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildVaccinationLegend(
                                  'Fully Vaccinated',
                                  vaccination.peopleVaccinated ?? 0,
                                  const Color(0xff1aa260),
                                ),
                                _buildVaccinationLegend(
                                  'Partially Vaccinated',
                                  (vaccination.peoplePartiallyVaccinated ?? 0) - 
                                  (vaccination.peopleVaccinated ?? 0),
                                  const Color(0xff4285F4),
                                ),
                                _buildVaccinationLegend(
                                  'Unvaccinated',
                                  (vaccination.population ?? 1000000) - 
                                  (vaccination.peoplePartiallyVaccinated ?? 0),
                                  Colors.grey[400]!,
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
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildVaccinationStatCard(
                    'Total Doses',
                    (vaccination.administered ?? 0).toString(),
                    Icons.vaccines,
                    const Color(0xff4285F4),
                  ),
                  _buildVaccinationStatCard(
                    'Fully Vaccinated',
                    (vaccination.peopleVaccinated ?? 0).toString(),
                    Icons.shield,
                    const Color(0xff1aa260),
                  ),
                  _buildVaccinationStatCard(
                    'Population',
                    (vaccination.population ?? 0).toString(),
                    Icons.people,
                    const Color(0xff9c27b0),
                  ),
                  _buildVaccinationStatCard(
                    'Coverage',
                    '${(((vaccination.peopleVaccinated ?? 0) / (vaccination.population ?? 1) * 100)).toStringAsFixed(1)}%',
                    Icons.analytics,
                    const Color(0xffff9800),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassmorphismCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassmorphismCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            title.contains('%') ? value : _formatNumber(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black54,
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
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
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
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildVaccinationLegend(String title, int value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
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
                    fontSize: 10,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  _formatNumber(value.toString()),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    if (widget.totalCases > 10000000) return Colors.red[700]!;
    if (widget.totalCases > 1000000) return Colors.orange[600]!;
    if (widget.totalCases > 100000) return Colors.yellow[700]!;
    return Colors.green[600]!;
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