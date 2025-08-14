import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/widgets/custom_interestchip.dart';
import 'package:nuspace_app/widgets/customtabswitch.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/customfont.dart';
import '../../widgets/snackbarhelper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? profileDetails;
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
    _fetchProfileDetails();
  }

  Future<void> _fetchProfileDetails() async {
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

      if (response.statusCode == 200 && responseData['success'] == true) {
        if (mounted) {
          setState(() {
            profileDetails = Map<String, dynamic>.from(
              responseData['user'] ?? [],
            );
            _isLoading = false;
          });

          print("Profile details: $profileDetails");
        }
      } else {
        print(
          "Error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          profileDetails = null;
        });
        print("Profile details: $profileDetails");
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
              icon: Icon(Icons.logout, size: 24.r),
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
              : profileDetails == null
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
                      text: "No RSO details found",
                      fontSize: 16.r,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ],
                ),
              )
              : Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.h),
                child: Column(
                  children: [
                    //upper half
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          CustomFont(
                            text: "Profile",
                            fontSize: 18.r,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: 30.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomFont(
                                text:
                                    profileDetails?['firstName'] ??
                                    "First Name",
                                fontSize: 20.r,
                                fontWeight: FontWeight.w600,
                              ),
                              CustomFont(text: " ", fontSize: 20.r),
                              CustomFont(
                                text: profileDetails?['lastName'],
                                fontSize: 20.r,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          CustomFont(
                            text: profileDetails?['email'] ?? "Email",
                            fontSize: 14.r,
                          ),
                          SizedBox(height: 5.h),
                          CustomFont(
                            text: profileDetails?['college'] ?? "college",
                            fontSize: 14.r,
                          ),
                          SizedBox(height: 15.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () {
                                  print("Going to edit profile screen");
                                },
                                child: Container(
                                  height: 30.h,
                                  width: 100.w,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Center(
                                    child: CustomFont(
                                      text: "Edit Profile",
                                      fontSize: 14.r,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    CustomTabSwitch(
                      tabs: ['Your Interests'],
                      selectedIndex: 0,
                      onTabSelected: (value) {},
                    ),
                    //lower half
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 10.h),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              CustomFont(
                                text: "Want to change preferences?",
                                fontSize: 14.r,
                                fontWeight: FontWeight.w500,
                              ),
                              InkWell(
                                onTap: () {
                                  print("Going to interests screen");
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 2.h,
                                  ),
                                  child: CustomFont(
                                    text: " Click here",
                                    fontSize: 14.r,
                                    color: nuBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          if (profileDetails?['student_interests'] != null &&
                              profileDetails!['student_interests'].isNotEmpty)
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              alignment: WrapAlignment.center,
                              children: List.generate(
                                profileDetails!['student_interests'].length,
                                (index) {
                                  final interest =
                                      profileDetails!['student_interests'][index];
                                  return InterestChip(
                                    label: interest,
                                    isSelected: false,
                                    onTap: () {},
                                  );
                                },
                              ),
                            )
                          else
                            Center(
                              child: CustomFont(
                                text: "No interests set yet",
                                fontSize: 14.r,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
