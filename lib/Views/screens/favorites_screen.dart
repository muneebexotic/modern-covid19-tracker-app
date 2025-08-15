import 'package:covid19_tracker_flutter/Controllers/favorites_controller.dart';
import 'package:covid19_tracker_flutter/Services/states_services.dart';
import 'package:covid19_tracker_flutter/Views/screens/detail_screen.dart';
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
                        'Favorite Countries',
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

              // Favorites List
              Expanded(
                child: Obx(() {
                  if (favoritesController.favoriteCountries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 80,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorites yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add countries to favorites to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
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
                          child: CircularProgressIndicator(),
                        );
                      }

                      final favoriteData = snapshot.data!.where((country) {
                        return favoritesController.favoriteCountries
                            .contains(country['country']);
                      }).toList();

                      return ListView.builder(
                        itemCount: favoriteData.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final country = favoriteData[index];
                          return _buildFavoriteCard(country);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> country) {
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip('Cases', country['cases'] ?? 0, Colors.blue),
                          const SizedBox(width: 8),
                          _buildStatChip('Deaths', country['deaths'] ?? 0, Colors.red),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatChip('Recovered', country['recovered'] ?? 0, Colors.green),
                          const SizedBox(width: 8),
                          _buildStatChip('Active', country['active'] ?? 0, Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Remove from favorites button
                IconButton(
                  onPressed: () {
                    favoritesController.toggleFavorite(countryName);
                  },
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${_formatNumber(value.toString())}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
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