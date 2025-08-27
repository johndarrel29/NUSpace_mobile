import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../services/connectivity_service.dart';
import '../utils/internalserverdialog.dart';
import '../widgets/customfont.dart';
import '../widgets/snackbarhelper.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> notification = [];
  List<Map<String, dynamic>> todayNotifications = [];
  List<Map<String, dynamic>> earlierNotifications = [];
  bool _isLoading = true;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    _fetchNotification();
  }

  Future<void> _fetchNotification() async {
    final token = await storage.read(key: "auth_token");
    final userId = await storage.read(key: "user_id");
    print("userId: $userId");
    if (token == null || userId == null) {
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
      final response = await http
          .get(
            Uri.parse(
              '${AppConfig.baseUrl}/api/notification/fetch-notification/$userId',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
          )
          .timeout(Duration(seconds: 20));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        print("respondeData: $responseData");
        if (mounted) {
          setState(() {
            notification = List<Map<String, dynamic>>.from(
              responseData['notifications'] ?? [],
            );
            _isLoading = false;
          });
          print("printing notifications: $notification");
        }
      } else {
        print(
          "error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          notification = [];
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

  Future<void> _markAsRead(String notifId) async {
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
      final response = await http
          .patch(
            Uri.parse('${AppConfig.baseUrl}/api/notification/$notifId/read'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
          )
          .timeout(Duration(seconds: 20));

      if (response.statusCode == 200) {
        print("Notification marked as read!");
      } else {
        print("Failed to mark as read: ${response.body}");
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
    }
  }

  void _groupNotifications() {
    final now = DateTime.now();

    todayNotifications =
        notification.where((notif) {
          final createdAt = DateTime.tryParse(notif['createdAt'] ?? '') ?? now;
          return createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
        }).toList();

    earlierNotifications =
        notification.where((notif) {
          final createdAt = DateTime.tryParse(notif['createdAt'] ?? '') ?? now;
          return !(createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day);
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _groupNotifications();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.edit_notifications, size: 24.r),
              color: nuBlue,
            ),
          ),
        ],
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
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: nuBlue, strokeAlign: 5),
              )
              : notification.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.grey,
                      size: 50.r,
                    ),
                    SizedBox(height: 5.h),
                    CustomFont(
                      text: "No notification found!",
                      fontSize: 16.r,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ],
                ),
              )
              : ListView(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                children: [
                  if (todayNotifications.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      child: CustomFont(
                        text: "Today",
                        fontSize: 18.r,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ...todayNotifications.map(
                      (notif) => CustomNotification(
                        title: notif['title'] ?? 'No title',
                        message: notif['message'] ?? 'No message',
                        isRead: notif['isRead'],
                        createdAt:
                            DateTime.tryParse(notif['createdAt'] ?? '') ??
                            DateTime.now(),
                        onTap: () async {
                          //mark notification as read
                          await _markAsRead(notif['_id']);

                          //redirect user to designated route
                          final data = notif['data'] ?? {};
                          print("printing data: $data");

                          if (!mounted) return;

                          setState(() {
                            notif['isRead'] = true;
                          });

                          switch (data['type'].toString()) {
                            case "ACTIVITY_APPROVAL":
                              Navigator.of(context).pushNamed(
                                "/viewActivityScreen",
                                arguments: {'activityID': data['activityId']},
                              );
                              break;

                            case "NEW_ACTIVITY":
                              Navigator.of(context).pushNamed(
                                "/viewActivityScreen",
                                arguments: {'activityID': data['activityId']},
                              );
                              break;

                            case "RSO_ANNOUNCEMENT":
                              Navigator.of(context).pushNamed(
                                "/announcementScreen",
                                arguments: {'rsoId': data['rsoId']},
                              );
                              break;

                            case "MEMBERSHIP_APPROVAL":
                              Navigator.of(context).pushNamed(
                                '/announcementScreen',
                                arguments: {'rsoId': data['rsoId']},
                              );
                              break;

                            case "ACTIVITY_FEEDBACK":
                              Navigator.of(context).pushNamed(
                                "/viewActivityScreen",
                                arguments: {'activityID': data['activityId']},
                              );
                              break;

                            default:
                              break;
                          }
                        },
                      ),
                    ),
                  ],
                  if (earlierNotifications.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      child: CustomFont(
                        text: "Earlier",
                        fontSize: 18.r,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ...earlierNotifications.map(
                      (notif) => CustomNotification(
                        title: notif['title'] ?? 'No title',
                        message: notif['message'] ?? 'No message',
                        isRead: notif['isRead'],
                        createdAt:
                            DateTime.tryParse(notif['createdAt'] ?? '') ??
                            DateTime.now(),
                        onTap: () async {
                          //mark notification as read
                          await _markAsRead(notif['_id']);

                          //redirect user to designated route
                          final data = notif['data'] ?? {};
                          print("printing data: $data");

                          if (!mounted) return;

                          setState(() {
                            notif['isRead'] = true;
                          });

                          switch (data['type'].toString()) {
                            case "ACTIVITY_APPROVAL":
                              Navigator.of(context).pushNamed(
                                "/viewActivityScreen",
                                arguments: {'activityID': data['activityId']},
                              );
                              break;

                            case "NEW_ACTIVITY":
                              Navigator.of(context).pushNamed(
                                "/viewActivityScreen",
                                arguments: {'activityID': data['activityId']},
                              );
                              break;

                            case "RSO_ANNOUNCEMENT":
                              Navigator.of(context).pushNamed(
                                "/announcementScreen",
                                arguments: {'rsoId': data['rsoId']},
                              );
                              break;

                            case "MEMBERSHIP_APPROVAL":
                              Navigator.of(context).pushNamed(
                                '/announcementScreen',
                                arguments: {'rsoId': data['rsoId']},
                              );
                              break;

                            default:
                              break;
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
    );
  }
}
