import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/widgets/activitycard.dart';
import 'package:nuspace_app/widgets/customtabswitch.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/customfont.dart';
import '../../widgets/snackbarhelper.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> activities = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errormessage;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    refreshData();
  }

  void refreshData() {
    print("Refreshing activity data");
    _fetchAllActivities();
  }

  Future<void> _fetchAllActivities() async {
    //check token..if no token, go back to landing screen
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
          .get(
            Uri.parse(
              '${AppConfig.baseUrl}/api/student/activities/getallActivities',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
          )
          .timeout(Duration(seconds: 20));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (mounted) {
          setState(() {
            activities = List<Map<String, dynamic>>.from(
              responseData['activities'] ?? [],
            );
            _isLoading = false;
          });

          print("Activities from all RSOs: $activities");
        }
      } else {
        setState(() {
          activities = [];
          _errormessage = responseData['message'];
        });
        print("error code ${response.statusCode} and message $_errormessage");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whitetheme,
      appBar: AppBar(
        scrolledUnderElevation: 0,
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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 6.w),
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications, size: 24.r),
              color: nuBlue,
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: nuBlue, strokeAlign: 5),
              )
              : Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  children: [
                    CustomTabSwitch(
                      tabs: ['For You', 'Your Activities'],
                      selectedIndex: _selectedIndex,
                      onTabSelected: (value) {
                        setState(() {
                          _selectedIndex = value;
                        });
                        print("Selected tab: $value");
                      },
                    ),

                    SizedBox(height: 10.h),

                    if (_selectedIndex == 0) ...[
                      Expanded(
                        child:
                            activities.isEmpty
                                ? Center(
                                  child: CustomFont(
                                    text:
                                        "No Activities Available At The Moment",
                                    fontSize: 16.r,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                                : SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      //pwede maglagay ng search button dito
                                      Placeholder(fallbackHeight: 50.h),
                                      SizedBox(height: 10.h),

                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: activities.length,
                                        itemBuilder: (context, index) {
                                          final activity = activities[index];

                                          DateTime? startDate;
                                          try {
                                            startDate =
                                                DateTime.parse(
                                                  activity['Activity_start_datetime'],
                                                ).toLocal();
                                          } catch (e) {
                                            startDate = null;
                                          }

                                          String dateString =
                                              startDate != null
                                                  ? DateFormat(
                                                    'MMMM d, yyyy • h:mm a',
                                                  ).format(startDate)
                                                  : "No date available";

                                          return ActivityCard(
                                            rsoName:
                                                activity['RSO_details']?['RSO_name'] ??
                                                'RSO Name',
                                            college:
                                                activity['RSO_details']?['RSO_College'] ??
                                                'RSO College',
                                            rsoImage:
                                                activity['RSO_details']?['RSO_picture'] ??
                                                '',
                                            activityName:
                                                activity['Activity_name'] ??
                                                "Activity_name",
                                            activityImage:
                                                activity['Activity_image'] ??
                                                '',
                                            date: dateString,
                                            description:
                                                activity['Activity_description'] ??
                                                "Activity description",
                                            publicity:
                                                activity['Activity_publicity'],
                                            onTap: () {
                                              print(
                                                "printing activity id: ${activity['_id']}",
                                              );
                                              Navigator.of(context).pushNamed(
                                                '/viewActivityScreen',
                                                arguments: {
                                                  'activityID': activity['_id'],
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}
