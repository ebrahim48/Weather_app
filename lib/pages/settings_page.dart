import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/provider/weather_provider.dart';



class SettingsPage extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) => ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            SwitchListTile(
              title: const Text('Show temperature in Fahrenheit'),
              subtitle: const Text('Default is Celsius'),
              value: provider.isFahrenheit,
              onChanged: (value) async {
                provider.setTempUnit(value);
                await provider.setPreferenceTempUnitValue(value);
                provider.getWeatherData();
              },
            ),
          ],
        ),
      ),
    );
  }
}
