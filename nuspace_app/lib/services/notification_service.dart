import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/firebase_options.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  //call this in main() to handle background messages
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Background notification: ${message.notification?.title}');
  }

  //call this in inisState()
  static Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permission status: ${settings.authorizationStatus}');
  }

  static void initializeFCMListerners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification: ${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.notification?.title}');
    });
  }

  static Future<void> getAndPrintFCMToken({
    required String userId,
    required String role,
  }) async {
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    if (token != null) {
      await _sendTokenToBackend(token, userId, role);
    }
  }

  //send token to backend
  static Future<void> _sendTokenToBackend(
    String token,
    String userId,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/device-token'),
        headers: {
          'Content-Type': 'application/json',
          //Authorization JWT Token
        },
        body: jsonEncode({
          'userId': userId,
          'role': role,
          'token': token,
          'platform': "mobile",
        }),
      );

      if (response.statusCode == 200) {
        print('Token sent to backend');
      } else {
        print("Failed to send token: ${response.statusCode}");
        print('Response: ${response.body}');
      }
    } catch (e, stackTrace) {
      print("Error in sending token to backend: $e");
      print("stacktrace: $stackTrace");
    }
  }
}
