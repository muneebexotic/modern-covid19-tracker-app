import 'package:covid19_tracker_flutter/Controllers/favorites_controller.dart';
import 'package:covid19_tracker_flutter/Services/states_services.dart';
import 'package:covid19_tracker_flutter/Views/screens/detail_screen.dart';
import 'package:covid19_tracker_flutter/Views/widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';

class CountriesListScreen extends StatefulWidget {
  const CountriesListScreen({super.key});

  @override
  State<CountriesListScreen> createState() => _CountriesListScreenState();
}

class _CountriesListScreenState extends State<CountriesListScreen>
    with TickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  final favoritesController = Get.find<FavoritesController>();
  late AnimationController _animationController;
  String selectedFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Countries',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GlassmorphismCard(
                  child: TextFormField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      hintText: 'Search countries...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.clear,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filter Chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Favorites'),
                    _buildFilterChip('High Cases'),
                    _buildFilterChip('Low Cases'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Countries List
              Expanded(
                child: FutureBuilder(
                  future: statesServices.countriesListApi(),
                  builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                    if (!snapshot.hasData) {
                      return ListView.builder(
                        itemCount: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          return _buildShimmerCard();
                        },
                      );
                    } else {
                      List<dynamic> filteredData = _filterCountries(snapshot.data!);
                      
                      if (filteredData.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No countries found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredData.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final country = filteredData[index];
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                index * 0.1,
                                1.0,
                                curve: Curves.easeOut,
                              ),
                            )),
                            child: _buildCountryCard(country),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedFilter == filter;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(
          filter,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFilter = filter;
          });
        },
        backgroundColor: isDark 
            ? Colors.grey[800]?.withOpacity(0.3)
            : Colors.white.withOpacity(0.7),
        selectedColor: const Color(0xff4285F4),
        checkmarkColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
    );
  }

  Widget _buildShimmerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: GlassmorphismCard(
          child: Row(
            children: [
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryCard(Map<String, dynamic> country) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryName = country['country'] ?? 'Unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphismCard(
        child: InkWell(
          onTap: () {
            Get.to(() => DetailScreen(
              name: countryName,
              image: country['countryInfo']?['flag'] ?? '',
              totalCases: country['cases'] ?? 0,
              totalRecovered: country['recovered'] ?? 0,
              totalDeaths: country['deaths'] ?? 0,
              test: country['tests'] ?? 0,
              active: country['active'] ?? 0,
              critical: country['critical'] ?? 0,
              todayRecovered: country['todayRecovered'] ?? 0,
            ));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Flag
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    country['countryInfo']?['flag'] ?? '',
                    width: 60,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Country Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countryName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cases: ${_formatNumber((country['cases'] ?? 0).toString())}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Risk Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRiskColor(country['cases'] ?? 0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRiskLevel(country['cases'] ?? 0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Favorite Button
                Obx(() => IconButton(
                  onPressed: () {
                    favoritesController.toggleFavorite(countryName);
                  },
                  icon: Icon(
                    favoritesController.isFavorite(countryName)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red[400],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _filterCountries(List<dynamic> countries) {
    List<dynamic> filtered = countries;

    // Apply search filter
    if (searchController.text.isNotEmpty) {
      filtered = filtered.where((country) {
        final name = (country['country'] ?? '').toString().toLowerCase();
        return name.contains(searchController.text.toLowerCase());
      }).toList();
    }

    // Apply category filter
    switch (selectedFilter) {
      case 'Favorites':
        filtered = filtered.where((country) {
          return favoritesController.isFavorite(country['country'] ?? '');
        }).toList();
        break;
      case 'High Cases':
        filtered.sort((a, b) => (b['cases'] ?? 0).compareTo(a['cases'] ?? 0));
        filtered = filtered.take(20).toList();
        break;
      case 'Low Cases':
        filtered.sort((a, b) => (a['cases'] ?? 0).compareTo(b['cases'] ?? 0));
        filtered = filtered.take(20).toList();
        break;
    }

    return filtered;
  }

  Color _getRiskColor(int cases) {
    if (cases > 10000000) return Colors.red[700]!;
    if (cases > 1000000) return Colors.orange[600]!;
    if (cases > 100000) return Colors.yellow[700]!;
    return Colors.green[600]!;
  }

  String _getRiskLevel(int cases) {
    if (cases > 10000000) return 'HIGH';
    if (cases > 1000000) return 'MED';
    if (cases > 100000) return 'LOW';
    return 'MIN';
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