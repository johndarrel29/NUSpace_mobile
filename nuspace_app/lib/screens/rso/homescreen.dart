import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/services/api_service.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import 'package:nuspace_app/widgets/customrecommendrso.dart';
import 'package:nuspace_app/widgets/customrso_listtile.dart';
import 'package:nuspace_app/widgets/customtabswitch.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/snackbarhelper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> suggestedRSOs = [];
  List<Map<String, dynamic>> otherRSOs = [];
  List<Map<String, dynamic>> joinedRSOs = [];
  Map<String, dynamic>? recommendationExplanation;
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
  }

  void refreshData() {
    setState(() {
      _isLoading = true;
    });
    _fetchRecommendedRSOs();
    _fetchAllJoinedRSOs();
  }

  Future<void> _fetchRecommendedRSOs() async {
    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .get(
              Uri.parse('${AppConfig.baseUrl}/api/student/rso/recommendRSO'),
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
            suggestedRSOs = List<Map<String, dynamic>>.from(
              responseData['data']['prioritized'] ?? [],
            );
            otherRSOs = List<Map<String, dynamic>>.from(
              responseData['data']['others'] ?? [],
            );

            //explanation
            recommendationExplanation = responseData['data']['explanation'];

            _isLoading = false;
          });

          print("Suggested RSOs: $suggestedRSOs");
          print("recommendation explanation $recommendationExplanation");
          print("Other RSOs: $otherRSOs");
        }
      } else {
        print(
          "error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          suggestedRSOs = [];
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

  Future<void> _fetchAllJoinedRSOs() async {
    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .get(
              Uri.parse('${AppConfig.baseUrl}/api/student/user/userProfile'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': accessToken,
              },
            )
            .timeout(Duration(seconds: 20));
      }, context: mounted ? context : null);

      if (response == null) return; //session expired

      final responseData = jsonDecode(response.body);
      print("Response data for joined RSOs: $responseData");

      if (response.statusCode == 200 && responseData['success'] == true) {
        final membershipList = responseData['joinedRSOs'];

        setState(() {
          joinedRSOs = List<Map<String, dynamic>>.from(membershipList);
          _isLoading = false;
        });

        print("Joined RSOs: $joinedRSOs");
      } else {
        print(
          "Error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          joinedRSOs = [];
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTabSwitch(
                      tabs: ["For You", "Your RSOs"],
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
                            suggestedRSOs.isEmpty ||
                                    recommendationExplanation == null
                                ? Center(
                                  child: CustomFont(
                                    text: "No RSO was recommended for you.",
                                    fontSize: 14.r,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                                : SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomFont(
                                        text: "Recommended RSO for you",
                                        fontSize: 14.r,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                      SizedBox(height: 10.h),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: suggestedRSOs.length.clamp(
                                          0,
                                          3,
                                        ),
                                        itemBuilder: (context, index) {
                                          final rso = suggestedRSOs[index];
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 5.h,
                                            ),
                                            child: CustomRecommendRSO(
                                              imageUrl: rso['logo'] ?? '',
                                              acronym: rso['acronym'] ?? '',
                                              priority: rso['priority'] ?? '',
                                              explanation:
                                                  rso['explanation'] ?? '',
                                              rank: index + 1,
                                              onTap: () {
                                                Navigator.of(context).pushNamed(
                                                  '/viewRSOScreen',
                                                  arguments: {
                                                    'rsoId': rso['rsoId'],
                                                  },
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),

                                      if (otherRSOs.isNotEmpty) ...[
                                        Divider(color: Colors.grey),
                                        SizedBox(height: 5.h),
                                        CustomFont(
                                          text: "Other RSO for you",
                                          fontSize: 14.r,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                        SizedBox(height: 5.h),
                                        //others
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          itemCount: otherRSOs.length,
                                          itemBuilder: (context, index) {
                                            final rso = otherRSOs[index];
                                            return CustomRSOListTile(
                                              imageUrl: rso['logo'] ?? '',
                                              acronym: rso['acronym'] ?? '',
                                              college: rso['college'] ?? '',
                                              category: rso['category'] ?? '',
                                              probationary: rso['probationary'],
                                              onTap: () {
                                                Navigator.of(context).pushNamed(
                                                  '/viewRSOScreen',
                                                  arguments: {
                                                    'rsoId': rso['rsoId'],
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                      ),
                    ],

                    if (_selectedIndex == 1) ...[
                      Expanded(
                        child:
                            joinedRSOs.isEmpty
                                ? Center(
                                  child: CustomFont(
                                    text: "You haven't joined any RSO yet",
                                    fontSize: 14.r,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                                : SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Tab 1: Joined RSOs
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: joinedRSOs.length,
                                        itemBuilder: (context, index) {
                                          final rso = joinedRSOs[index];
                                          print("Printing joined RSOs: $rso");
                                          return CustomRSOListTile(
                                            imageUrl: rso['RSO_picture'] ?? '',
                                            acronym: rso['acronym'] ?? '',
                                            college: rso['college'] ?? '',
                                            category: rso['category'] ?? '',
                                            probationary: rso['probationary']!,
                                            onTap: () {
                                              print(
                                                "Going to announcement screen of RSO",
                                              );
                                              Navigator.of(context).pushNamed(
                                                '/announcementScreen',
                                                arguments: {
                                                  'rsoId': rso['rsoId'],
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
