import 'package:covid19_tracker_flutter/Controllers/favorites_controller.dart';
import 'package:covid19_tracker_flutter/Models/CountryDetailModel.dart';
import 'package:covid19_tracker_flutter/Services/states_service.dart';
import 'package:covid19_tracker_flutter/Views/screens/detail_screen/detail_screen.dart';
import 'package:covid19_tracker_flutter/Views/widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final favoritesController = Get.find<FavoritesController>();
  final StatesServices statesServices = StatesServices();

  @override
  Widget build(BuildContext context) {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Favorites',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xff0f172a),
                            height: 1.2,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${favoritesController.favoriteCountries.length} countries',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xff64748b),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Favorites List
            Expanded(
              child: Obx(() {
                if (favoritesController.favoriteCountries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xffef4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            size: 60,
                            color: const Color(0xffef4444).withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No favorites yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xff0f172a),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add countries to favorites to see them here.\nTap the heart icon on any country card.',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xff64748b),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff6366f1),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xff6366f1,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.explore_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Explore Countries',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder(
                  future: statesServices.countriesListApi(),
                  builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff6366f1),
                        ),
                      );
                    }

                    final favoriteData = snapshot.data!.where((country) {
                      return favoritesController.favoriteCountries.contains(
                        country['country'],
                      );
                    }).toList();

                    return ListView.builder(
                      itemCount: favoriteData.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final country = favoriteData[index];
                        return _buildFavoriteCard(country, index);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> country, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryName = country['country'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            todayRecovered: country['todayRecovered'] ?? 0,
            tests: null,
          );

          Get.to(() => DetailScreen(countryDetail: countryDetail));
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff1e293b) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  // Flag
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
                              color: const Color(0xff64748b).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.flag_rounded,
                              color: const Color(0xff64748b),
                              size: 24,
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
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xff0f172a),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRiskColor(
                              country['cases'] ?? 0,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getRiskColor(
                                country['cases'] ?? 0,
                              ).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Risk: ${_getRiskLevel(country['cases'] ?? 0)}',
                            style: TextStyle(
                              color: _getRiskColor(country['cases'] ?? 0),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remove from favorites button
                  GestureDetector(
                    onTap: () {
                      favoritesController.toggleFavorite(countryName);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xffef4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xffef4444),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatChip(
                      'Cases',
                      country['cases'] ?? 0,
                      const Color(0xff6366f1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactStatChip(
                      'Deaths',
                      country['deaths'] ?? 0,
                      const Color(0xffef4444),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactStatChip(
                      'Recovered',
                      country['recovered'] ?? 0,
                      const Color(0xff10b981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactStatChip(
                      'Active',
                      country['active'] ?? 0,
                      const Color(0xfff59e0b),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatChip(String label, int value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            _formatNumber(value.toString()),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xff64748b),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(int cases) {
    if (cases > 10000000) return const Color(0xffef4444);
    if (cases > 1000000) return const Color(0xfff59e0b);
    if (cases > 100000) return const Color(0xff3b82f6);
    return const Color(0xff10b981);
  }

  String _getRiskLevel(int cases) {
    if (cases > 10000000) return 'HIGH';
    if (cases > 1000000) return 'MEDIUM';
    if (cases > 100000) return 'LOW';
    return 'MINIMAL';
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
