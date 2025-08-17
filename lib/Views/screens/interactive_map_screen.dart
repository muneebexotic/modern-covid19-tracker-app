import 'package:covid19_tracker_flutter/Models/MapDataModel.dart';
import 'package:covid19_tracker_flutter/Views/screens/interactive_map/widgets/cluster_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:covid19_tracker_flutter/Controllers/map_controller.dart'
    as app_map;
import 'package:covid19_tracker_flutter/Controllers/geolocation_controller.dart';
import 'package:covid19_tracker_flutter/Views/screens/interactive_map/widgets/country_popup.dart';
import 'package:covid19_tracker_flutter/Views/screens/interactive_map/widgets/map_controls.dart';
import 'package:covid19_tracker_flutter/Views/screens/interactive_map/widgets/legend_widget.dart';
import 'package:covid19_tracker_flutter/Utils/colors.dart';
import 'package:covid19_tracker_flutter/Utils/text_styles.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'dart:async';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen>
    with TickerProviderStateMixin {
  late final app_map.MapController
      mapController; // <-- Use 'app_map.MapController'
  late final GeolocationController geoController;
  late final flutter_map.MapController
      flutterMapController; // <-- Use 'flutter_map.MapController'

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;

  // Add StreamController for heatmap rebuilding
  late final StreamController<void> _rebuildStream;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    mapController = Get.put(
      app_map.MapController(),
    ); // <-- Use 'app_map.MapController()'
    geoController = Get.put(GeolocationController());
    flutterMapController =
        flutter_map.MapController(); // <-- This line was already correct but now works with the import fix

    // Initialize rebuild stream for heatmap
    _rebuildStream = StreamController<void>.broadcast();

    // Setup animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    // Setup search controller
    _searchController.addListener(() {
      mapController.updateSearchQuery(_searchController.text);
      setState(() {
        _showSearchResults = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _rebuildStream.close(); // Don't forget to close the stream
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffold
          : AppColors.lightScaffold,
      body: Obx(
        () => Stack(
          children: [
            // Main Map
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMapView(isDark),
            ),

            // Loading Overlay
            if (mapController.loading.value)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading map data...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Controls
            if (mapController.showControls.value) ...[
              _buildTopControls(isDark),

              // Search Results Overlay
              if (_showSearchResults) _buildSearchResults(isDark),
            ],

            // Map Controls (Zoom, etc.)
            if (mapController.showControls.value)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 120,
                child: MapControls(
                  mapController: mapController,
                  geoController: geoController,
                  flutterMapController: flutterMapController,
                ),
              ),

            // Legend
            if (mapController.showLegend.value)
              Positioned(
                left: 16,
                bottom: MediaQuery.of(context).padding.bottom + 80,
                child: LegendWidget(mapController: mapController),
              ),

            // Country Popup
            if (mapController.selectedCountry.value != null)
              Positioned.fill(
                child: CountryPopup(
                  country: mapController.selectedCountry.value!,
                  onClose: () => mapController.clearSelection(),
                ),
              ),

            // Bottom Stats Bar
            if (!mapController.isFullscreen.value) _buildBottomStatsBar(isDark),

            // Error Snackbar
            if (mapController.error.value.isNotEmpty)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 16,
                right: 16,
                child: _buildErrorCard(isDark),
              ),
          ],
        ),
      ),
    );
  }

  // Helper function to get the value for the heatmap from your model
  double _getValueForMetric(MapDataModel country) {
    switch (mapController.selectedMetric.value) {
      case 'deaths':
        return country.totalDeaths.toDouble();
      case 'recovered':
        return country.recovered.toDouble();
      case 'active':
        return country.active.toDouble();
      default: // cases
        return country.totalCases.toDouble();
    }
  }

  // Helper function to prepare heatmap data
  List<WeightedLatLng> _prepareHeatmapData() {
    return mapController.filteredCountries.map((country) {
      return WeightedLatLng(
        LatLng(country.latitude, country.longitude),
        _getValueForMetric(country),
      );
    }).toList();
  }

  Widget _buildMapView(bool isDark) {
    return Obx(
      () => flutter_map.FlutterMap(
        mapController: flutterMapController,
        options: flutter_map.MapOptions(
          initialCenter: mapController.currentCenter.value,
          initialZoom: mapController.currentZoom.value,
          minZoom: 1.0,
          maxZoom: 18.0,
          interactionOptions: const flutter_map.InteractionOptions(
            flags: flutter_map.InteractiveFlag.all,
          ),
          onMapEvent: (flutter_map.MapEvent mapEvent) {
            if (mapEvent is flutter_map.MapEventMoveEnd) {
              mapController.setMapCenter(mapEvent.camera.center);
              mapController.zoomTo(mapEvent.camera.zoom);
            }
          },
          onTap: (tapPosition, point) {
            if (mapController.selectedCountry.value != null) {
              mapController.clearSelection();
            }
            setState(() {
              _showSearchResults = false;
            });
            FocusScope.of(context).unfocus();
          },
        ),
        children: [
          // Base Tile Layer
          flutter_map.TileLayer(
            urlTemplate: mapController.getMapTileUrl(),
            subdomains: mapController.getMapSubdomains(),
            userAgentPackageName: 'com.example.covid19_tracker_flutter',
            maxNativeZoom: 19,
          ),

          // Heatmap Overlay (FIXED IMPLEMENTATION)
          if (mapController.showHeatmap.value && mapController.filteredCountries.isNotEmpty)
            HeatMapLayer(
              heatMapDataSource: InMemoryHeatMapDataSource(
                data: _prepareHeatmapData(),
              ),
              heatMapOptions: HeatMapOptions(
                gradient: {
                  0.0: Colors.blue,
                  0.3: Colors.green,
                  0.5: Colors.yellow,
                  0.7: Colors.orange,
                  1.0: Colors.red,
                },
                minOpacity: 0.1,
                radius: 25,
              ),
              reset: _rebuildStream.stream,
            ),

          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 120,
              size: const Size(40, 40),
              markers: mapController.filteredCountries.map((country) {
                return flutter_map.Marker(
                  point: LatLng(country.latitude, country.longitude),
                  width: 40,
                  height: 40,
                  alignment: Alignment.bottomCenter,
                  child: ClusterMarker(
                    countries: [country],
                    selectedMetric: mapController.selectedMetric.value,
                    zoom: flutterMapController.camera.zoom,
                    onTap: () {
                      mapController.selectCountry(country);
                      HapticFeedback.lightImpact();
                    },
                  ),
                );
              }).toList(),
              builder: (context, markers) {
                final countriesInCluster = markers.map((marker) {
                  return mapController.allCountries.firstWhere(
                    (c) =>
                        c.latitude == marker.point.latitude &&
                        c.longitude == marker.point.longitude,
                  );
                }).toList();

                return ClusterMarker(
                  countries: countriesInCluster,
                  selectedMetric: mapController.selectedMetric.value,
                  zoom: flutterMapController.camera.zoom,
                  onTap: () {
                    flutterMapController.fitCamera(
                      flutter_map.CameraFit.bounds(
                        bounds: flutter_map.LatLngBounds.fromPoints(
                          markers.map((m) => m.point).toList(),
                        ),
                        padding: const EdgeInsets.all(50),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls(bool isDark) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                // Back Button
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Get.back(),
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),

                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global COVID Map',
                        style: AppTextStyles.heading(context, size: 20),
                      ),
                      Obx(
                        () => Text(
                          '${mapController.filteredCountries.length} countries',
                          style: AppTextStyles.smallMuted.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Settings Menu
                _buildSettingsMenu(isDark),
              ],
            ),

            const SizedBox(height: 16),

            // Search Bar
            _buildSearchBar(isDark),

            const SizedBox(height: 12),

            // Filter Chips
            _buildFilterChips(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search countries...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _showSearchResults = false;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(
        () => Row(
          children: [
            // Risk Level Filter
            _buildFilterChip(
              'Risk Level',
              mapController.selectedRiskLevel.value,
              mapController.riskLevels,
              (value) => mapController.setRiskLevelFilter(value),
              isDark,
            ),

            const SizedBox(width: 8),

            // Metric Filter
            _buildFilterChip(
              'Metric',
              mapController.selectedMetric.value.capitalize!,
              mapController.metrics.map((m) => m.capitalize!).toList(),
              (value) => mapController.changeMetric(value.toLowerCase()),
              isDark,
            ),

            const SizedBox(width: 8),

            // Map Type Filter
            _buildFilterChip(
              'Map Type',
              mapController.currentMapType.value.capitalize!,
              mapController.mapTypes.map((m) => m.capitalize!).toList(),
              (value) => mapController.changeMapType(value.toLowerCase()),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
              // Trigger heatmap rebuild when filters change
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _rebuildStream.add(null);
              });
            }
          },
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
          dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 140,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Obx(() {
          final results = mapController.filteredCountries.take(5).toList();

          if (results.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No countries found',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final country = results[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse('0xFF${country.riskColor.substring(1)}'),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      country.countryCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  country.country,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${country.formattedCases} cases',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  mapController.selectCountry(country);
                  _searchController.clear();
                  setState(() {
                    _showSearchResults = false;
                  });
                  FocusScope.of(context).unfocus();
                },
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildSettingsMenu(bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark ? Colors.white : Colors.black,
      ),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'refresh':
            mapController.refreshMapData();
            break;
          case 'location':
            geoController.getCurrentLocation();
            break;
          case 'fullscreen':
            mapController.toggleFullscreen();
            break;
          case 'legend':
            mapController.toggleLegend();
            break;
          case 'heatmap':
            mapController.toggleHeatmap();
            // Trigger heatmap rebuild when toggled
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _rebuildStream.add(null);
            });
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(
                Icons.refresh_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Refresh Data',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'location',
          child: Row(
            children: [
              Icon(
                Icons.my_location_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'My Location',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'fullscreen',
          child: Row(
            children: [
              Icon(
                mapController.isFullscreen.value
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                mapController.isFullscreen.value
                    ? 'Exit Fullscreen'
                    : 'Fullscreen',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'legend',
          child: Row(
            children: [
              Icon(
                mapController.showLegend.value
                    ? Icons.legend_toggle_rounded
                    : Icons.legend_toggle_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Toggle Legend',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'heatmap',
          child: Row(
            children: [
              Icon(
                mapController.showHeatmap.value
                    ? Icons.heat_pump_rounded
                    : Icons.heat_pump_outlined,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Toggle Heatmap',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStatsBar(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkCard : AppColors.lightCard)
              .withOpacity(0.95),
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
        ),
        child: Obx(() {
          final stats = mapController.getStatsSummary();
          if (stats.isEmpty) return const SizedBox.shrink();

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Countries',
                '${stats['totalCountries']}',
                AppColors.primary,
                isDark,
              ),
              _buildStatItem(
                'Cases',
                _formatNumber(stats['totalCases']),
                AppColors.danger,
                isDark,
              ),
              _buildStatItem(
                'Deaths',
                _formatNumber(stats['totalDeaths']),
                AppColors.warning,
                isDark,
              ),
              _buildStatItem(
                'Recovered',
                _formatNumber(stats['totalRecovered']),
                AppColors.accent,
                isDark,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mapController.error.value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => mapController.error.value = '',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}