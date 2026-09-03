import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:tracking_app/helper_methods/authentication/auth_helpers.dart';

class DIOConfig {
  final Dio dio = Dio();

  bool isRefreshing = false;
  bool logoutInProgress = false;

  //TODO: use adapter for http2 from packages

  DIOConfig() {
    dio.interceptors.add(LogInterceptor(requestBody: true));

    dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
      final HttpClient client =
      HttpClient(context: SecurityContext(withTrustedRoots: false));
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        const String expectedFingerprint =
            "84:25:08:4E:C8:C2:A4:BB:6B:94:CF:DE:6A:8A:2F:35:0A:CF:A2:C0:3A:26:D2:DA:2D:7B:79:D5:11:A7:90:3C";

        final sha256Digest = sha256.convert(cert.der).toString().toUpperCase();
        final formattedDigest = sha256Digest
            .replaceAllMapped(RegExp(r".{2}"), (m) => "${m.group(0)}:")
            .substring(0, 95);

        return formattedDigest == expectedFingerprint;
      };
      return client;
    });

    final authHelpers = AuthHelpers(dio: dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.path.contains('/logout')) {
            handler.next(options);
            return;
          }

          final token = await authHelpers.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },

        onError: (error, handler) async {
          if (error.requestOptions.path.contains('/logout')) {
            return handler.next(error);
          }

          if (error.response?.statusCode == 401) {
            if (isRefreshing) {
              return handler.next(error);
            }

            isRefreshing = true;

            try {
              if (error.requestOptions.headers['X-Refresh-Attempt'] == 'true') {
                await safeLogout(authHelpers);
                return handler.next(error);
              }

              String? newToken = await authHelpers.sessionCheck();

              if (newToken == null || newToken.isEmpty) {
                await safeLogout(authHelpers);
                return handler.next(error);
              }

              error.requestOptions.headers['X-Refresh-Attempt'] = 'true';
              error.requestOptions.headers['Authorization'] =
              'Bearer $newToken';

              try {
                final response = await dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (retryError) {
                await safeLogout(authHelpers);
                return handler.next(error);
              }
            } catch (e) {
              await safeLogout(authHelpers);
              return handler.next(error);
            } finally {
              isRefreshing = false;
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<void> safeLogout(AuthHelpers authHelpers) async {
    if (logoutInProgress) return;
    logoutInProgress = true;

    try {
      await authHelpers.logout();
    } finally {
      logoutInProgress = false;
    }
  }
}
