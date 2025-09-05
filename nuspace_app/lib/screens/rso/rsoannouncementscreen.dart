import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/services/api_service.dart';
import 'package:nuspace_app/widgets/custombutton.dart';
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
  List<dynamic> _activities = [];
  List<dynamic> _announcements = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  int announcementlimit = 5;
  int announcementpage = 1;
  bool _announcementHasNextPage = true;

  int activitiesLimit = 5;
  int activitiesPage = 1;
  bool _activitiesHasNextPage = true;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    _fetchAnnouncements();
    _fetchRSOActivities();
  }

  Future<void> _fetchAnnouncements({bool append = false}) async {
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
                '${AppConfig.baseUrl}/api/student/announcements/getStudentAnnouncement/${widget.rsoId}?page=$announcementpage&limit=$announcementlimit',
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
            final List<dynamic> announcementList = responseData['data'] ?? [];
            if (append) {
              _announcements.addAll(announcementList);
            } else {
              _announcements = announcementList;
            }

            _announcementHasNextPage =
                responseData['pagination']?['hasNextPage'] ?? false;
            _isLoading = false;
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

  Future<void> _fetchRSOActivities({bool append = false}) async {
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
                '${AppConfig.baseUrl}/api/student/activities/getRSOActivities/${widget.rsoId}?page=$activitiesPage&limit=$activitiesLimit',
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
            final List<dynamic> activitiesList = responseData['data'] ?? [];

            if (append) {
              _activities.addAll(activitiesList);
            } else {
              _activities = activitiesList;
            }

            _activitiesHasNextPage = responseData['pagination']?['hasNextPage'];
            _isLoading = false;
          });
        }
        print("Printing activities list success: $_activities");
      } else {
        print(
          "Error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          _activities = [];
        });
        print("Printing activities list failed: $_activities");
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
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: nuBlue, strokeAlign: 5),
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
    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.grey, size: 50.r),
            SizedBox(height: 5.h),
            CustomFont(
              text: "No RSO announcements available",
              fontSize: 16.r,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _announcements.length + 1,
      itemBuilder: (context, index) {
        if (index == _announcements.length) {
          if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (!_announcementHasNextPage) {
            return SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: CustomButton(
              text: "See more",
              fontSize: 16.r,
              fontweight: FontWeight.bold,
              onPressed: () {
                setState(() {
                  announcementpage += 1;
                });
                _fetchAnnouncements(append: true);
              },
            ),
          );
        }

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
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.grey, size: 50.r),
            SizedBox(height: 5.h),
            CustomFont(
              text: "No Activities Available in this RSO",
              fontSize: 16.r,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _activities.length + 1,
      itemBuilder: (context, index) {
        if (index == _activities.length) {
          if (_isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (!_activitiesHasNextPage) {
            return SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: CustomButton(
              text: "See More",
              fontSize: 16.r,
              fontweight: FontWeight.bold,
              onPressed: () {
                setState(() {
                  activitiesPage += 1;
                });
                _fetchRSOActivities(append: true);
              },
            ),
          );
        }

        final activity = _activities[index];
        print("Printing activity $activity");

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
          imageUrl: activity['imageUrl'] ?? '',
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
