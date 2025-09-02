import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/firebase_options.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        //handle notification tap
        print("Tapped notification with payload: ${response.payload}");
      },
    );
  }

  static Future<void> showNotification(RemoteMessage message) async {
    final soundName = message.data['sound'];
    final title = message.data['title'] ?? 'No Title';
    final body = message.data['body'] ?? 'No body';
    final route = message.data['route'];

    final notificationId =
        message.data['id']?.hashCode ??
        (DateTime.now().millisecondsSinceEpoch % 2147483647);

    print("Notification ID: $notificationId, Sound: $soundName");

    final channelId = 'nuspace_channel_$soundName';

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      'NU Space Notifications ($soundName)',
      channelDescription: 'This channel is for NU Space push notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound:
          soundName != null
              ? RawResourceAndroidNotificationSound(soundName)
              : RawResourceAndroidNotificationSound('notification_1'),
    );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: soundName != null ? "$soundName.wav" : null,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: route,
    );
  }

  //call this in main to handle background messages
  @pragma('vm:entry-point')
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.showNotification(message);
    print('Background notification: ${message.notification?.title}');
  }

  //call this in inisState()
  static Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('user declined permission');
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void initializeFCMListerners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification: ${message.notification?.title}');
      showNotification(message);
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
      const storage = FlutterSecureStorage();
      await storage.write(key: "device_token", value: token);

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
        Uri.parse('${AppConfig.baseUrl}/api/device-token/save-token'),
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
