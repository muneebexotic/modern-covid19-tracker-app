import 'package:covid19_tracker_flutter/Controllers/favorites_controller.dart';
import 'package:covid19_tracker_flutter/Controllers/theme_controller.dart';
import 'package:covid19_tracker_flutter/Models/WorldStatesModel.dart';
import 'package:covid19_tracker_flutter/Services/states_service.dart';
import 'package:covid19_tracker_flutter/Views/screens/countries_list.dart';
import 'package:covid19_tracker_flutter/Views/screens/favorites_screen.dart';
import 'package:covid19_tracker_flutter/Views/widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pie_chart/pie_chart.dart' as PieChart;
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

class WorldStatesScreen extends StatefulWidget {
  const WorldStatesScreen({super.key});

  @override
  State<WorldStatesScreen> createState() => _WorldStatesScreenState();
}

class _WorldStatesScreenState extends State<WorldStatesScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  )..repeat();

  late final AnimationController _fadeController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  );

  late final Animation<double> _fadeAnimation;
  final themeController = Get.find<ThemeController>();
  final favoritesController = Get.put(FavoritesController());

  @override
  void initState() {
    super.initState();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  final colorList = const <Color>[
    Color(0xff6366f1),
    Color(0xff10b981),
    Color(0xffef4444),
  ];

  @override
  Widget build(BuildContext context) {
    StatesServices statesServices = StatesServices();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff0f172a) : const Color(0xfff8fafc),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            color: const Color(0xff6366f1),
            child: CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COVID-19',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xff0f172a),
                                    height: 1.2,
                                  ),
                                ),
                                Text(
                                  'Global Tracker',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xff64748b) : const Color(0xff64748b),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _buildIconButton(
                                  icon: Icons.favorite_rounded,
                                  color: const Color(0xffef4444),
                                  onTap: () => Get.to(() => const FavoritesScreen()),
                                ),
                                const SizedBox(width: 8),
                                Obx(() => _buildIconButton(
                                  icon: themeController.isDarkMode.value
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                  color: const Color(0xff6366f1),
                                  onTap: themeController.toggleTheme,
                                )),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Main Content
                SliverToBoxAdapter(
                  child: FutureBuilder(
                    future: statesServices.fetchWorldStateRecords(),
                    builder: (context, AsyncSnapshot<WorldStatesModel> snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SpinKitRing(
                                color: const Color(0xff6366f1),
                                size: 50,
                                lineWidth: 4,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading global data...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? const Color(0xff64748b) : const Color(0xff64748b),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Overview Card
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
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Global Overview',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xff0f172a),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Compact Chart
                                    SizedBox(
                                      height: 200,
                                      child: PieChart.PieChart(
                                        dataMap: {
                                          "Cases": double.parse(snapshot.data!.cases!.toString()),
                                          "Recovered": double.parse(snapshot.data!.recovered.toString()),
                                          "Deaths": double.parse(snapshot.data!.deaths.toString()),
                                        },
                                        chartValuesOptions: const PieChart.ChartValuesOptions(
                                          showChartValuesInPercentage: true,
                                          chartValueStyle: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                          decimalPlaces: 1,
                                        ),
                                        chartRadius: 80,
                                        legendOptions: PieChart.LegendOptions(
                                          showLegends: true,
                                          legendPosition: PieChart.LegendPosition.right,
                                          legendTextStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? const Color(0xff94a3b8) : const Color(0xff64748b),
                                          ),
                                        ),
                                        animationDuration: const Duration(milliseconds: 1200),
                                        chartType: PieChart.ChartType.disc,
                                        colorList: colorList,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),

                              // Key Stats Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactStatCard(
                                      'Total Cases',
                                      snapshot.data!.cases.toString(),
                                      const Color(0xff6366f1),
                                      Icons.coronavirus_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildCompactStatCard(
                                      'Recovered',
                                      snapshot.data!.recovered.toString(),
                                      const Color(0xff10b981),
                                      Icons.health_and_safety_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildCompactStatCard(
                                      'Deaths',
                                      snapshot.data!.deaths.toString(),
                                      const Color(0xffef4444),
                                      Icons.dangerous_rounded,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Secondary Stats
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSecondaryStatCard(
                                      'Active',
                                      snapshot.data!.active.toString(),
                                      const Color(0xfff59e0b),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSecondaryStatCard(
                                      'Critical',
                                      snapshot.data!.critical.toString(),
                                      const Color(0xffec4899),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildSecondaryStatCard(
                                      'Today Deaths',
                                      snapshot.data!.todayDeaths.toString(),
                                      const Color(0xff8b5cf6),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Action Buttons
                              _buildModernActionButton(
                                'Explore Countries',
                                Icons.public_rounded,
                                const Color(0xff6366f1),
                                () => Get.to(() => const CountriesListScreen()),
                              ),
                              const SizedBox(height: 12),
                              _buildModernActionButton(
                                'View Favorites',
                                Icons.favorite_rounded,
                                const Color(0xffef4444),
                                () => Get.to(() => const FavoritesScreen()),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff1e293b) : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCompactStatCard(String title, String value, Color color, IconData icon) {
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
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
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
            _formatNumber(value),
            style: TextStyle(
              fontSize: 18,
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
              color: isDark ? const Color(0xff64748b) : const Color(0xff64748b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStatCard(String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
        children: [
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xff64748b) : const Color(0xff64748b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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
}