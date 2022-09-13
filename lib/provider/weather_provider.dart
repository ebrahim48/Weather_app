import 'dart:convert';
import 'package:geocoding/geocoding.dart' as Geo;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/models/current_response_model.dart';
import 'package:weather_app/models/forecast_response_model.dart';
import 'package:weather_app/utils/constants.dart';

import '../models/current_response_model.dart';
import '../models/forecast_response_model.dart';
import '../utils/constants.dart';

class WeatherProvider extends ChangeNotifier {
  CurrentResponseModel? currentResponseModel;
  ForecastResponseModel? forecastResponseModel;
  double latitude = 0.0, longitude = 0.0;
  String unit = 'metric';
  String unitSymbol = celsius;

  bool get hasDataLoaded => currentResponseModel != null &&
      forecastResponseModel != null;

  bool get isFahrenheit => unit == 'imperial';

  void setNewLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
  }

  void setTempUnit(bool tag) {
    unit = tag ? 'imperial' : 'metric';
    unitSymbol = tag ? fahrenheit : celsius;
    notifyListeners();
  }

  Future<bool> setPreferenceTempUnitValue(bool tag) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setBool('unit', tag);
  }

  Future<bool> getPreferenceTempUnitValue() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool('unit') ?? false;
  }

  getWeatherData() {
    _getCurrentData();
    _getForecastData();
  }

  void convertAddressToLatLng(String result) async {
    try{
      final locationList = await Geo.locationFromAddress(result);
      if(locationList.isNotEmpty) {
        final location = locationList.first;
        setNewLocation(location.latitude, location.longitude);
        getWeatherData();
      } else {
        print('City not found');
      }
    }catch(error) {
      //easyloading use koiren
      print(error.toString());

    }
  }

  void _getCurrentData() async {
    final uri = Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&units=$unit&appid=$weather_api_key');
    try {
      final response = await get(uri);
      final map = jsonDecode(response.body);
      if(response.statusCode == 200) {
        currentResponseModel = CurrentResponseModel.fromJson(map);
        print(currentResponseModel!.main!.temp!.round());
        notifyListeners();
      } else {
        print(map['message']);
      }
    }catch(error) {
      rethrow;
    }
  }

  void _getForecastData() async {
    final uri = Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&units=$unit&appid=$weather_api_key');
    try {
      final response = await get(uri);
      final map = jsonDecode(response.body);
      if(response.statusCode == 200) {
        forecastResponseModel = ForecastResponseModel.fromJson(map);
        print(forecastResponseModel!.list!.length);
        notifyListeners();
      } else {
        print(map['message']);
      }
    }catch(error) {
      rethrow;
    }
  }
}