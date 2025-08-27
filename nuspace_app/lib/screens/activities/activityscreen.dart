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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _yourActivitiesSearchController =
      TextEditingController();
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> filteredActivities = [];
  List<Map<String, dynamic>> joinedActivities = [];
  List<Map<String, dynamic>> filteredJoinedActivities = [];

  int _selectedIndex = 0;
  bool _isLoading = true;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    refreshData();
    _searchController.addListener(_onSearchChanged);
    _yourActivitiesSearchController.addListener(_onYourActivitiesSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _yourActivitiesSearchController.dispose();
    super.dispose();
  }

  void refreshData() {
    print("Refreshing activity data");
    _fetchAllActivities();
    _joinedActivities();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredActivities =
          activities.where((activity) {
            final name =
                activity['Activity_name']?.toString().toLowerCase() ?? '';
            final rso =
                activity['RSO_details']?['RSO_name']
                    ?.toString()
                    .toLowerCase() ??
                '';
            return name.contains(query) || rso.contains(query);
          }).toList();
    });
  }

  void _onYourActivitiesSearchChanged() {
    final query = _yourActivitiesSearchController.text.toLowerCase();
    setState(() {
      filteredJoinedActivities =
          joinedActivities.where((activity) {
            final name =
                activity['Activity_name']?.toString().toLowerCase() ?? '';
            final rso =
                activity['RSO_details']?['RSO_name']
                    ?.toString()
                    .toLowerCase() ??
                '';
            return name.contains(query) || rso.contains(query);
          }).toList();
    });
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
            filteredActivities = activities;
            _isLoading = false;
          });

          print("filtered Activities from all RSOs: $filteredActivities");
        }
      } else {
        setState(() {
          activities = [];
        });
        print(
          "error code ${response.statusCode} and message ${responseData['message']}",
        );
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

  Future<void> _joinedActivities() async {
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
            Uri.parse('${AppConfig.baseUrl}/api/student/user/userProfile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': token,
            },
          )
          .timeout(Duration(seconds: 20));

      final responseData = jsonDecode(response.body);
      print(
        "printing response joined Activities ${responseData['activities']}",
      );

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (mounted) {
          setState(() {
            joinedActivities = List<Map<String, dynamic>>.from(
              responseData['activities'] ?? '',
            );
            filteredJoinedActivities = joinedActivities;
            _isLoading = false;
            print(
              "Lagay yung joined activities sa list $filteredJoinedActivities",
            );
          });
        }
      } else {
        setState(() {
          joinedActivities = [];
        });
        print(
          "error code ${response.statusCode} and message ${responseData['message']}",
        );
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
              onPressed: () {
                Navigator.of(context).pushNamed('/notificationScreen');
              },
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
                                : GestureDetector(
                                  onTap: () => FocusScope.of(context).unfocus(),
                                  child: SingleChildScrollView(
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .manual,
                                    child: Column(
                                      children: [
                                        //search bar
                                        TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Search activities...',
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: nuBlue,
                                            ),
                                            suffixIcon:
                                                _searchController
                                                        .text
                                                        .isNotEmpty
                                                    ? IconButton(
                                                      icon: Icon(
                                                        Icons.clear,
                                                        color: nuBlue,
                                                      ),
                                                      onPressed: () {
                                                        _searchController
                                                            .clear();
                                                        setState(
                                                          () =>
                                                              filteredActivities =
                                                                  activities,
                                                        );
                                                      },
                                                    )
                                                    : null,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: nuBlue,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 8.h,
                                                ),
                                          ),
                                        ),

                                        SizedBox(height: 10.h),

                                        if (filteredActivities.isEmpty)
                                          Center(
                                            child: CustomFont(
                                              text:
                                                  "No activities match your search",
                                              fontSize: 16.r,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        else
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount:
                                                filteredActivities.length,
                                            itemBuilder: (context, index) {
                                              final activity =
                                                  filteredActivities[index];

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
                                                status:
                                                    activity['Activity_date_status'] ??
                                                    'Unknown',
                                                description:
                                                    activity['Activity_description'] ??
                                                    "Activity description",
                                                publicity:
                                                    activity['Activity_publicity'],
                                                onTap: () {
                                                  print(
                                                    "printing activity id: ${activity['_id']}",
                                                  );
                                                  Navigator.of(
                                                    context,
                                                  ).pushNamed(
                                                    '/viewActivityScreen',
                                                    arguments: {
                                                      'activityID':
                                                          activity['_id'],
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
                      ),
                    ],

                    if (_selectedIndex == 1) ...[
                      Expanded(
                        child:
                            joinedActivities.isEmpty
                                ? Center(
                                  child: CustomFont(
                                    text:
                                        "No Activities Available At The Moment",
                                    fontSize: 16.r,
                                    color: Colors.grey.shade600,
                                  ),
                                )
                                : GestureDetector(
                                  onTap: () => FocusScope.of(context).unfocus(),
                                  child: SingleChildScrollView(
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .manual,
                                    child: Column(
                                      children: [
                                        //search button
                                        TextField(
                                          controller:
                                              _yourActivitiesSearchController,
                                          decoration: InputDecoration(
                                            hintText: 'Search activities...',
                                            prefixIcon: Icon(
                                              Icons.search,
                                              color: nuBlue,
                                            ),
                                            suffixIcon:
                                                _yourActivitiesSearchController
                                                        .text
                                                        .isNotEmpty
                                                    ? IconButton(
                                                      icon: Icon(
                                                        Icons.clear,
                                                        color: nuBlue,
                                                      ),
                                                      onPressed: () {
                                                        _yourActivitiesSearchController
                                                            .clear();
                                                        setState(
                                                          () =>
                                                              filteredActivities =
                                                                  activities,
                                                        );
                                                      },
                                                    )
                                                    : null,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                color: nuBlue,
                                              ),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 8.h,
                                                ),
                                          ),
                                        ),

                                        SizedBox(height: 10.h),

                                        if (filteredJoinedActivities.isEmpty)
                                          Center(
                                            child: CustomFont(
                                              text:
                                                  "No activities match your search",
                                              fontSize: 16.r,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        else
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount:
                                                filteredJoinedActivities.length,
                                            itemBuilder: (context, index) {
                                              final activity =
                                                  filteredJoinedActivities[index];

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
                                                status:
                                                    activity['Activity_date_status'] ??
                                                    'Unknown',
                                                description:
                                                    activity['Activity_description'] ??
                                                    "Activity description",
                                                publicity:
                                                    activity['Activity_publicity'],
                                                onTap: () {
                                                  print(
                                                    "printing activity id: ${activity['_id']}",
                                                  );
                                                  Navigator.of(
                                                    context,
                                                  ).pushNamed(
                                                    '/viewActivityScreen',
                                                    arguments: {
                                                      'activityID':
                                                          activity['_id'],
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
                      ),
                    ],
                  ],
                ),
              ),
    );
  }
}
