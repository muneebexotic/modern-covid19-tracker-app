import 'dart:convert';

import 'package:covid19_tracker_flutter/Models/WorldStatesModel.dart';
import 'package:covid19_tracker_flutter/Services/Utilities/app_url.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class StatesServices {
  Future<WorldStatesModel> fetchWorldStateRecords() async {
    final response = await http.get(Uri.parse(AppUrl.worldStateApi));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return WorldStatesModel.fromJson(data);
    } else {
      throw Exception('Error');
    }
  }

  Future<List<dynamic>> countriesListApi() async {
    var data;
    final response = await http.get(Uri.parse(AppUrl.countriesList));

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Error');
    }
  }
}
