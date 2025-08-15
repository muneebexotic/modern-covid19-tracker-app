import 'package:covid19_tracker_flutter/Controllers/favorites_controller.dart';
import 'package:covid19_tracker_flutter/Controllers/theme_controller.dart';
import 'package:covid19_tracker_flutter/Models/WorldStatesModel.dart';
import 'package:covid19_tracker_flutter/Services/states_services.dart';
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
    Color(0xff4285F4),
    Color(0xff1aa260),
    Color(0xffde5246),
  ];

  @override
  Widget build(BuildContext context) {
    StatesServices statesServices = StatesServices();
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header with theme toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'COVID-19 Tracker',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Get.to(() => const FavoritesScreen()),
                              icon: Icon(
                                Icons.favorite,
                                color: Colors.red[400],
                                size: 28,
                              ),
                            ),
                            Obx(() => IconButton(
                              onPressed: themeController.toggleTheme,
                              icon: Icon(
                                themeController.isDarkMode.value
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                size: 28,
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    FutureBuilder(
                      future: statesServices.fetchWorldStateRecords(),
                      builder: (context, AsyncSnapshot<WorldStatesModel> snapshot) {
                        if (!snapshot.hasData) {
                          return Column(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                              SpinKitPulsingGrid(
                                color: const Color(0xff4285F4),
                                size: 100,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Loading global data...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              // Main statistics card
                              GlassmorphismCard(
                                child: Column(
                                  children: [
                                    Text(
                                      'Global Overview',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Pie Chart
                                    
                                    PieChart.PieChart(
                                      dataMap: {
                                        "Total Cases": double.parse(
                                          snapshot.data!.cases!.toString(),
                                        ),
                                        "Recovered": double.parse(
                                          snapshot.data!.recovered.toString(),
                                        ),
                                        "Deaths": double.parse(
                                          snapshot.data!.deaths.toString(),
                                        ),
                                      },
                                      chartValuesOptions: const PieChart.ChartValuesOptions(
                                        showChartValuesInPercentage: true,
                                        chartValueStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      chartRadius: MediaQuery.of(context).size.width / 3.2,
                                      legendOptions: PieChart.LegendOptions(
                                        legendPosition: PieChart.LegendPosition.bottom,
                                        showLegends: true,
                                        legendTextStyle: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                      animationDuration: const Duration(milliseconds: 1200),
                                      chartType: PieChart.ChartType.ring,
                                      colorList: colorList,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Statistics Grid
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                children: [
                                  _buildStatCard(
                                    'Total Cases',
                                    snapshot.data!.cases.toString(),
                                    Icons.coronavirus,
                                    const Color(0xff4285F4),
                                  ),
                                  _buildStatCard(
                                    'Deaths',
                                    snapshot.data!.deaths.toString(),
                                    Icons.dangerous,
                                    const Color(0xffde5246),
                                  ),
                                  _buildStatCard(
                                    'Recovered',
                                    snapshot.data!.recovered.toString(),
                                    Icons.health_and_safety,
                                    const Color(0xff1aa260),
                                  ),
                                  _buildStatCard(
                                    'Active',
                                    snapshot.data!.active.toString(),
                                    Icons.local_hospital,
                                    const Color(0xffff9800),
                                  ),
                                  _buildStatCard(
                                    'Critical',
                                    snapshot.data!.critical.toString(),
                                    Icons.warning,
                                    const Color(0xfff44336),
                                  ),
                                  _buildStatCard(
                                    'Today Deaths',
                                    snapshot.data!.todayDeaths.toString(),
                                    Icons.trending_up,
                                    const Color(0xff9c27b0),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              // Action buttons
                              Column(
                                children: [
                                  _buildActionButton(
                                    'Track Countries',
                                    Icons.public,
                                    const Color(0xff1aa260),
                                    () => Get.to(() => const CountriesListScreen()),
                                  ),
                                  const SizedBox(height: 15),
                                  _buildActionButton(
                                    'View Favorites',
                                    Icons.favorite,
                                    const Color(0xffde5246),
                                    () => Get.to(() => const FavoritesScreen()),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
            size: 30,
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

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return GlassmorphismCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
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