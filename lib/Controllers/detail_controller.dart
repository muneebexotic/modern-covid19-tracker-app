import 'package:covid19_tracker_flutter/Models/CountryDetailModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:covid19_tracker_flutter/Models/VaccinationModel.dart';
import 'package:covid19_tracker_flutter/Services/vaccination_service.dart';
import 'dart:math';

/// Controller for Detail Screen
/// - Fetches vaccination data
/// - Prepares chart data (non-random deterministic series for stability)
/// - Exposes risk label / color
class DetailController extends GetxController {
  final VaccinationService _vaccinationService;
  final CountryDetail countryDetail;

  DetailController({
    required VaccinationService vaccinationService,
    required this.countryDetail,
  }) : _vaccinationService = vaccinationService;

  // Reactive state
  final Rxn<VaccinationModel> vaccination = Rxn<VaccinationModel>();
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVaccination();
  }

  Future<void> fetchVaccination() async {
    try {
      loading.value = true;
      error.value = '';
      
      // Debug print
      print('🔍 Fetching vaccination data for: ${countryDetail.name}');
      
      final result = await _vaccinationService.getCountryVaccination(countryDetail.name);
      
      // Debug prints
      print('✅ Vaccination data received:');
      print('   Country: ${result.country}');
      print('   Population: ${result.population}');
      print('   Fully vaccinated: ${result.peopleVaccinated}');
      print('   Partially vaccinated: ${result.peoplePartiallyVaccinated}');
      print('   Administered: ${result.administered}');
      
      vaccination.value = result;
      
      // Additional validation
      if (result.population == null || result.population == 0) {
        print('⚠️ Warning: No population data for ${countryDetail.name}');
      }
      
    } catch (e, st) {
      error.value = 'Failed to load vaccination data';
      print('❌ DetailController.fetchVaccination error: $e');
      print('Stack trace: $st');
    } finally {
      loading.value = false;
    }
  }

  /// Returns risk level label
  String get riskLevel {
    final cases = countryDetail.totalCases;
    if (cases > 10000000) return 'HIGH';
    if (cases > 1000000) return 'MEDIUM';
    if (cases > 100000) return 'LOW';
    return 'MINIMAL';
  }

  /// Returns risk color (use AppColors)
  Color riskColor(BuildContext context) {
    final cases = countryDetail.totalCases;
    if (cases > 10000000) return const Color(0xffef4444);
    if (cases > 1000000) return const Color(0xfff59e0b);
    if (cases > 100000) return const Color(0xff3b82f6);
    return const Color(0xff10b981);
  }

  /// Prepares deterministic mock chart points for 4 points.
  /// Avoids pure randomness to prevent UI jitter on rebuilds.
  List<FlSpotData> chartSpotsFor(double baseValue) {
    // Create 4 relative values that scale with baseValue
    final multiplier = max(1.0, baseValue / 100000.0);
    final values = <double>[
      baseValue * (0.65 + 0.05 * multiplier.clamp(0.0, 2.0)),
      baseValue * (0.75 + 0.05 * multiplier.clamp(0.0, 2.0)),
      baseValue * (0.85 + 0.05 * multiplier.clamp(0.0, 2.0)),
      baseValue * (0.95 + 0.05 * multiplier.clamp(0.0, 2.0)),
    ];
    return List.generate(values.length, (i) => FlSpotData(x: i.toDouble(), y: values[i]));
  }

  /// Generate shareable text
  String buildShareText() {
    return '''
🦠 COVID-19 Data for ${countryDetail.name}

📊 Statistics:
• Total Cases: ${countryDetail.totalCases}
• Deaths: ${countryDetail.totalDeaths}
• Recovered: ${countryDetail.totalRecovered}
• Active: ${countryDetail.active}
• Critical: ${countryDetail.critical}

📱 Shared from COVID-19 Tracker App
    ''';
  }
}

/// Small helper model for chart points to avoid tight coupling with fl_chart in controller
class FlSpotData {
  final double x;
  final double y;
  FlSpotData({required this.x, required this.y});
}