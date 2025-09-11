import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:nuspace_app/config/config.dart';

final storage = FlutterSecureStorage();

Future<String?> safeRead(String key) async {
  try {
    return await storage.read(key: key);
  } catch (e) {
    print("SecureStorage read error for $key: $e");
    await storage.delete(key: key); // clear corrupted value
    return null;
  }
}

class AuthService {
  static Future<String?> refreshAccessToken(String refreshToken) async {
    try {
      final String? deviceToken = await safeRead("device_token");
      if (deviceToken == null) return null;

      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/login/refresh-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'refreshToken': refreshToken,
              'deviceToken': deviceToken,
            }),
          )
          .timeout(Duration(seconds: 20));

      final responseData = jsonDecode(response.body);
      print("Refresh token responseData: $responseData");

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData['accessToken'];
      } else {
        await storage.deleteAll();
        return null;
      }
    } catch (e) {
      print("Error refreshing token: $e");
      return null;
    }
  }

  static Future<String> checkLoginStatus() async {
    String? accessToken = await safeRead("auth_token");
    String? refreshToken = await safeRead("refresh_token");

    if (accessToken != null) {
      try {
        Map<String, dynamic> payload = Jwt.parseJwt(accessToken);
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          payload['exp'] * 1000,
        );

        if (expiry.isAfter(DateTime.now())) {
          return '/mainScreen';
        }
      } catch (e) {
        print("Invalid access token: $e");
      }
    }

    if (refreshToken != null) {
      String? newAccessToken = await refreshAccessToken(refreshToken);
      if (newAccessToken != null) {
        await storage.write(key: "auth_token", value: newAccessToken);
        return '/mainScreen';
      }
    }

    return '/landingScreen';
  }
}
