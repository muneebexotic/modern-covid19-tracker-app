class MapDataModel {
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  final num totalCases;
  final num totalDeaths;
  final num recovered;
  final num active;
  final num todayCases;
  final num todayDeaths;
  final num population;
  final String flag;

  MapDataModel({
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.totalCases,
    required this.totalDeaths,
    required this.recovered,
    required this.active,
    required this.todayCases,
    required this.todayDeaths,
    required this.population,
    required this.flag,
  });

  factory MapDataModel.fromJson(Map<String, dynamic> json) {
    final countryInfo = json['countryInfo'] ?? {};
    
    return MapDataModel(
      country: json['country'] ?? 'Unknown',
      countryCode: countryInfo['iso2'] ?? 'XX',
      latitude: (countryInfo['lat'] ?? 0.0).toDouble(),
      longitude: (countryInfo['long'] ?? 0.0).toDouble(),
      totalCases: json['cases'] ?? 0,
      totalDeaths: json['deaths'] ?? 0,
      recovered: json['recovered'] ?? 0,
      active: json['active'] ?? 0,
      todayCases: json['todayCases'] ?? 0,
      todayDeaths: json['todayDeaths'] ?? 0,
      population: json['population'] ?? 0,
      flag: countryInfo['flag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'countryCode': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'totalCases': totalCases,
      'totalDeaths': totalDeaths,
      'recovered': recovered,
      'active': active,
      'todayCases': todayCases,
      'todayDeaths': todayDeaths,
      'population': population,
      'flag': flag,
    };
  }

  /// Get risk level based on cases per million
  String get riskLevel {
    if (population == 0) return 'UNKNOWN';
    final casesPerMillion = (totalCases / population) * 1000000;
    
    if (casesPerMillion > 100000) return 'CRITICAL';
    if (casesPerMillion > 50000) return 'HIGH';
    if (casesPerMillion > 20000) return 'MEDIUM';
    if (casesPerMillion > 5000) return 'LOW';
    return 'MINIMAL';
  }

  /// Get risk color based on level
  String get riskColor {
    switch (riskLevel) {
      case 'CRITICAL':
        return '#DC2626'; // Red 600
      case 'HIGH':
        return '#EF4444'; // Red 500
      case 'MEDIUM':
        return '#F59E0B'; // Amber 500
      case 'LOW':
        return '#3B82F6'; // Blue 500
      case 'MINIMAL':
        return '#10B981'; // Emerald 500
      default:
        return '#64748B'; // Slate 500
    }
  }

  /// Get marker size based on total cases
  double get markerSize {
    if (totalCases > 10000000) return 25.0;
    if (totalCases > 5000000) return 20.0;
    if (totalCases > 1000000) return 16.0;
    if (totalCases > 500000) return 12.0;
    if (totalCases > 100000) return 10.0;
    if (totalCases > 10000) return 8.0;
    return 6.0;
  }

  /// Format number for display
  String formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Get formatted cases string
  String get formattedCases => formatNumber(totalCases);
  
  /// Get formatted deaths string
  String get formattedDeaths => formatNumber(totalDeaths);
  
  /// Get formatted recovered string
  String get formattedRecovered => formatNumber(recovered);
  
  /// Get formatted active string
  String get formattedActive => formatNumber(active);

  @override
  String toString() {
    return 'MapDataModel(country: $country, cases: $totalCases, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MapDataModel &&
        other.country == country &&
        other.countryCode == countryCode;
  }

  @override
  int get hashCode {
    return country.hashCode ^ countryCode.hashCode;
  }
}