import 'dart:async';

import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/pages/settings_page.dart';
import 'package:weather_app/provider/weather_provider.dart';
import 'package:weather_app/utils/constants.dart';
import 'package:weather_app/utils/helper_function.dart';
import 'package:weather_app/utils/location_utils.dart';
import 'package:weather_app/utils/text_styles.dart';

import '../models/forecast_response_model.dart';

class WeatherPage extends StatefulWidget {
  static const String routeName = '/';
  const WeatherPage({Key? key}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late WeatherProvider provider;
  bool isFirst = true;
  Timer? timer;
  @override
  void didChangeDependencies() {
    if(isFirst){
      provider = Provider.of<WeatherProvider>(context);
      _getData();
      isFirst = false;
    }
    super.didChangeDependencies();
  }
  _startTimer(){
    timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      print('timer started');

    });
  }

  _stoptimer() {
    if(timer != null) {
      timer!.cancel();
    }
  }

  _getData() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if(!isLocationEnabled) {
      showMsgWithAction(
          context: context,
          msg: 'Please turn on location',
          callback: () async {
            _startTimer();
            final status = await Geolocator.openLocationSettings();
            print(status);
          });
      return;
    }
    try{
      final position = await determinePosition();
      provider.setNewLocation(position.latitude, position.longitude);
      provider.setTempUnit(await provider.getPreferenceTempUnitValue());
      provider.getWeatherData();
    }catch(error) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Weather App'),
        actions: [
          IconButton(
            onPressed: () {
              _getData();
            },
          icon: const Icon(Icons.my_location),
          ),
          IconButton(
            onPressed: ()async {
              final result = await showSearch(context: context, delegate: _CitySearchDelegate());
              if(result != null && result.isNotEmpty) {
                //print(result);
                provider.convertAddressToLatLng(result);
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, SettingsPage.routeName),
            icon: const Icon(Icons.settings),
          ),

        ],

      ),
      body: Center(
        child: provider.hasDataLoaded ? ListView(
          padding: const EdgeInsets.all(8),
          children: [
             _currentWeatherSection(),
             _forecastWeatherSection(),
          ],
        ) :
        const Text('Please wait...', style: txtNormal16,),
      ),
    );
  }


  Widget _currentWeatherSection() {
    final response = provider.currentResponseModel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(getFormattedDateTime(response!.dt!, 'MMM dd, yyyy'), style: txtDateHeader18,),
        Text('${response.name},${response.sys!.country}', style: txtAddross24,),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('$iconPrefix${response.weather![0].icon}$iconSuffix', fit: BoxFit.cover,),
              Text('${response.main!.temp!.round()}$degree${provider.unitSymbol}', style: txtTempBig80,)
            ],
          ),
        ),
        Wrap(
          children: [
            Text('feels like ${response.main!.feelsLike!.round()}$degree${provider.unitSymbol}', style: txtNormal16,),
            const SizedBox(width: 10,),
            Text('${response.weather![0].main}, ${response.weather![0].description}', style: txtNormal16,)
          ],
        ),
        const SizedBox(height: 20,),
        Wrap(
          children: [
            Text('Humidity ${response.main!.humidity}%', style: txtNorman16White54,),
            const SizedBox(width: 10,),
            Text('Pressure ${response.main!.pressure}hPa', style: txtNorman16White54,),
            const SizedBox(width: 10,),
            Text('Visibility ${response.visibility}meter', style: txtNorman16White54,),
            const SizedBox(width: 10,),
            Text('Wind ${response.wind!.speed}m/s', style: txtNorman16White54,),
            const SizedBox(width: 10,),
            Text('Degree ${response.wind!.deg}$degree', style: txtNorman16White54,)
          ],
        ),

        const SizedBox(height: 20,),
        Wrap(
          children: [
            Text('Sunrise ${getFormattedDateTime(response.sys!.sunrise!, 'hh:mm a')}', style: txtNormal16,),
            const SizedBox(width: 10,),
            Text('Sunset ${getFormattedDateTime(response.sys!.sunset!, 'hh:mm a')}', style: txtNormal16,),

            const SizedBox(width: 10,),

          ],
        ),
        SizedBox(height: 20,)
      ],
    );
  }

  Widget _forecastWeatherSection() {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        Text('Weather Forecast', style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold, color: Colors.white),),
        Container(
          margin: EdgeInsets.only(top: 20),
          height: 400,
          width: double.infinity,
          child: ListView.builder(
            itemCount: provider.forecastResponseModel!.list!.length,
            itemBuilder: (context, index) {
              final forecastData = provider.forecastResponseModel;
              return InkWell(
                child: Card(
                    elevation: 10,
                    color: Colors.lightBlue,
                    child: InkWell(
                      onTap: () {
                        _bottomSheet(forecastData!, index);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: size.width / 3,
                              child: Text(getFormattedDateTime(
                                  forecastData!.list![index].dt!, 'E, MMM dd'), style: txtNormal16,),
                            ),
                            SizedBox(
                              width: (size.width / 5) * 2,
                              child: Row(
                                children: [
                                  Image.network(
                                    '$iconPrefix${forecastData.list![index].weather![0].icon}$iconSuffix',
                                    height: 50,
                                    width: 50,
                                  ),
                                  Text(
                                    '${forecastData.list![index].main!.humidity}/${forecastData.list![index].main!.temp!.round()}$degree', style: txtNormal16,),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                  width: (size.width / 5 * 2),
                                  child: Text(
                                    '${forecastData.list![index].weather![0].description}', style: txtNormal16,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    )),
              );
            },
          ),
        ),
      ],
    );
  }



  void _bottomSheet(ForecastResponseModel forecastResponseModel, int index) {
    showFlexibleBottomSheet(
      isExpand: true,
      minHeight: 0,
      initHeight: 0.4,
      maxHeight: 1,
      context: context,
      builder: (context, scrollController, bottomSheetOffset) {
        return Container(
          padding: EdgeInsets.all(16),
          color: Colors.lightGreen,
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Text('${forecastResponseModel.city!.name}, ${forecastResponseModel.city!.country}', style: txtAddross24,),
              ),
              Center(
                child: Wrap(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          '$iconPrefix${forecastResponseModel.list![index].weather![0].icon}$iconSuffix',
                          height: 50,
                          width: 50,
                        ),
                        Text(
                          '${forecastResponseModel.list![index].weather![0].main},  ${forecastResponseModel.list![index].weather![0].description}',
                          style: txtNormal16,
                        ),
                      ],
                    ),
                  ],

                ),
              ),

              Center(
                child: Text(
                  'The high will be ${forecastResponseModel.list![index].main!.tempMax}$degree and the low will be ${forecastResponseModel.list![index].main!.tempMin}$degree',
                  style: txtNorman16White54,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Divider(height: 10,color: Colors.black,),
              const SizedBox(
                height: 10,
              ),
              Center(
                child: Text(
                  'Pressure : ${forecastResponseModel.list![index].main!.pressure}, Humidity : ${forecastResponseModel.list![index].main!.humidity}', style: txtDateHeader18,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Center(
                child: Text(
                    'Speed : ${forecastResponseModel.list![index].wind!.speed}, Degree : ${forecastResponseModel.list![index].wind!.deg}$degree,  UV : ${forecastResponseModel.list![index].wind!.gust}', style: txtDateHeader18
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Center(
                child: Text(
                  'Sunrise: ${getFormattedDateTime(forecastResponseModel.city!.sunrise!, 'hh : mm a')} | Sunset: ${getFormattedDateTime(forecastResponseModel.city!.sunset!, 'hh : mm a')}', style: txtNormal16,

                ),
              ),
            ],
          ),

        );
      },
      anchors: [0, 0.4, 1],
      isSafeArea: true,
    );
  }

}


class _CitySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(query),
      onTap: () {
        close(context, query);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredList = query.isEmpty ? cities :
    cities.where((city) =>
        city.toLowerCase().startsWith(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(filteredList[index]),
        onTap: () {
          query = filteredList[index];
          close(context, query);
        },
      ),
    );
  }

}
