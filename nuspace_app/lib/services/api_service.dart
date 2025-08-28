import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

import 'auth_service.dart';

final storage = FlutterSecureStorage();

// Lock for token refresh to prevent multiple simultaneous refreshes
bool _isRefreshing = false;
List<Function(String)> _pendingRequests = [];

Future<http.Response?> apiRequest(
  Future<http.Response> Function(String accessToken) requestFunc, {
  BuildContext? context,
}) async {
  String? accessToken = await storage.read(key: "auth_token");
  String? refreshToken = await storage.read(key: "refresh_token");

  if (accessToken == null) {
    if (context != null) await logoutAndRedirect(context);
    print("No access token found. Please log in.");
    return null;
  }

  try {
    final payload = Jwt.parseJwt(accessToken);
    final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);

    // Handle token expiration
    if (expiry.isBefore(DateTime.now()) && refreshToken != null) {
      if (_isRefreshing) {
        // If already refreshing, queue the request
        final completer = Completer<String>();
        _pendingRequests.add((newToken) => completer.complete(newToken));
        accessToken = await completer.future;
      } else {
        _isRefreshing = true;
        final newToken = await AuthService.refreshAccessToken(refreshToken);

        if (newToken != null) {
          accessToken = newToken;
          await storage.write(key: "auth_token", value: newToken);

          // Complete pending requests
          for (var callback in _pendingRequests) {
            callback(newToken);
          }
          _pendingRequests.clear();
        } else {
          // Refresh token invalid, log out
          if (context != null) await logoutAndRedirect(context);
          _pendingRequests.clear();
          _isRefreshing = false;
          print("Session expired. Please log in again.");
          return null;
        }
        _isRefreshing = false;
      }
    }
  } catch (e) {
    if (context != null) await logoutAndRedirect(context);
    print("Error parsing access token: $e");
    return null;
  }

  final response = await requestFunc(accessToken);

  // Handle unauthorized from backend
  if (response.statusCode == 401 || response.statusCode == 400) {
    if (context != null) await logoutAndRedirect(context);
    print("Unauthorized. Please log in again.");
    return null;
  }

  return response;
}

Future<void> logoutAndRedirect(BuildContext context) async {
  await storage.deleteAll();
  Navigator.pushNamedAndRemoveUntil(
    context,
    '/landingScreen',
    (route) => false,
  );
}
