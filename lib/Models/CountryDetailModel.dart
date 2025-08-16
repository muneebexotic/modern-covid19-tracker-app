/// UI-friendly model for Detail Screen
class CountryDetail {
  final String name;
  final String flagUrl;
  final int totalCases;
  final int totalRecovered;
  final int todayRecovered;
  final int totalDeaths;
  final int active;
  final int critical;
  final int test;

  CountryDetail({
    required this.name,
    required this.flagUrl,
    required this.totalCases,
    required this.totalRecovered,
    required this.todayRecovered,
    required this.totalDeaths,
    required this.active,
    required this.critical,
    required this.test,
    required tests,
  });
}
