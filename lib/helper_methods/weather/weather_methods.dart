import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherMethods {
  static String apiUrl = "https://api.open-meteo.com/v1/forecast";

  static Future<dynamic> getWeather(String query) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl$query"));
      if (response.statusCode == 200) {
        final weatherJson = jsonDecode(response.body);

        return weatherJson;
      } else {
        return "No data provided.";
      }
    } catch (error) {
      return "An unexpected error occurred: $error";
    }
  }
}
