class VaccinationModel {
  String? country;
  String? countryISO;
  int? administered;
  int? peopleVaccinated;
  int? peoplePartiallyVaccinated;
  int? population;
  String? sq_km_area;
  String? life_expectancy;
  String? elevation_in_meters;
  String? continent;
  String? abbreviation;
  String? location;
  String? iso;
  String? date;

  VaccinationModel({
    this.country,
    this.countryISO,
    this.administered,
    this.peopleVaccinated,
    this.peoplePartiallyVaccinated,
    this.population,
    this.sq_km_area,
    this.life_expectancy,
    this.elevation_in_meters,
    this.continent,
    this.abbreviation,
    this.location,
    this.iso,
    this.date,
  });

  VaccinationModel.fromJson(Map<String, dynamic> json) {
    country = json['country'];
    countryISO = json['countryISO'];
    administered = json['administered'];
    peopleVaccinated = json['people_vaccinated'];
    peoplePartiallyVaccinated = json['people_partially_vaccinated'];
    population = json['population'];
    sq_km_area = json['sq_km_area'];
    life_expectancy = json['life_expectancy'];
    elevation_in_meters = json['elevation_in_meters'];
    continent = json['continent'];
    abbreviation = json['abbreviation'];
    location = json['location'];
    iso = json['iso'];
    date = json['date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['country'] = country;
    data['countryISO'] = countryISO;
    data['administered'] = administered;
    data['people_vaccinated'] = peopleVaccinated;
    data['people_partially_vaccinated'] = peoplePartiallyVaccinated;
    data['population'] = population;
    data['sq_km_area'] = sq_km_area;
    data['life_expectancy'] = life_expectancy;
    data['elevation_in_meters'] = elevation_in_meters;
    data['continent'] = continent;
    data['abbreviation'] = abbreviation;
    data['location'] = location;
    data['iso'] = iso;
    data['date'] = date;
    return data;
  }
}