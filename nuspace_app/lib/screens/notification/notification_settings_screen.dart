import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/snackbarhelper.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final List<String> _availableSounds = [
    'notification1.mp3',
    'notification2.mp3',
    'notification3.mp3',
    'notification4.mp3',
    'notification5.mp3',
    'notification6.mp3',
    'notification7.mp3',
    'notification8.mp3',
    'notification9.mp3',
    'notification10.mp3',
    'notification11.mp3',
    'notification12.mp3',
    'notification13.mp3',
  ];

  String? _selectedSound;
  final _player = AudioPlayer();
  final storage = FlutterSecureStorage();
  bool _isLoading = true;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    _loadSelectedSound();
  }

  Future<void> _loadSelectedSound() async {
    final token = await storage.read(key: "auth_token");
    if (token == null) {
      print("No auth token found, navigating to landing screen!");
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/landingScreen', (route) => false);
        SnackbarHelper.showSnackbar(
          "Token expired or not found",
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      return;
    }

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final userId = await storage.read(key: "user_id");
      final role = await storage.read(key: "user_role");
      print("Printing userId $userId && role $role");

      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.baseUrl}/api/device-token/fetch-sound?userId=$userId&role=$role&token=$fcmToken&platform=mobile',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
          )
          .timeout(Duration(seconds: 20));

      final responseData = jsonDecode(response.body);
      print("Printing response data: $responseData");

      if (response.statusCode == 200) {
        setState(() {
          _selectedSound = responseData['notificationSound'];
        });

        print("printing _selectedsound: $_selectedSound");
      } else {
        setState(() {
          _selectedSound = _availableSounds.first;
        });
      }
    } on TimeoutException {
      // Handle Timeout (Server Down)
      print("Server Timeout! Navigating to Internal Server Error screen.");
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const InternalServerDialog(),
        );
      }
    } catch (e, stackTrace) {
      SnackbarHelper.showSnackbar(
        "An error occurred. Please try again.",
        backgroundColor: Colors.red,
      );
      print("Error in login $e");
      print("stacktrace: $stackTrace");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectSound(String sound) async {
    final baseName = sound.replaceAll('.mp3', '');
    setState(() {
      _selectedSound = baseName;
    });

    final token = await storage.read(key: "auth_token");
    if (token == null) {
      print("No auth token found, navigating to landing screen!");
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/landingScreen', (route) => false);
        SnackbarHelper.showSnackbar(
          "Token expired or not found",
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      return;
    }

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final userId = await storage.read(key: "user_id");
      final role = await storage.read(key: "user_role");
      print("Printing userId $userId && role $role");

      final response = await http
          .put(
            Uri.parse('${AppConfig.baseUrl}/api/device-token/sound'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
            body: jsonEncode({
              "userId": userId,
              "role": role,
              "token": fcmToken,
              "platform": "mobile",
              "notificationSound": baseName,
            }),
          )
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        print("✅ Sound updated on backend: $baseName");
      } else {
        print("❌ Failed to update sound: ${response.body}");
      }
    } on TimeoutException {
      // Handle Timeout (Server Down)
      print("Server Timeout! Navigating to Internal Server Error screen.");
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const InternalServerDialog(),
        );
      }
    } catch (e, stackTrace) {
      SnackbarHelper.showSnackbar(
        "An error occurred. Please try again.",
        backgroundColor: Colors.red,
      );
      print("Error in login $e");
      print("stacktrace: $stackTrace");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playSound(String sound) async {
    try {
      await _player.setAsset('assets/sounds/$sound');
      _player.play();
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () async {
            FocusScope.of(context).unfocus(); // first dismiss keyboard
            await Future.delayed(
              const Duration(milliseconds: 300), //change to 500 if want
            ); // wait for keyboard to fully close

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(Icons.arrow_back, size: 24.r),
        ),
        backgroundColor: whitetheme,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/nuspace_whitelogo.png",
                color: nuBlue,
                height: 30.r,
                width: 30.r,
              ),
              SizedBox(width: 5.w),
              CustomFont(
                text: "NU\nSpace",
                fontSize: 14.r,
                color: nuBlue,
                useGoogleFont: false,
                fontFamily: 'ClanOT',
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 0.w),
        child: ListView.builder(
          itemCount: _availableSounds.length,
          itemBuilder: (context, index) {
            final sound = _availableSounds[index];

            return ListTile(
              title: CustomFont(
                text: sound.replaceAll('.mp3', ''),
                fontSize: 16.r,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sound.replaceAll('.mp3', '') == _selectedSound)
                    Icon(Icons.check, color: Colors.green, size: 25.r),
                  IconButton(
                    icon: Icon(Icons.play_arrow, size: 25.r),
                    onPressed: () => _playSound(sound),
                  ),
                ],
              ),
              onTap: () => _selectSound(sound),
            );
          },
        ),
      ),
    );
  }
}
