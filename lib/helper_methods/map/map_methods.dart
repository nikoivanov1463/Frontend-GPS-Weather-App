import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMethods {
  static Future<LatLng> getCurrentLocation() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    Position currentPosition =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);

    return LatLng(currentPosition.latitude, currentPosition.longitude);
  }

  static Future<String?> getTownFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String? town = place.locality;
        String? subLocality = place.subLocality;

        return town ?? subLocality;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
