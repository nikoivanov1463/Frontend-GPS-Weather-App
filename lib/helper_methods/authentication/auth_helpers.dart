import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthHelpers{
  static const String url = "https://192.168.0.2:8080";

  late final Dio dio;
  final sessionStorage = const FlutterSecureStorage();

  AuthHelpers({required this.dio});

  Future<int> logout() async {
    const sessionStorage = FlutterSecureStorage();
    final jwt = await sessionStorage.read(key: "token");

    try {
      final response = await dio.delete(
        "$url/api/logout",
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': "Bearer $jwt",
        }),
      );

      await sessionStorage.deleteAll();
      return response.statusCode ?? 0;
    } catch (e) {
      print(e.toString());
      return 0;
    }
  }

  Future<String?> getToken() {
    return sessionStorage.read(key: "token");
  }

  Future<String?> getRefreshToken() {
    return sessionStorage.read(key: "refresh_token");
  }

  Future<String?> sessionCheck() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await dio.post(
        '$url/api/session-check',
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Refresh_Token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        String? newAccessToken = response.headers['Authorization']?.first.replaceFirst("Bearer ", "").trim();
        String? newRefreshToken = response.headers['Refresh_Token']?.first.replaceFirst("Bearer ", "").trim();

        await sessionStorage.write(key: "token", value: newAccessToken);
        await sessionStorage.write(key: "refresh_token", value: newRefreshToken);

        return newAccessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}