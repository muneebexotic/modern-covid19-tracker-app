import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:covid19_tracker_flutter/Models/MapDataModel.dart';
import 'package:covid19_tracker_flutter/Services/map_service.dart';
import 'dart:math' as math;

/// Controller for Interactive Map Screen
class MapController extends GetxController {
  final MapService _mapService = MapService();
  final mapController = flutter_map.MapController();

  // Reactive state
  final RxList<MapDataModel> allCountries = <MapDataModel>[].obs;
  final RxList<MapDataModel> filteredCountries = <MapDataModel>[].obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final Rxn<MapDataModel> selectedCountry = Rxn<MapDataModel>();
  
  // Map settings
  final Rx<LatLng> currentCenter = const LatLng(20.0, 0.0).obs;
  final RxDouble currentZoom = 2.0.obs;
  final RxString currentMapType = 'standard'.obs;
  final RxBool showHeatmap = false.obs;
  final RxBool showClusters = true.obs;
  final RxString selectedMetric = 'cases'.obs;
  
  // Filters
  final RxString searchQuery = ''.obs;
  final RxString selectedRiskLevel = 'ALL'.obs;
  final RxList<String> selectedRegions = <String>[].obs;
  final RxDouble minCases = 0.0.obs;
  final RxDouble maxCases = 100000000.0.obs;

  // UI state
  final RxBool showLegend = true.obs;
  final RxBool showControls = true.obs;
  final RxBool isFullscreen = false.obs;

