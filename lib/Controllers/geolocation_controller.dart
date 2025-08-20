import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:covid19_tracker_flutter/Models/GeoLocationModel.dart';
import 'package:covid19_tracker_flutter/Services/geolocation_service.dart';
import 'dart:math' as math;

/// Controller for Geolocation functionality
class GeolocationController extends GetxController {
  final GeolocationService _geolocationService = GeolocationService();

  // Reactive state
  final Rxn<GeoLocationModel> currentLocation = Rxn<GeoLocationModel>();
  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final Rx<LocationPermission> permissionStatus = LocationPermission.denied.obs;
  final RxBool serviceEnabled = false.obs;
  final RxBool isTracking = false.obs;

  // Location settings
  final RxBool highAccuracyEnabled = true.obs;
  final RxInt distanceFilter = 10.obs; // meters
  final RxBool autoUpdate = false.obs;

  // Location history
  final RxList<GeoLocationModel> locationHistory = <GeoLocationModel>[].obs;
  final RxInt maxHistoryLength = 50.obs;

  // Streaming
  StreamSubscription<GeoLocationModel>? _locationSubscription;

  @override
  void onInit() {
    super.onInit();
    _checkInitialStatus();
  }

  @override
  void onClose() {
    stopLocationTracking();
    super.onClose();
  }

  /// Check initial location service and permission status
  Future<void> _checkInitialStatus() async {
    await checkLocationService();
    await checkPermissionStatus();
  }

  /// Check if location service is enabled
  Future<void> checkLocationService() async {
    try {
      serviceEnabled.value = await _geolocationService
          .isLocationServiceEnabled();
      print('📍 Location service enabled: ${serviceEnabled.value}');
    } catch (e) {
      print('❌ Error checking location service: $e');
      serviceEnabled.value = false;
    }
  }

