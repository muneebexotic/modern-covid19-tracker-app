import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:covid19_tracker_flutter/Models/GeoLocationModel.dart';

class GeolocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permissions
  Future<LocationPermission> checkPermissions() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permissions
  Future<LocationPermission> requestPermissions() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location with full permission handling
  Future<GeoLocationModel?> getCurrentLocation({
    bool enableHighAccuracy = true,
  }) async {
    try {
      print('🌍 Checking location services...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        throw LocationServiceException('Location services are disabled. Please enable them in settings.');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions denied');
          throw LocationPermissionException('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions permanently denied');
        throw LocationPermissionException(
          'Location permissions are permanently denied. Please enable them in app settings.'
        );
      }

      print('✅ Location permissions granted, getting position...');

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: enableHighAccuracy 
            ? LocationAccuracy.high 
            : LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      print('📍 Got position: ${position.latitude}, ${position.longitude}');

      // Get address from coordinates
      String? address, country, city;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = _formatAddress(placemark);
          country = placemark.country;
          city = placemark.locality ?? placemark.subAdministrativeArea;
          
          print('📮 Address resolved: $address');
        }
      } catch (e) {
        print('⚠️ Failed to get address: $e');
        // Continue without address info
      }

      return GeoLocationModel.fromPosition(
        position,
        address: address,
        country: country,
        city: city,
      );

    } catch (e) {
      print('❌ Error getting current location: $e');
      rethrow;
    }
  }

  /// Get location from coordinates (reverse geocoding)
  Future<GeoLocationModel?> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      print('🔍 Reverse geocoding: $latitude, $longitude');

      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);
        
        return GeoLocationModel(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          address: address,
          country: placemark.country,
          city: placemark.locality ?? placemark.subAdministrativeArea,
        );
      }

      return GeoLocationModel(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      print('❌ Error in reverse geocoding: $e');
      return GeoLocationModel(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get coordinates from address (forward geocoding)
  Future<GeoLocationModel?> getCoordinatesFromAddress(String address) async {
    try {
      print('🔍 Forward geocoding: $address');

      final locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        
        return GeoLocationModel(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          address: address,
        );
      }

      return null;
    } catch (e) {
      print('❌ Error in forward geocoding: $e');
      return null;
    }
  }

  /// Listen to location changes
  Stream<GeoLocationModel> watchPosition({
    bool enableHighAccuracy = true,
    int distanceFilter = 10, // meters
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: enableHighAccuracy 
            ? LocationAccuracy.high 
            : LocationAccuracy.medium,
        distanceFilter: distanceFilter,
      ),
    ).asyncMap((position) async {
      // Get address for each position update
      String? address, country, city;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = _formatAddress(placemark);
          country = placemark.country;
          city = placemark.locality ?? placemark.subAdministrativeArea;
        }
      } catch (e) {
        print('⚠️ Failed to get address for position update: $e');
      }

      return GeoLocationModel.fromPosition(
        position,
        address: address,
        country: country,
        city: city,
      );
    });
  }

  /// Calculate distance between two points
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // km
  }

  /// Calculate bearing between two points
  double calculateBearing(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  /// Get last known position
  Future<GeoLocationModel?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return GeoLocationModel.fromPosition(position);
    } catch (e) {
      print('❌ Error getting last known position: $e');
      return null;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      print('❌ Error opening location settings: $e');
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      print('❌ Error opening app settings: $e');
      return false;
    }
  }

  /// Get location accuracy description
  String getAccuracyDescription(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.lowest:
        return 'Lowest (~500m)';
      case LocationAccuracy.low:
        return 'Low (~500m)';
      case LocationAccuracy.medium:
        return 'Medium (~100-500m)';
      case LocationAccuracy.high:
        return 'High (~0-100m)';
      case LocationAccuracy.best:
        return 'Best (~0-100m)';
      case LocationAccuracy.bestForNavigation:
        return 'Best for Navigation (~0-100m)';
      default:
        return 'Unknown';
    }
  }

  /// Check if location is within country boundaries (simple approximation)
  Future<bool> isLocationInCountry(
    double latitude,
    double longitude,
    String countryName,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final country = placemarks.first.country?.toLowerCase();
        return country == countryName.toLowerCase();
      }
      return false;
    } catch (e) {
      print('❌ Error checking country boundaries: $e');
      return false;
    }
  }

  /// Get timezone from coordinates using a web service
  Future<String?> getTimezoneFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Using a free timezone API
      final response = await http.get(
        Uri.parse('http://worldtimeapi.org/api/timezone'),
      );

      if (response.statusCode == 200) {
        // This is a simplified implementation
        // You might want to use a more sophisticated timezone API
        final data = json.decode(response.body);
        return data.isNotEmpty ? data[0] : null;
      }
      return null;
    } catch (e) {
      print('❌ Error getting timezone: $e');
      return null;
    }
  }

  /// Validate coordinates
  bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 && 
           latitude <= 90 && 
           longitude >= -180 && 
           longitude <= 180;
  }

  /// Format address from placemark
  String _formatAddress(Placemark placemark) {
    final components = <String>[];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      components.add(placemark.street!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      components.add(placemark.locality!);
    }
    if (placemark.subAdministrativeArea != null && 
        placemark.subAdministrativeArea!.isNotEmpty &&
        placemark.subAdministrativeArea != placemark.locality) {
      components.add(placemark.subAdministrativeArea!);
    }
    if (placemark.administrativeArea != null && 
        placemark.administrativeArea!.isNotEmpty) {
      components.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      components.add(placemark.country!);
    }

    return components.join(', ');
  }

  /// Get location settings for different use cases
  LocationSettings getLocationSettings({
    required LocationAccuracy accuracy,
    int distanceFilter = 0,
    Duration? timeLimit,
  }) {
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }

  /// Get human readable permission status
  String getPermissionStatusDescription(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location access denied';
      case LocationPermission.deniedForever:
        return 'Location access permanently denied';
      case LocationPermission.whileInUse:
        return 'Location access granted while using app';
      case LocationPermission.always:
        return 'Location access always granted';
      default:
        return 'Unknown permission status';
    }
  }
}

/// Custom exceptions for location services
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
  
  @override
  String toString() => 'LocationServiceException: $message';
}

class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);
  
  @override
  String toString() => 'LocationPermissionException: $message';
}

class LocationTimeoutException implements Exception {
  final String message;
  LocationTimeoutException(this.message);
  
  @override
  String toString() => 'LocationTimeoutException: $message';
}