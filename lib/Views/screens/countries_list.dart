import 'package:covid19_tracker_flutter/Controllers/favorites_controller.dart';
import 'package:covid19_tracker_flutter/Models/CountryDetailModel.dart';
import 'package:covid19_tracker_flutter/Services/states_service.dart';
import 'package:covid19_tracker_flutter/Views/screens/detail_screen/detail_screen.dart';
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
      backgroundColor: isDark
          ? const Color(0xff0f172a)
          : const Color(0xfff8fafc),
      body: SafeArea(
        child: Column(
          children: [
            // Modern App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
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
                        Icons.arrow_back_ios_rounded,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Countries',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
                child: TextFormField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xff0f172a),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    hintText: 'Search countries...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xff64748b)
                          : const Color(0xff64748b),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 16),
                      child: Icon(
                        Icons.search_rounded,
                        color: isDark
                            ? const Color(0xff64748b)
                            : const Color(0xff64748b),
                        size: 20,
                      ),
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              searchController.clear();
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: Icon(
                                Icons.clear_rounded,
                                color: isDark
                                    ? const Color(0xff64748b)
                                    : const Color(0xff64748b),
                                size: 20,
                              ),
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
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Favorites'),
                  _buildFilterChip('High Cases'),
                  _buildFilterChip('Low Cases'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Countries List
            Expanded(
              child: FutureBuilder(
                future: statesServices.countriesListApi(),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (!snapshot.hasData) {
                    return ListView.builder(
                      itemCount: 8,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        return _buildShimmerCard();
                      },
                    );
                  } else {
                    List<dynamic> filteredData = _filterCountries(
                      snapshot.data!,
                    );

                    if (filteredData.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xff64748b).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: const Color(0xff64748b),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No countries found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xff0f172a),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xff64748b),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredData.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final country = filteredData[index];
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    (index * 0.05).clamp(0.0, 1.0),
                                    1.0,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
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
    );
  }

  Widget _buildFilterChip(String filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff6366f1)
                : (isDark ? const Color(0xff1e293b) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xff6366f1)
                  : const Color(0xff64748b).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xff6366f1).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Text(
            filter,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? const Color(0xff94a3b8)
                        : const Color(0xff64748b)),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xff1e293b) : Colors.grey[200]!,
        highlightColor: isDark ? const Color(0xff334155) : Colors.grey[100]!,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 35,
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
                      width: 120,
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
      child: GestureDetector(
        onTap: () {
          final countryDetail = CountryDetail(
            name: countryName,
            flagUrl: country['countryInfo']?['flag'] ?? '',
            totalCases: country['cases'] ?? 0,
            totalRecovered: country['recovered'] ?? 0,
            totalDeaths: country['deaths'] ?? 0,
            active: country['active'] ?? 0,
            test: country['tests'] ?? 0,
            critical: country['critical'] ?? 0,
            todayRecovered: country['todayRecovered'] ?? 0, tests: null,
          );

          Get.to(() => DetailScreen(countryDetail: countryDetail));
        },
        child: Container(
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
          child: Row(
            children: [
              // Flag
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    country['countryInfo']?['flag'] ?? '',
                    width: 50,
                    height: 35,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 35,
                        decoration: BoxDecoration(
                          color: const Color(0xff64748b).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.flag_rounded,
                          color: const Color(0xff64748b),
                          size: 20,
                        ),
                      );
                    },
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
                      countryName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xff0f172a),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cases: ${_formatNumber((country['cases'] ?? 0).toString())}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff64748b),
                      ),
                    ),
                  ],
                ),
              ),

              // Risk Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRiskColor(country['cases'] ?? 0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getRiskLevel(country['cases'] ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Favorite Button
              Obx(
                () => GestureDetector(
                  onTap: () {
                    favoritesController.toggleFavorite(countryName);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: favoritesController.isFavorite(countryName)
                          ? const Color(0xffef4444).withOpacity(0.1)
                          : const Color(0xff64748b).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      favoritesController.isFavorite(countryName)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: favoritesController.isFavorite(countryName)
                          ? const Color(0xffef4444)
                          : const Color(0xff64748b),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
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
    if (cases > 10000000) return const Color(0xffef4444);
    if (cases > 1000000) return const Color(0xfff59e0b);
    if (cases > 100000) return const Color(0xff3b82f6);
    return const Color(0xff10b981);
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
