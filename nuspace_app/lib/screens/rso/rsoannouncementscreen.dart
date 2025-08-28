import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/services/api_service.dart';
import 'package:nuspace_app/widgets/customtabswitch.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/customfont.dart';
import '../../widgets/snackbarhelper.dart';
import '../../widgets/viewrso_activitycard.dart';

class RSOAnnouncementScreen extends StatefulWidget {
  final String? rsoId;
  const RSOAnnouncementScreen({super.key, required this.rsoId});

  @override
  State<RSOAnnouncementScreen> createState() => _RSOAnnouncementScreenState();
}

class _RSOAnnouncementScreenState extends State<RSOAnnouncementScreen> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? announcementResponse;
  Map<String, dynamic>? rsoDetails;
  List<dynamic> _announcements = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    _fetchAnnouncements();
    _fetchRSODetails();
  }

  Future<void> _fetchAnnouncements() async {
    print("View announcement screen rsoId: ${widget.rsoId}");
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
              Uri.parse(
                '${AppConfig.baseUrl}/api/student/announcements/getStudentAnnouncement/${widget.rsoId}',
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
      print("response data: $responseData");
      if (response.statusCode == 200 && responseData['success'] == true) {
        if (mounted) {
          setState(() {
            final List<dynamic> announcementList =
                responseData['sortedAnnouncements'] ?? [];
            _isLoading = false;
            _announcements = announcementList;
          });
        }
        print("Announcements fetched :$_announcements");
      } else {
        print(
          "Error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          _announcements = [];
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

  Future<void> _fetchRSODetails() async {
    print("View RSO Screen rsoId: ${widget.rsoId}");
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
              Uri.parse(
                '${AppConfig.baseUrl}/api/student/rso/viewRSO/${widget.rsoId}',
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
            rsoDetails = responseData['rsoDetails'];
            _isLoading = false;
          });
        }
        print("Printing rso details success: $rsoDetails");
      } else {
        print(
          "Error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          rsoDetails = null;
        });
        print("Printing rso details failed: $rsoDetails");
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
        centerTitle: true,
        leading: IconButton(
          onPressed: () async {
            FocusScope.of(context).unfocus(); // First dismiss keyboard
            await Future.delayed(
              const Duration(milliseconds: 300), //change to 500 if want
            ); // Wait for keyboard to fully close

            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          icon: Icon(Icons.arrow_back, size: 24.r),
        ),
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
              : _announcements.isEmpty
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
                      text: "No RSO announcements available",
                      fontSize: 16.r,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  CustomTabSwitch(
                    tabs: ['Announcements', 'Activities'],
                    selectedIndex: _selectedIndex,
                    onTabSelected: (value) {
                      setState(() {
                        _selectedIndex = value;
                      });
                    },
                  ),
                  if (_selectedIndex == 0) ...[
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        child: _buildAnnouncements(),
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.w,
                          vertical: 10.h,
                        ),
                        child: _rsoActivities(),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildAnnouncements() {
    return ListView.builder(
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final announcement = _announcements[index];

        String formattedDate = '';
        final dateStr = announcement['createdAt'] ?? '';
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          final local = parsed.toLocal();

          formattedDate = DateFormat("MMMM d, y | h:mm a").format(local);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //date
              CustomFont(
                text: formattedDate,
                fontSize: 14.r,
                color: Colors.grey.shade700,
              ),
              SizedBox(height: 8.h),

              //title
              CustomFont(
                text: announcement['title'] ?? '',
                fontSize: 20.r,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 10.h),

              //content
              CustomFont(
                text: announcement['content'] ?? '',
                fontSize: 16.r,
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 12.h),
              Divider(thickness: 1, color: Colors.grey.shade400),
            ],
          ),
        );
      },
    );
  }

  Widget _rsoActivities() {
    final activities = rsoDetails?['RSO_activities'] ?? [];

    if (activities.isEmpty) {
      return Center(
        child: CustomFont(
          text: "No Activities Available in this RSO",
          fontSize: 16.r,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];

        //parse the date from backend
        DateTime? startDate;
        try {
          startDate =
              DateTime.parse(activity['Activity_start_datetime']).toLocal();
        } catch (e) {
          startDate = null;
        }

        //tas convert na yung date into string
        String dateString =
            startDate != null
                ? DateFormat('MMMM d, yyyy • h:mm a').format(startDate)
                : "No date available";

        return ViewRSOActivityCard(
          imageUrl: activity['Activity_image'],
          name: activity['Activity_name'],
          date: dateString,
          description: activity["Activity_description"],
          publicity: activity['Activity_publicity'],
          status: activity['Activity_date_status'],
          onTap: () {
            print("Printing activity ID: ${activity["_id"]}");
            Navigator.of(context).pushNamed(
              '/viewActivityScreen',
              arguments: {'activityID': activity['_id']},
            );
          },
        );
      },
    );
  }
}
