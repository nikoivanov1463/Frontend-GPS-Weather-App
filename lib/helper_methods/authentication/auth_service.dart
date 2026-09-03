import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tracking_app/dio/config.dart';

class AuthService {
  final DIOConfig config = DIOConfig();

  final sessionStorage = const FlutterSecureStorage();

  static const String url = "https://192.168.0.2:8080";

  Future<dynamic> login(
    BuildContext context,
    String username,
    String email,
    String password,
  ) async {
    const String uri = "$url/api/login";

    try {
      final response = await config.dio.post(
        uri,
        options: Options(headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        }),
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        await sessionStorage.write(key: "token", value: response.data["jwt"]);
        await sessionStorage.write(
            key: "refresh_token", value: response.data["refresh_jwt_token"]);
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, "/home");
        }
        return null;
      }
    }on DioException catch (e){
      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data as Map<String, dynamic>;

        if(errorData['errors'] != null) {
          final result = errorData['errors'];

          return result;
        }
      }
    }
  }

  Future<String> changePassword(BuildContext context, String email) async {
    const sessionStorage = FlutterSecureStorage();
    String? refreshJwt = await sessionStorage.read(key: "refresh_token");

    const String uri = "$url/api/change";

    try {
      final request = await config.dio.post(uri,
          options: Options(headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Refresh_Token': "Bearer ${refreshJwt.toString()}"
          }),
          data: jsonEncode({'email': email}));

      if (request.statusCode == 200) {
        return request.data;
      }

      return request.data;
    } catch (e) {
      return "Problem connecting";
    }
  }
}