import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tracking_app/helper_methods/map/map_methods.dart';
import 'package:tracking_app/helper_methods/weather/weather_methods.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late String? userTown;

  DateTime dateNow = DateTime.now();

  List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Map<String, dynamic>> initWeather() async {
    LatLng location = await MapMethods.getCurrentLocation();
    dynamic weather = await WeatherMethods.getWeather(
        "?latitude=${location.latitude}&longitude=${location.longitude}&current=temperature_2m,relative_humidity_2m,is_day,precipitation,wind_speed_10m&hourly=temperature_2m,relative_humidity_2m,snowfall,showers,wind_speed_10m");
    userTown = await MapMethods.getTownFromCoordinates(
        location.latitude, location.longitude);

    return {
      'temperature':
          double.parse(weather["current"]["temperature_2m"].toString()),
      'humidity': weather["current"]["relative_humidity_2m"].toString(),
      'showers': weather["hourly"]["showers"][0].toString(),
      'snowfall': weather["hourly"]["snowfall"][0].toString(),
      'windSpeed': weather["current"]["wind_speed_10m"].toString(),
      'hourlyTime': weather["hourly"]["time"],
      'hourlyTemp': weather["hourly"]["temperature_2m"]
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initWeather(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          dynamic data = snapshot.data;

          String currentTemperature = data['temperature'].toString();
          String currentHumidity = data['humidity'];
          String currentShowers = data['showers'];
          String currentSnowfall = data['snowfall'];
          String currentWindSpeed = data['windSpeed'];

          List<DateTime> dates = data['hourlyTime']
              .map<DateTime>((element) => DateTime.parse(element))
              .toList();

          List<DateTime> filteredDatesBasedOnCurrentHour = dates
              .where((date) => (date.hour == DateTime.now().hour))
              .toList();

          List<dynamic> hourlyTemp = data['hourlyTemp'];

          List<int> filteredTempData = [];
          filteredDatesBasedOnCurrentHour.asMap().forEach((index, date) {
            filteredTempData
                .add(double.parse(hourlyTemp[index].toString()).toInt());
          });

          List<DateTime> weeklyDates = [];
          for (int i = 0; i < 7; i++) {
            weeklyDates.add(dateNow.add(Duration(days: i)));
          }

          List<String> weeklyDayNames = weeklyDates
              .map((date) => DateFormat("EEEE").format(date))
              .toList();

          return Column(
            children: [
              Flexible(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Builder(
                        builder: (BuildContext context) {
                          if (double.tryParse(currentShowers) != null) {
                            double showers = double.parse(currentShowers);

                            if (showers > 0.00) {
                              return const Center(
                                child: Icon(
                                  size: 200,
                                  Icons.water_drop_rounded,
                                  color: Colors.blue,
                                ),
                              );
                            }
                          }

                          if (double.tryParse(currentSnowfall) != null) {
                            double snowfall = double.parse(currentSnowfall);

                            if (snowfall > 0.00) {
                              return const Center(
                                child: Icon(
                                  size: 200,
                                  Icons.snowing,
                                  color: Colors.blue,
                                ),
                              );
                            }
                          }

                          if (dateNow.hour >= 7 && dateNow.hour <= 19) {
                            return const Center(
                              child: Icon(
                                size: 200,
                                Icons.sunny,
                                color: Colors.blue,
                              ),
                            );
                          } else {
                            return const Center(
                              child: Icon(
                                size: 200,
                                Icons.nights_stay_rounded,
                                color: Colors.blue,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Text(
                        "Currently in $userTown $currentTemperature°C $currentHumidity% ${currentWindSpeed}km/h",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets.only(top: 20, left: 20, right: 20),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: ListView.builder(
                          itemCount: days.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Column(
                              children: [
                                Text(
                                  weeklyDayNames[index],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "On ${weeklyDates[index].day.toString()} ${DateFormat("MMMM").format(weeklyDates[index])} At ${DateFormat("HH:mm").format(weeklyDates[index])} ${filteredTempData[index]} °C",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const Divider(
                                  color: Colors.white24,
                                  thickness: 2,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
