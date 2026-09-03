import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tracking_app/dio/config.dart';

class MarkerMethods {
  static const String serverUrl = "https://192.168.0.2:8080";

  late Future<String> saveMarkersRequest;

  late Future<String> deleteSelectedMarkerRequest;

  final DIOConfig config = DIOConfig();

  static const secureStorageInstance = FlutterSecureStorage();

  Future<String> saveMarker(MarkerId markerDate, double latitude,
      double longitude, String color, String title) async {
    const String url = "$serverUrl/api/save-marker";

    String? jwt = await secureStorageInstance.read(key: "token");

    try {
      final response = await config.dio.post(
        url,
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwt'
        }),
        data: jsonEncode({
          'marker_date': markerDate.value,
          'latitude': latitude,
          'longitude': longitude,
          'color': color,
          'title': title
        }),
      );

      return response.data;
    } on SocketException catch (e) {
      return "Network error: ${e.message}";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<dynamic> fetchUserPins() async {
    const String url = "$serverUrl/api/fetch-all-markers";

    String? jwt = await secureStorageInstance.read(key: "token");

    try {
      final response = await config.dio.post(url,
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': jwt,
          }));

      final List<dynamic> markers = response.data;

      return markers;
    } on SocketException catch (e) {
      return "Network error: ${e.message}";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<String> deleteSelectedMarker(String markerDate) async {
    const String url = "$serverUrl/api/delete-marker";

    String? jwt = await secureStorageInstance.read(key: "token");

    try {
      final response = await config.dio.delete(
        url,
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwt'
        }),
        data: jsonEncode({"marker_date": markerDate}),
      );

      return response.data;
    } on SocketException catch (e) {
      return "Network error: ${e.message}";
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }
}
