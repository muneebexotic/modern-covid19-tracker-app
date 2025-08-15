import 'dart:convert';
import 'package:covid19_tracker_flutter/Models/VaccinationModel.dart';
import 'package:http/http.dart' as http;

class VaccinationService {
  // Using mock data since the original vaccination API might not be available
  Future<List<VaccinationModel>> getVaccinationData() async {
    try {
      // This is mock data - in real implementation, you'd use an actual API
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      final mockData = [
        {
          'country': 'USA',
          'countryISO': 'US',
          'administered': 600000000,
          'people_vaccinated': 220000000,
          'people_partially_vaccinated': 250000000,
          'population': 331000000,
          'continent': 'North America',
          'location': 'United States',
          'date': '2024-01-15'
        },
        {
          'country': 'India',
          'countryISO': 'IN',
          'administered': 2200000000,
          'people_vaccinated': 900000000,
          'people_partially_vaccinated': 950000000,
          'population': 1400000000,
          'continent': 'Asia',
          'location': 'India',
          'date': '2024-01-15'
        },
        {
          'country': 'China',
          'countryISO': 'CN',
          'administered': 3400000000,
          'people_vaccinated': 1300000000,
          'people_partially_vaccinated': 1350000000,
          'population': 1450000000,
          'continent': 'Asia',
          'location': 'China',
          'date': '2024-01-15'
        },
        {
          'country': 'Brazil',
          'countryISO': 'BR',
          'administered': 500000000,
          'people_vaccinated': 180000000,
          'people_partially_vaccinated': 190000000,
          'population': 215000000,
          'continent': 'South America',
          'location': 'Brazil',
          'date': '2024-01-15'
        }
      ];

      return mockData.map((json) => VaccinationModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vaccination data: $e');
    }
  }

  Future<VaccinationModel> getCountryVaccination(String country) async {
    try {
      final allData = await getVaccinationData();
      return allData.firstWhere(
        (data) => data.country?.toLowerCase() == country.toLowerCase(),
        orElse: () => VaccinationModel(
          country: country,
          administered: 0,
          peopleVaccinated: 0,
          peoplePartiallyVaccinated: 0,
        ),
      );
    } catch (e) {
      throw Exception('Failed to fetch country vaccination data: $e');
    }
  }
}