  // Available options
  final List<String> mapTypes = ['standard', 'satellite', 'terrain'];
  final List<String> metrics = ['cases', 'deaths', 'recovered', 'active'];
  final List<String> riskLevels = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'MINIMAL'];

  @override
  void onInit() {
    super.onInit();
    loadMapData();
    _setupSearchListener();
  }

  /// Setup search listener with debouncing
  void _setupSearchListener() {
    debounce(searchQuery, (_) => _filterCountries(),
        time: const Duration(milliseconds: 500));
  }

  /// Load all map data
  Future<void> loadMapData() async {
    try {
      loading.value = true;
      error.value = '';

      print('🗺️ MapController: Loading map data...');

      final countries = await _mapService.getAllCountriesMapData();
      
      allCountries.value = countries;
      _filterCountries();

      // Set initial bounds to show all countries
      if (countries.isNotEmpty) {
        _fitMapToCountries(countries);
      }

      print('✅ MapController: Loaded ${countries.length} countries');

    } catch (e, stackTrace) {
      error.value = 'Failed to load map data';
      print('❌ MapController.loadMapData error: $e');
      print('Stack trace: $stackTrace');
    } finally {
      loading.value = false;
    }
  }

  /// Filter countries based on current filters
  void _filterCountries() {
    List<MapDataModel> filtered = List.from(allCountries);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((country) {
        return country.country.toLowerCase().contains(query) ||
               country.countryCode.toLowerCase().contains(query);
      }).toList();
    }

    // Apply risk level filter
    if (selectedRiskLevel.value != 'ALL') {
      filtered = filtered.where((country) {
        return country.riskLevel == selectedRiskLevel.value;
      }).toList();
    }

    // Apply cases range filter
    filtered = filtered.where((country) {
      return country.totalCases >= minCases.value &&
             country.totalCases <= maxCases.value;
    }).toList();

    filteredCountries.value = filtered;
    print('🔍 Filtered to ${filtered.length} countries');
  }

  /// Refresh map data
  Future<void> refreshMapData() async {
    await loadMapData();
  }

  /// Select a country on the map
  void selectCountry(MapDataModel country) {
    selectedCountry.value = country;
    
    // Center map on selected country
    final center = LatLng(country.latitude, country.longitude);
    currentCenter.value = center;
    
    // Zoom in if not already zoomed
    if (currentZoom.value < 5) {
      currentZoom.value = 5.0;
    }

    print('📍 Selected country: ${country.country}');
  }

  /// Clear country selection
  void clearSelection() {
    selectedCountry.value = null;
  }

  /// Set map center
  void setMapCenter(LatLng center, {double? zoom}) {
    currentCenter.value = center;
    if (zoom != null) {
      currentZoom.value = zoom;
    }
  }

  /// Zoom to specific level
  void zoomTo(double zoom) {
    currentZoom.value = zoom.clamp(1.0, 18.0);
  }

  /// Zoom in
  void zoomIn() {
    currentZoom.value = (currentZoom.value + 1).clamp(1.0, 18.0);
  }

  /// Zoom out
  void zoomOut() {
    currentZoom.value = (currentZoom.value - 1).clamp(1.0, 18.0);
  }

  /// Change map type
  void changeMapType(String type) {
    if (mapTypes.contains(type)) {
      currentMapType.value = type;
      print('🗺️ Changed map type to: $type');
    }
  }

  /// Toggle heatmap overlay
  void toggleHeatmap() {
    showHeatmap.value = !showHeatmap.value;
    print('🌡️ Heatmap ${showHeatmap.value ? 'enabled' : 'disabled'}');
  }

  /// Toggle clustering
  void toggleClustering() {
    showClusters.value = !showClusters.value;
    print('🗂️ Clustering ${showClusters.value ? 'enabled' : 'disabled'}');
  }

  /// Change selected metric
  void changeMetric(String metric) {
    if (metrics.contains(metric)) {
      selectedMetric.value = metric;
      print('📊 Changed metric to: $metric');
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Set risk level filter
  void setRiskLevelFilter(String riskLevel) {
    selectedRiskLevel.value = riskLevel;
    _filterCountries();
  }

  /// Set cases range filter
  void setCasesRangeFilter(double min, double max) {
    minCases.value = min;
    maxCases.value = max;
    _filterCountries();
  }

  /// Toggle legend visibility
  void toggleLegend() {
    showLegend.value = !showLegend.value;
  }

  /// Toggle controls visibility
  void toggleControls() {
    showControls.value = !showControls.value;
  }

  /// Toggle fullscreen mode
  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
  }

  /// Fit map to show all countries
  void fitToAllCountries() {
    _fitMapToCountries(filteredCountries);
  }

  /// Fit map to specific countries
  void _fitMapToCountries(List<MapDataModel> countries) {
    if (countries.isEmpty) return;

    double minLat = countries.first.latitude;
    double maxLat = countries.first.latitude;
    double minLng = countries.first.longitude;
    double maxLng = countries.first.longitude;

    for (final country in countries) {
      minLat = math.min(minLat, country.latitude);
      maxLat = math.max(maxLat, country.latitude);
      minLng = math.min(minLng, country.longitude);
      maxLng = math.max(maxLng, country.longitude);
    }

    final bounds = flutter_map.LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Center on bounds
    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    currentCenter.value = center;
    currentZoom.value = _calculateZoomLevel(bounds);
  }

  /// Calculate appropriate zoom level for bounds
  double _calculateZoomLevel(flutter_map.LatLngBounds bounds) {
    final latDiff = (bounds.north - bounds.south).abs();
    final lngDiff = (bounds.east - bounds.west).abs();
    final maxDiff = math.max(latDiff, lngDiff);

    if (maxDiff > 90) return 1.0;
    if (maxDiff > 45) return 2.0;
    if (maxDiff > 20) return 3.0;
    if (maxDiff > 10) return 4.0;
    if (maxDiff > 5) return 5.0;
    if (maxDiff > 2) return 6.0;
    if (maxDiff > 1) return 7.0;
    return 8.0;
  }

  /// Get countries by risk level
  List<MapDataModel> getCountriesByRisk(String riskLevel) {
    return filteredCountries.where((c) => c.riskLevel == riskLevel).toList();
  }

  /// Get top countries by selected metric
  List<MapDataModel> getTopCountries({int limit = 10}) {
    final sorted = List<MapDataModel>.from(filteredCountries);
    
    switch (selectedMetric.value) {
      case 'deaths':
        sorted.sort((a, b) => b.totalDeaths.compareTo(a.totalDeaths));
        break;
      case 'recovered':
        sorted.sort((a, b) => b.recovered.compareTo(a.recovered));
        break;
      case 'active':
        sorted.sort((a, b) => b.active.compareTo(a.active));
        break;
      default: // cases
        sorted.sort((a, b) => b.totalCases.compareTo(a.totalCases));
        break;
    }
    
    return sorted.take(limit).toList();
  }

  /// Get value for country based on selected metric
  num getCountryValue(MapDataModel country) {
    switch (selectedMetric.value) {
      case 'deaths':
        return country.totalDeaths;
      case 'recovered':
        return country.recovered;
      case 'active':
        return country.active;
      default:
        return country.totalCases;
    }
  }

  /// Get statistics summary
  Map<String, dynamic> getStatsSummary() {
    if (filteredCountries.isEmpty) return {};

    final totalCases = filteredCountries.fold<num>(0, (sum, c) => sum + c.totalCases);
    final totalDeaths = filteredCountries.fold<num>(0, (sum, c) => sum + c.totalDeaths);
    final totalRecovered = filteredCountries.fold<num>(0, (sum, c) => sum + c.recovered);
    final totalActive = filteredCountries.fold<num>(0, (sum, c) => sum + c.active);

    return {
      'totalCountries': filteredCountries.length,
      'totalCases': totalCases,
      'totalDeaths': totalDeaths,
      'totalRecovered': totalRecovered,
      'totalActive': totalActive,
      'riskBreakdown': {
        'critical': getCountriesByRisk('CRITICAL').length,
        'high': getCountriesByRisk('HIGH').length,
        'medium': getCountriesByRisk('MEDIUM').length,
        'low': getCountriesByRisk('LOW').length,
        'minimal': getCountriesByRisk('MINIMAL').length,
      }
    };
  }

  /// Get URL for map tiles based on type
  String getMapTileUrl() {
    switch (currentMapType.value) {
      case 'satellite':
        return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
      case 'terrain':
        return 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      default: // standard
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  /// Get map tile subdomains
  List<String> getMapSubdomains() {
    switch (currentMapType.value) {
      case 'satellite':
      case 'terrain':
        return ['mt0', 'mt1', 'mt2', 'mt3'];
      default:
        return ['a', 'b', 'c'];
    }
  }
}

// Import math for calculations