  /// Check current permission status
  Future<void> checkPermissionStatus() async {
    try {
      permissionStatus.value = await _geolocationService.checkPermissions();
      print('🔐 Permission status: ${permissionStatus.value}');
    } catch (e) {
      print('❌ Error checking permissions: $e');
      permissionStatus.value = LocationPermission.denied;
    }
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    try {
      loading.value = true;
      error.value = '';

      print('🔑 Requesting location permission...');

      permissionStatus.value = await _geolocationService.requestPermissions();

      final granted =
          permissionStatus.value == LocationPermission.whileInUse ||
          permissionStatus.value == LocationPermission.always;

      if (granted) {
        print('✅ Location permission granted');
        await checkLocationService();
      } else {
        error.value = _geolocationService.getPermissionStatusDescription(
          permissionStatus.value,
        );
        print('❌ Location permission denied: ${permissionStatus.value}');
      }

      return granted;
    } catch (e) {
      error.value = 'Failed to request location permission';
      print('❌ Error requesting permission: $e');
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// Get current location
  Future<GeoLocationModel?> getCurrentLocation({bool force = false}) async {
    try {
      loading.value = true;
      error.value = '';

      print('📍 Getting current location...');

      // Check permissions first
      if (!await _ensureLocationEnabled()) {
        return null;
      }

      final location = await _geolocationService.getCurrentLocation(
        enableHighAccuracy: highAccuracyEnabled.value,
      );

      if (location != null) {
        currentLocation.value = location;
        _addToHistory(location);
        print('✅ Got current location: ${location.displayName}');
      }

      return location;
    } catch (e) {
      if (e.toString().contains('Location services')) {
        error.value = 'Location services are disabled';
      } else if (e.toString().contains('permission')) {
        error.value = 'Location permission required';
      } else {
        error.value = 'Failed to get location';
      }
      print('❌ Error getting current location: $e');
      return null;
    } finally {
      loading.value = false;
    }
  }

  /// Start location tracking
  Future<void> startLocationTracking() async {
    try {
      if (isTracking.value) {
        print('⚠️ Already tracking location');
        return;
      }

      if (!await _ensureLocationEnabled()) {
        return;
      }

      print('🎯 Starting location tracking...');

      isTracking.value = true;

      _locationSubscription = _geolocationService
          .watchPosition(
            enableHighAccuracy: highAccuracyEnabled.value,
            distanceFilter: distanceFilter.value,
          )
          .listen(
            (location) {
              currentLocation.value = location;
              _addToHistory(location);
              print('📍 Location updated: ${location.shortCoordinatesString}');
            },
            onError: (e) {
              error.value = 'Location tracking error';
              print('❌ Location tracking error: $e');
              stopLocationTracking();
            },
          );

      print('✅ Location tracking started');
    } catch (e) {
      error.value = 'Failed to start location tracking';
      print('❌ Error starting location tracking: $e');
      isTracking.value = false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    if (_locationSubscription != null) {
      _locationSubscription!.cancel();
      _locationSubscription = null;
      isTracking.value = false;
      print('🛑 Location tracking stopped');
    }
  }

  /// Toggle location tracking
  Future<void> toggleLocationTracking() async {
    if (isTracking.value) {
      stopLocationTracking();
    } else {
      await startLocationTracking();
    }
  }

  /// Get last known position
  Future<GeoLocationModel?> getLastKnownPosition() async {
    try {
      loading.value = true;

      final location = await _geolocationService.getLastKnownPosition();
      if (location != null) {
        currentLocation.value = location;
        print('📍 Got last known position: ${location.displayName}');
      }

      return location;
    } catch (e) {
      print('❌ Error getting last known position: $e');
      return null;
    } finally {
      loading.value = false;
    }
  }

  /// Get location from coordinates
  Future<GeoLocationModel?> getLocationFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      loading.value = true;

      return await _geolocationService.getLocationFromCoordinates(
        latitude,
        longitude,
      );
    } catch (e) {
      print('❌ Error getting location from coordinates: $e');
      return null;
    } finally {
      loading.value = false;
    }
  }

  /// Get coordinates from address
  Future<GeoLocationModel?> searchAddress(String address) async {
    try {
      if (address.trim().isEmpty) return null;

      loading.value = true;
      error.value = '';

      final location = await _geolocationService.getCoordinatesFromAddress(
        address,
      );

      if (location != null) {
        print(
          '🔍 Found location for "$address": ${location.coordinatesString}',
        );
      } else {
        error.value = 'Address not found';
      }

      return location;
    } catch (e) {
      error.value = 'Failed to search address';
      print('❌ Error searching address: $e');
      return null;
    } finally {
      loading.value = false;
    }
  }

  /// Calculate distance to a point
  double calculateDistance(double latitude, double longitude) {
    final current = currentLocation.value;
    if (current == null) return 0.0;

    return _geolocationService.calculateDistance(
      current.latitude,
      current.longitude,
      latitude,
      longitude,
    );
  }

  /// Calculate bearing to a point
  double calculateBearing(double latitude, double longitude) {
    final current = currentLocation.value;
    if (current == null) return 0.0;

    return _geolocationService.calculateBearing(
      current.latitude,
      current.longitude,
      latitude,
      longitude,
    );
  }

  /// Update location settings
  void updateSettings({
    bool? highAccuracy,
    int? distanceFilter,
    bool? newAutoUpdate, // Renamed parameter
  }) {
    bool needsRestart = false;

    if (highAccuracy != null && highAccuracy != highAccuracyEnabled.value) {
      highAccuracyEnabled.value = highAccuracy;
      needsRestart = true;
    }

    if (distanceFilter != null && distanceFilter != this.distanceFilter.value) {
      this.distanceFilter.value = distanceFilter;
      needsRestart = true;
    }

    if (newAutoUpdate != null) {
      autoUpdate.value = newAutoUpdate; // Correctly assigns the value
    }

    // Restart tracking if settings changed and currently tracking
    if (needsRestart && isTracking.value) {
      stopLocationTracking();
      Future.delayed(const Duration(milliseconds: 500), () {
        startLocationTracking();
      });
    }

    print('⚙️ Location settings updated');
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await _geolocationService.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _geolocationService.openAppSettings();
  }

  /// Clear location history
  void clearHistory() {
    locationHistory.clear();
    print('🗑️ Location history cleared');
  }

  /// Get formatted permission status
  String get permissionStatusText {
    return _geolocationService.getPermissionStatusDescription(
      permissionStatus.value,
    );
  }

  /// Check if location features are available
  bool get isLocationAvailable {
    return serviceEnabled.value &&
        (permissionStatus.value == LocationPermission.whileInUse ||
            permissionStatus.value == LocationPermission.always);
  }

  /// Get accuracy description
  String get accuracyDescription {
    final current = currentLocation.value;
    if (current?.accuracy == null) return 'Unknown';
    return current!.accuracyDescription;
  }

  /// Get location age
  String get locationAge {
    final current = currentLocation.value;
    if (current == null) return 'No location';
    return current.ageDescription;
  }

  /// Ensure location is enabled (service + permission)
  Future<bool> _ensureLocationEnabled() async {
    // Check service
    if (!serviceEnabled.value) {
      await checkLocationService();
      if (!serviceEnabled.value) {
        error.value = 'Location services are disabled';
        return false;
      }
    }

    // Check permissions
    final hasPermission =
        permissionStatus.value == LocationPermission.whileInUse ||
        permissionStatus.value == LocationPermission.always;

    if (!hasPermission) {
      await checkPermissionStatus();
      final stillNoPermission =
          permissionStatus.value != LocationPermission.whileInUse &&
          permissionStatus.value != LocationPermission.always;

      if (stillNoPermission) {
        error.value = 'Location permission required';
        return false;
      }
    }

    return true;
  }

  /// Add location to history
  void _addToHistory(GeoLocationModel location) {
    // Don't add if it's the same as the last location
    if (locationHistory.isNotEmpty) {
      final lastLocation = locationHistory.last;
      if (lastLocation.latitude == location.latitude &&
          lastLocation.longitude == location.longitude) {
        return;
      }
    }

    locationHistory.add(location);

    // Limit history size
    while (locationHistory.length > maxHistoryLength.value) {
      locationHistory.removeAt(0);
    }

    print(
      '📝 Added location to history (${locationHistory.length}/${maxHistoryLength.value})',
    );
  }

  /// Get nearby locations from history
  List<GeoLocationModel> getNearbyLocations(double radiusKm) {
    final current = currentLocation.value;
    if (current == null) return [];

    return locationHistory.where((location) {
      return current.isWithinRadius(location, radiusKm);
    }).toList();
  }

  /// Get location statistics
  Map<String, dynamic> getLocationStats() {
    if (locationHistory.isEmpty) return {};

    final locations = locationHistory;
    double totalDistance = 0.0;
    double maxSpeed = 0.0;
    double? minAccuracy;
    double? maxAccuracy;

    for (int i = 0; i < locations.length; i++) {
      final location = locations[i];

      // Calculate distance between consecutive points
      if (i > 0) {
        totalDistance += locations[i - 1].distanceTo(location);
      }

      // Track speed
      if (location.speed != null) {
        maxSpeed = math.max(maxSpeed, location.speed!);
      }

      // Track accuracy
      if (location.accuracy != null) {
        if (minAccuracy == null || location.accuracy! < minAccuracy) {
          minAccuracy = location.accuracy;
        }
        if (maxAccuracy == null || location.accuracy! > maxAccuracy) {
          maxAccuracy = location.accuracy;
        }
      }
    }

    final timeSpan = locations.isNotEmpty && locations.length > 1
        ? locations.last.timestamp.difference(locations.first.timestamp)
        : Duration.zero;

    return {
      'totalPoints': locations.length,
      'totalDistance': totalDistance, // km
      'maxSpeed': maxSpeed, // m/s
      'minAccuracy': minAccuracy, // meters
      'maxAccuracy': maxAccuracy, // meters
      'timeSpan': timeSpan,
      'averageSpeed': timeSpan.inSeconds > 0
          ? (totalDistance * 1000) /
                timeSpan
                    .inSeconds // m/s
          : 0.0,
    };
  }

  /// Export location data
  Map<String, dynamic> exportLocationData() {
    return {
      'currentLocation': currentLocation.value?.toJson(),
      'locationHistory': locationHistory.map((l) => l.toJson()).toList(),
      'settings': {
        'highAccuracyEnabled': highAccuracyEnabled.value,
        'distanceFilter': distanceFilter.value,
        'autoUpdate': autoUpdate.value,
      },
      'status': {
        'permissionStatus': permissionStatus.value.toString(),
        'serviceEnabled': serviceEnabled.value,
        'isTracking': isTracking.value,
      },
      'stats': getLocationStats(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import location data
  void importLocationData(Map<String, dynamic> data) {
    try {
      // Import current location
      if (data['currentLocation'] != null) {
        currentLocation.value = GeoLocationModel.fromJson(
          data['currentLocation'],
        );
      }

      // Import history
      if (data['locationHistory'] != null) {
        final List<dynamic> historyData = data['locationHistory'];
        locationHistory.value = historyData
            .map((json) => GeoLocationModel.fromJson(json))
            .toList();
      }

      // Import settings
      if (data['settings'] != null) {
        final settings = data['settings'];
        highAccuracyEnabled.value = settings['highAccuracyEnabled'] ?? true;
        distanceFilter.value = settings['distanceFilter'] ?? 10;
        autoUpdate.value = settings['autoUpdate'] ?? false;
      }

      print('📥 Location data imported successfully');
    } catch (e) {
      print('❌ Error importing location data: $e');
    }
  }

  /// Get location summary for display
  String get locationSummary {
    final current = currentLocation.value;
    if (current == null) return 'No location available';

    final accuracy = current.accuracy != null
        ? ' (±${current.accuracy!.round()}m)'
        : '';

    return '${current.displayName}$accuracy';
  }

  /// Check if current location is stale (older than 5 minutes)
  bool get isLocationStale {
    final current = currentLocation.value;
    if (current == null) return true;

    final now = DateTime.now();
    final age = now.difference(current.timestamp);
    return age.inMinutes > 5;
  }

  /// Force refresh current location
  Future<void> refreshLocation() async {
    await getCurrentLocation(force: true);
  }

  /// Get distance string to a point
  String getDistanceString(double latitude, double longitude) {
    final current = currentLocation.value;
    if (current == null) return 'Unknown distance';

    final distance = calculateDistance(latitude, longitude);
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    }
    return '${distance.toStringAsFixed(1)}km away';
  }

  /// Get bearing string to a point
  String getBearingString(double latitude, double longitude) {
    final bearing = calculateBearing(latitude, longitude);

    // Convert bearing to compass direction
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;

    return directions[index];
  }
}
