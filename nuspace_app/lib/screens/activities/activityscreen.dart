import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/services/api_service.dart';
import 'package:nuspace_app/widgets/activitycard.dart';
import 'package:nuspace_app/widgets/customtabswitch.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/custombutton.dart';
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

  int activitiesLimit = 5;
  int activitesPage = 1;
  bool _activitiesHasNextPage = true;

  int profileActivitiesLimit = 5;
  int profileActivitiesPage = 1;
  bool _profileActivitiesHasNextPage = true;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
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

  Future<void> _fetchAllActivities({bool append = false}) async {
    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .get(
              Uri.parse(
                '${AppConfig.baseUrl}/api/student/activities/getallActivities?page=$activitesPage&limit=$activitiesLimit',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': accessToken,
              },
            )
            .timeout(Duration(seconds: 20));
      }, context: mounted ? context : null);

      if (response == null) return; //session expired

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (mounted) {
          setState(() {
            final newActivities = List<Map<String, dynamic>>.from(
              responseData['activities'] ?? [],
            );

            if (append) {
              activities.addAll(newActivities);
            } else {
              activities = newActivities;
            }

            filteredActivities = activities;
            _activitiesHasNextPage =
                responseData['pagination']?['hasNextPage'] ?? false;
            _isLoading = false;
          });

          print("filtered Activities from all RSOs: $filteredActivities");
          print(
            "total activities: ${responseData['pagination']?['totalActivities']}",
          );
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinedActivities({bool loadMore = false}) async {
    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .get(
              Uri.parse(
                '${AppConfig.baseUrl}/api/student/user/userProfile?page=$profileActivitiesPage&limit=$profileActivitiesLimit',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': accessToken,
              },
            )
            .timeout(Duration(seconds: 20));
      }, context: mounted ? context : null);

      if (response == null) return; //session expired

      final responseData = jsonDecode(response.body);
      print(
        "printing response joined Activities ${responseData['activities']}",
      );

      if (response.statusCode == 200 && responseData['success'] == true) {
        final newJoinedActivities = List<Map<String, dynamic>>.from(
          responseData['activities'] ?? [],
        );

        if (mounted) {
          setState(() {
            if (loadMore) {
              joinedActivities.addAll(newJoinedActivities);
            } else {
              joinedActivities = newJoinedActivities;
            }

            filteredJoinedActivities = joinedActivities;

            _profileActivitiesHasNextPage =
                responseData['pagination']?['hasNextPage'] ?? false;

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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                text: "NU",
                fontSize: 22.r,
                color: nuGold,
                useGoogleFont: false,
                fontFamily: 'ClanOT',
                fontWeight: FontWeight.bold,
              ),
              CustomFont(
                text: "Space",
                fontSize: 22.r,
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
                if (!connectivityService.isConnected) {
                  print("No Internet Connection");
                  SnackbarHelper.showConnectivityStatus(false);
                  return;
                }
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
              : !connectivityService.isConnected
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: Colors.grey.shade600,
                      size: 50.r,
                    ),
                    CustomFont(
                      text: "Connect to Internet",
                      fontSize: 16.r,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
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
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.grey.shade600,
                                        size: 50.r,
                                      ),
                                      CustomFont(
                                        text:
                                            "No Activities Available At The Moment",
                                        fontSize: 16.r,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
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
                                                filteredActivities.length + 1,
                                            itemBuilder: (context, index) {
                                              if (index ==
                                                  filteredActivities.length) {
                                                if (_isLoading) {
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                }

                                                if (!_activitiesHasNextPage) {
                                                  return SizedBox.shrink();
                                                }

                                                return Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 12.h,
                                                  ),
                                                  child: CustomButton(
                                                    text: "See more",
                                                    fontSize: 16.r,
                                                    fontweight: FontWeight.bold,
                                                    onPressed: () {
                                                      setState(() {
                                                        activitesPage += 1;
                                                      });
                                                      _fetchAllActivities(
                                                        append: true,
                                                      );
                                                    },
                                                  ),
                                                );
                                              }

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
                                                  if (!connectivityService
                                                      .isConnected) {
                                                    print(
                                                      "No Internet Connection",
                                                    );
                                                    SnackbarHelper.showConnectivityStatus(
                                                      false,
                                                    );
                                                    return;
                                                  }
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
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.grey.shade600,
                                        size: 50.r,
                                      ),
                                      CustomFont(
                                        text:
                                            "No Activities Available At The Moment",
                                        fontSize: 16.r,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
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
                                                filteredJoinedActivities
                                                    .length +
                                                1,
                                            itemBuilder: (context, index) {
                                              if (index ==
                                                  filteredJoinedActivities
                                                      .length) {
                                                if (_isLoading) {
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                }

                                                if (!_profileActivitiesHasNextPage) {
                                                  return SizedBox.shrink();
                                                }

                                                return Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 12.h,
                                                  ),
                                                  child: CustomButton(
                                                    text: "See more",
                                                    fontSize: 16.r,
                                                    fontweight: FontWeight.bold,
                                                    onPressed: () {
                                                      setState(() {
                                                        profileActivitiesPage +=
                                                            1;
                                                      });
                                                      _joinedActivities(
                                                        loadMore: true,
                                                      );
                                                    },
                                                  ),
                                                );
                                              }

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
                                                  if (!connectivityService
                                                      .isConnected) {
                                                    print(
                                                      "No Internet Connection",
                                                    );
                                                    SnackbarHelper.showConnectivityStatus(
                                                      false,
                                                    );
                                                    return;
                                                  }
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
