import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/services/api_service.dart';
import 'package:nuspace_app/widgets/custombutton.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/customfont.dart';
import '../../widgets/snackbarhelper.dart';

class ViewActivityScreen extends StatefulWidget {
  final String? activityID;
  const ViewActivityScreen({super.key, required this.activityID});

  @override
  State<ViewActivityScreen> createState() => _ViewActivityScreenState();
}

class _ViewActivityScreenState extends State<ViewActivityScreen> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? activityDetails;
  bool _isLoading = true;
  bool? isCurrentRSOMember;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    _fetchActivityDetails();
  }

  Future<void> _fetchActivityDetails() async {
    print("View RSO Screen rsoId: ${widget.activityID}");

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
                '${AppConfig.baseUrl}/api/student/activities/viewActivity/${widget.activityID}',
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

      if (response.statusCode == 200 || responseData['success'] == true) {
        if (mounted) {
          setState(() {
            activityDetails = responseData['activity'];
            isCurrentRSOMember = responseData['isCurrentRSOMember'];
            _isLoading = false;
          });
        }
        print("Printing activity detaills success: $activityDetails");
      } else {
        print(
          "Error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          activityDetails = null;
          _isLoading = false;
        });
        print("Printing rso details failed: $activityDetails");
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
    bool isOpenForAll = activityDetails?['Activity_publicity'] == true;
    DateTime? startDate;
    DateTime? endDate;

    try {
      startDate =
          DateTime.parse(activityDetails?['Activity_start_datetime']).toLocal();
      endDate =
          DateTime.parse(activityDetails?['Activity_end_datetime']).toLocal();
    } catch (e) {
      startDate = null;
      endDate = null;
    }

    String dateString = '';
    String timeString = '';
    String shortDateString = '';

    if (startDate != null && endDate != null) {
      //exmample, sunday, june 29
      //if date is different like its not the same day
      if (startDate.year == endDate.year &&
          startDate.month == endDate.month &&
          startDate.day == endDate.day) {
        dateString = DateFormat('EEEE').format(startDate);
      } else {
        //if not then
        dateString =
            '${DateFormat('EEEE').format(startDate)} - ${DateFormat('EEEE').format(endDate)}';
      }

      //example: 7:00 AM - 5:00 PM
      timeString =
          '${DateFormat('h:mm a').format(startDate)} to ${DateFormat('h:mm a').format(endDate)}';

      if (startDate.year == endDate.year &&
          startDate.month == endDate.month &&
          startDate.day == endDate.day) {
        shortDateString = DateFormat('MMMM d, yyyy').format(startDate);
      } else {
        shortDateString =
            '${DateFormat('MMMM d, yyyy').format(startDate)} - ${DateFormat('MMMM d, yyyy').format(endDate)}';
      }
    } else {
      dateString = 'No date available';
      timeString = 'No time available';
      shortDateString = 'No short date';
    }

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
              : activityDetails == null
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
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          //RSO profile picture
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30.r),
                            child: CachedNetworkImage(
                              imageUrl:
                                  activityDetails?['RSO_id']['RSO_picture'] ??
                                  '',
                              width: 50.r,
                              height: 50.r,
                              memCacheHeight: 100,
                              memCacheWidth: 100,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    width: 50.r,
                                    height: 50.r,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    width: 50.r,
                                    height: 50.r,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                          SizedBox(width: 12.w),

                          //RSO acronym and name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomFont(
                                  text:
                                      activityDetails?['RSO_id']['RSO_acronym'] ??
                                      "RSO Acronym",
                                  fontSize: 16.r,
                                  fontWeight: FontWeight.w600,
                                ),
                                SizedBox(height: 5.h),
                                CustomFont(
                                  text:
                                      activityDetails?['RSO_id']['RSO_name'] ??
                                      "RSO Name",
                                  fontSize: 14.r,
                                ),
                              ],
                            ),
                          ),

                          //activity status
                          CustomFont(
                            text:
                                activityDetails?['Activity_date_status'] ==
                                        'upcoming'
                                    ? 'Upcoming '
                                    : activityDetails?['Activity_date_status'] ==
                                        'ongoing'
                                    ? 'On Going'
                                    : activityDetails?['Activity_date_status'] ==
                                        'done'
                                    ? 'Done'
                                    : 'Unknown',
                            fontSize: 14.r,
                            color:
                                activityDetails?['Activity_date_status'] ==
                                        'upcoming'
                                    ? nuBlue
                                    : activityDetails?['Activity_date_status'] ==
                                        'ongoing'
                                    ? Colors.red
                                    : activityDetails?['Activity_date_status'] ==
                                        'done'
                                    ? Colors.green
                                    : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),

                      SizedBox(height: 10.h),

                      //display image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          color: Colors.grey[300],
                          child: CachedNetworkImage(
                            imageUrl: activityDetails?['Activity_image'] ?? '',
                            height: 300.h,
                            width: double.infinity,
                            memCacheHeight: 600,
                            memCacheWidth: 800,
                            fit: BoxFit.contain,
                            placeholder:
                                (context, url) => Container(
                                  width: 50.r,
                                  height: 50.r,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  width: 50.r,
                                  height: 50.r,
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported,
                                          size: 100.r,
                                          color: Colors.grey,
                                        ),
                                        CustomFont(
                                          text: "No Image Available",
                                          fontSize: 14.r,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10.h),

                      //Activity name
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomFont(
                              text:
                                  activityDetails?['Activity_name'] ??
                                  "Activity name not available",
                              fontSize: 18.r,
                              fontWeight: FontWeight.bold,
                              maxLines: 3,
                            ),
                            SizedBox(height: 5.h),
                            CustomFont(text: shortDateString, fontSize: 14.r),
                            SizedBox(height: 10.h),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30.w,
                                  vertical: 15.h,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 30.r,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 10.w),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CustomFont(
                                              text: dateString,
                                              fontSize: 14.r,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            SizedBox(height: 5.h),
                                            CustomFont(
                                              text: timeString,
                                              fontSize: 14.r,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 30.r,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 10.w),
                                        CustomFont(
                                          text:
                                              activityDetails?['Activity_place'] ??
                                              "Activity Place Not Available",
                                          fontSize: 14.r,
                                          fontWeight: FontWeight.w600,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15.h),
                                    Row(
                                      children: [
                                        Icon(
                                          isOpenForAll
                                              ? Icons.people_outline
                                              : Icons.people_alt_outlined,
                                          size: 30.r,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 10.w),
                                        CustomFont(
                                          text:
                                              isOpenForAll
                                                  ? "Open for all"
                                                  : "Only for RSO Members",
                                          fontSize: 14.r,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 10.h),
                            CustomFont(
                              text: "Event details",
                              fontSize: 16.r,
                              fontWeight: FontWeight.w700,
                            ),
                            SizedBox(height: 10.h),
                            CustomFont(
                              text:
                                  activityDetails?['Activity_description'] ??
                                  "Activity description not available",
                              fontSize: 14.r,
                            ),
                            SizedBox(height: 20.h),

                            if (activityDetails?['Activity_date_status'] ==
                                'upcoming') ...[
                              if (activityDetails?['Activity_publicity'] ==
                                      true ||
                                  isCurrentRSOMember == true) ...[
                                CustomButton(
                                  text: "Join Activity",
                                  height: 40.h,
                                  fontSize: 14.r,
                                  fontweight: FontWeight.bold,
                                  onPressed: () {
                                    if (!connectivityService.isConnected) {
                                      print("No Internet Connection");
                                      SnackbarHelper.showConnectivityStatus(
                                        false,
                                      );
                                      return;
                                    }
                                    Navigator.of(context).pushNamed(
                                      '/activityForms',
                                      arguments: {
                                        'activityId': activityDetails?['_id'],
                                        'formType': 'pre-activity',
                                      },
                                    );
                                  },
                                ),
                              ] else ...[
                                CustomButton(
                                  text: "Only For RSO Members",
                                  height: 40.h,
                                  fontSize: 14.r,
                                  fontweight: FontWeight.bold,
                                  onPressed: null,
                                ),
                              ],
                            ] else if (activityDetails?['Activity_date_status'] ==
                                'done') ...[
                              if (activityDetails?['Activity_feedback_deadline'] !=
                                      null &&
                                  DateTime.now().isBefore(
                                    DateTime.parse(
                                      activityDetails!['Activity_feedback_deadline'],
                                    ),
                                  )) ...[
                                CustomButton(
                                  //may deadline to
                                  text: "Activity Feedback",
                                  height: 40.h,
                                  fontSize: 14.r,
                                  fontweight: FontWeight.bold,
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      '/activityForms',
                                      arguments: {
                                        'activityId': activityDetails?['_id'],
                                        'formType': 'post-activity',
                                      },
                                    );
                                  },
                                ),
                              ],
                            ],
                            SizedBox(height: 50.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
