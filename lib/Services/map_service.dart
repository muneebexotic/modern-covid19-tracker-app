import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:covid19_tracker_flutter/Models/MapDataModel.dart';

class MapService {
  static const String _baseUrl = 'https://disease.sh/v3/covid-19/';
  static const String _countriesEndpoint = 'countries';
  
  /// Fetch all countries with their COVID data and coordinates
  Future<List<MapDataModel>> getAllCountriesMapData() async {
    try {
      print('🗺️ Fetching countries map data...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl$_countriesEndpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        
        // Filter out countries without valid coordinates
        final List<MapDataModel> countries = jsonData
            .map((json) => MapDataModel.fromJson(json))
            .where((country) => 
                country.latitude != 0.0 && 
                country.longitude != 0.0 &&
                country.country != 'MS Zaandam' && // Exclude cruise ship
                country.country != 'Diamond Princess' // Exclude cruise ship
            )
            .toList();

        print('✅ Successfully fetched ${countries.length} countries with map data');
        return countries;
      } else {
        print('❌ Failed to fetch countries map data: ${response.statusCode}');
        throw Exception('Failed to load countries map data: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error in getAllCountriesMapData: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Network error: $e');
    }
  }

  /// Fetch specific country data by name
  Future<MapDataModel?> getCountryMapData(String countryName) async {
    try {
      print('🔍 Fetching map data for: $countryName');
      
      final response = await http.get(
        Uri.parse('$_baseUrl$_countriesEndpoint/${Uri.encodeComponent(countryName)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final country = MapDataModel.fromJson(jsonData);
        
        print('✅ Successfully fetched map data for: ${country.country}');
        return country;
      } else if (response.statusCode == 404) {
        print('⚠️ Country not found: $countryName');
        return null;
      } else {
        print('❌ Failed to fetch country map data: ${response.statusCode}');
        throw Exception('Failed to load country map data: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error in getCountryMapData: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get countries filtered by risk level
  Future<List<MapDataModel>> getCountriesByRiskLevel(String riskLevel) async {
    try {
      final allCountries = await getAllCountriesMapData();
      return allCountries.where((country) => country.riskLevel == riskLevel).toList();
    } catch (e) {
      print('❌ Error filtering countries by risk level: $e');
      return [];
    }
  }

  /// Get top countries by cases
  Future<List<MapDataModel>> getTopCountriesByCases({int limit = 20}) async {
    try {
      final allCountries = await getAllCountriesMapData();
      allCountries.sort((a, b) => b.totalCases.compareTo(a.totalCases));
      return allCountries.take(limit).toList();
    } catch (e) {
      print('❌ Error getting top countries: $e');
      return [];
    }
  }

  /// Get countries within a specific region (bounding box)
  Future<List<MapDataModel>> getCountriesInRegion({
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
  }) async {
    try {
      final allCountries = await getAllCountriesMapData();
      return allCountries.where((country) {
        final lat = country.latitude;
        final lng = country.longitude;
        
        return lat <= northLat &&
               lat >= southLat &&
               lng <= eastLng &&
               lng >= westLng;
      }).toList();
    } catch (e) {
      print('❌ Error getting countries in region: $e');
      return [];
    }
  }

  /// Search countries by name
  Future<List<MapDataModel>> searchCountries(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final allCountries = await getAllCountriesMapData();
      final lowercaseQuery = query.toLowerCase();
      
      return allCountries.where((country) {
        return country.country.toLowerCase().contains(lowercaseQuery) ||
               country.countryCode.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('❌ Error searching countries: $e');
      return [];
    }
  }

  /// Get global statistics for map overview
  Future<Map<String, dynamic>> getGlobalMapStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        return {
          'totalCountries': data['affectedCountries'] ?? 0,
          'totalCases': data['cases'] ?? 0,
          'totalDeaths': data['deaths'] ?? 0,
          'totalRecovered': data['recovered'] ?? 0,
          'activeCases': data['active'] ?? 0,
          'criticalCases': data['critical'] ?? 0,
          'lastUpdated': DateTime.fromMillisecondsSinceEpoch(data['updated'] ?? 0),
        };
      } else {
        throw Exception('Failed to load global statistics');
      }
    } catch (e) {
      print('❌ Error getting global statistics: $e');
      return {};
    }
  }

  /// Get clustering data for map optimization
  Future<List<Map<String, dynamic>>> getClusteringData({
    required double northLat,
    required double southLat,
    required double eastLng,
    required double westLng,
    required double zoomLevel,
  }) async {
    try {
      final countries = await getCountriesInRegion(
        northLat: northLat,
        southLat: southLat,
        eastLng: eastLng,
        westLng: westLng,
      );

      // Simple clustering logic based on zoom level
      if (zoomLevel < 3) {
        // Cluster by continent/region
        return _clusterByRegion(countries);
      } else if (zoomLevel < 5) {
        // Cluster nearby countries
        return _clusterNearbyCountries(countries);
      } else {
        // Show individual countries
        return countries.map((country) => {
          'type': 'individual',
          'country': country,
          'latitude': country.latitude,
          'longitude': country.longitude,
          'totalCases': country.totalCases,
        }).toList();
      }
    } catch (e) {
      print('❌ Error getting clustering data: $e');
      return [];
    }
  }

  /// Simple region-based clustering
  List<Map<String, dynamic>> _clusterByRegion(List<MapDataModel> countries) {
    final Map<String, List<MapDataModel>> regions = {};
    
    for (final country in countries) {
      final region = _getRegionForCountry(country);
      regions[region] ??= [];
      regions[region]!.add(country);
    }

    return regions.entries.map((entry) {
      final regionCountries = entry.value;
      final totalCases = regionCountries.fold<num>(0, (sum, c) => sum + c.totalCases);
      final avgLat = regionCountries.fold<double>(0, (sum, c) => sum + c.latitude) / regionCountries.length;
      final avgLng = regionCountries.fold<double>(0, (sum, c) => sum + c.longitude) / regionCountries.length;

      return {
        'type': 'cluster',
        'region': entry.key,
        'countries': regionCountries,
        'latitude': avgLat,
        'longitude': avgLng,
        'totalCases': totalCases,
        'count': regionCountries.length,
      };
    }).toList();
  }

  /// Get region name for a country based on coordinates
  String _getRegionForCountry(MapDataModel country) {
    final lat = country.latitude;
    final lng = country.longitude;

    // Simple region classification
    if (lat > 35 && lng > -10 && lng < 70) return 'Europe';
    if (lat > -35 && lat < 35 && lng > -20 && lng < 50) return 'Africa';
    if (lat > 10 && lng > 70 && lng < 150) return 'Asia';
    if (lat < 10 && lng > 90 && lng < 180) return 'Southeast Asia';
    if (lng > -170 && lng < -30) return 'Americas';
    if (lng > 110 && lng < 180 && lat < -10) return 'Oceania';
    
    return 'Other';
  }

  /// Simple nearby countries clustering
  List<Map<String, dynamic>> _clusterNearbyCountries(List<MapDataModel> countries) {
    // For now, return individual countries
    // In a real implementation, you'd use a proper clustering algorithm
    return countries.map((country) => {
      'type': 'individual',
      'country': country,
      'latitude': country.latitude,
      'longitude': country.longitude,
      'totalCases': country.totalCases,
    }).toList();
  }
}