import 'dart:math' as math; // <-- Add this import

class GeoLocationModel {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? heading;
  final double? speed;
  final DateTime timestamp;
  final String? address;
  final String? country;
  final String? city;

  GeoLocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.heading,
    this.speed,
    required this.timestamp,
    this.address,
    this.country,
    this.city,
  });

  factory GeoLocationModel.fromPosition(dynamic position, {
    String? address,
    String? country,
    String? city,
  }) {
    return GeoLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      timestamp: position.timestamp ?? DateTime.now(),
      address: address,
      country: country,
      city: city,
    );
  }

  factory GeoLocationModel.fromJson(Map<String, dynamic> json) {
    return GeoLocationModel(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble(),
      altitude: json['altitude']?.toDouble(),
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      address: json['address'],
      country: json['country'],
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'heading': heading,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'country': country,
      'city': city,
    };
  }

  /// Check if location is valid (not null coordinates)
  bool get isValid {
    return latitude != 0.0 && longitude != 0.0;
  }

  /// Get formatted coordinates string
  String get coordinatesString {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Get short coordinates string
  String get shortCoordinatesString {
    return '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
  }

  /// Calculate distance to another location in kilometers
  double distanceTo(GeoLocationModel other) {
    const double earthRadius = 6371; // km
    
    final lat1Rad = latitude * (math.pi / 180);
    final lat2Rad = other.latitude * (math.pi / 180);
    final deltaLatRad = (other.latitude - latitude) * (math.pi / 180);
    final deltaLngRad = (other.longitude - longitude) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  /// Get formatted distance string
  String distanceToString(GeoLocationModel other) {
    final distance = distanceTo(other);
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  /// Check if location is within a certain radius of another location
  bool isWithinRadius(GeoLocationModel other, double radiusKm) {
    return distanceTo(other) <= radiusKm;
  }

  /// Get display name (city, country or coordinates)
  String get displayName {
    if (city != null && country != null) {
      return '$city, $country';
    } else if (country != null) {
      return country!;
    } else if (address != null) {
      return address!;
    }
    return shortCoordinatesString;
  }

  /// Get accuracy description
  String get accuracyDescription {
    if (accuracy == null) return 'Unknown accuracy';
    
    if (accuracy! <= 5) return 'Very high accuracy';
    if (accuracy! <= 10) return 'High accuracy';
    if (accuracy! <= 50) return 'Good accuracy';
    if (accuracy! <= 100) return 'Fair accuracy';
    return 'Low accuracy';
  }

  /// Check if this is a recent location (within last 5 minutes)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes <= 5;
  }

  /// Get age of location data
  String get ageDescription {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Create a copy with updated values
  GeoLocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    DateTime? timestamp,
    String? address,
    String? country,
    String? city,
  }) {
    return GeoLocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      country: country ?? this.country,
      city: city ?? this.city,
    );
  }

  @override
  String toString() {
    return 'GeoLocationModel(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is GeoLocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode ^ timestamp.hashCode;
  }
}