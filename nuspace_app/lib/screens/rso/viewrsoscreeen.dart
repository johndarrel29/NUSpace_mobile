import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/custom_interestchip.dart';
import 'package:nuspace_app/widgets/custombutton.dart';
import 'package:nuspace_app/widgets/viewrso_activitycard.dart';
import 'package:nuspace_app/widgets/customtabswitch.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/customfont.dart';
import '../../widgets/customofficercard.dart';
import '../../widgets/snackbarhelper.dart';

class ViewRSOScreen extends StatefulWidget {
  final String? rsoId;
  const ViewRSOScreen({super.key, required this.rsoId});

  @override
  State<ViewRSOScreen> createState() => _ViewRSOScreenState();
}

class _ViewRSOScreenState extends State<ViewRSOScreen> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? rsoDetails;
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool isCurrentMember = false;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    _fetchRSODetails();
  }

  Future<void> _fetchRSODetails() async {
    print("View RSO Screen rsoId: ${widget.rsoId}");
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
              '${AppConfig.baseUrl}/api/student/rso/viewRSO/${widget.rsoId}',
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
            rsoDetails = responseData['rsoDetails'];
            isCurrentMember = responseData['isCurrentUserMember'];
            _isLoading = false;
          });
        }
        print("Printing rso details success: $rsoDetails");
        print("Is current member: $isCurrentMember");
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
              : rsoDetails == null
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
              : Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(30.r),
                            child: CachedNetworkImage(
                              imageUrl: rsoDetails?['RSO_picture'] ?? '',
                              width: 50.r,
                              height: 50.r,
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
                          title: CustomFont(
                            text:
                                rsoDetails?['RSO_snapshot']?['acronym'] ??
                                "RSO Acronym",
                            fontSize: 16.r,
                            fontWeight: FontWeight.w600,
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 5.h),
                            child: CustomFont(
                              text:
                                  rsoDetails?['RSO_snapshot']?['name'] ??
                                  "RSO Name",
                              fontSize: 14.r,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        //tags
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 8.r,
                          runSpacing: 8.r,
                          children:
                              (rsoDetails?['RSO_tags'] as List<dynamic>? ?? [])
                                  .map((tagObj) {
                                    final tagLabel = tagObj['tag'] ?? '';
                                    return InterestChip(
                                      label: tagLabel,
                                      isSelected: false,
                                      isDisabled: false,
                                      onTap: () {},
                                    );
                                  })
                                  .toList(),
                        ),

                        SizedBox(height: 10.h),

                        //customTabSwitch
                        CustomTabSwitch(
                          tabs: ["Details", "Activities"],
                          selectedIndex: _selectedIndex,
                          fontSize: 14,
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
                            child: SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: CustomFont(
                                        text:
                                            rsoDetails?['RSO_snapshot']?['description'] ??
                                            "RSO Description",
                                        fontSize: 14.r,
                                        textAlign: TextAlign.justify,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: CustomFont(
                                        text: "Officers",
                                        fontSize: 14.r,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),

                                    if (rsoDetails?['RSO_Officers'].isEmpty)
                                      Center(
                                        child: CustomFont(
                                          text: "No Officers Yet",
                                          fontSize: 16.r,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    Wrap(
                                      spacing: 12.w,
                                      runSpacing: 12.h,
                                      alignment: WrapAlignment.center,
                                      children:
                                          (rsoDetails?['RSO_Officers']
                                                      as List<dynamic>? ??
                                                  [])
                                              .map(
                                                (officer) => CustomOfficerCard(
                                                  imageUrl:
                                                      officer['OfficerPicture'],
                                                  name:
                                                      officer['OfficerName'] ??
                                                      'Officer Name',
                                                  position:
                                                      officer['OfficerPosition'] ??
                                                      'Position',
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (_selectedIndex == 1) ...[
                          if (rsoDetails?['RSO_activities'].isEmpty)
                            Expanded(
                              child: Center(
                                child: CustomFont(
                                  text: "No Activities Available in this RSO",
                                  fontSize: 16.r,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: rsoDetails?['RSO_activities'].length,
                              itemBuilder: (context, index) {
                                final activity =
                                    rsoDetails?['RSO_activities'][index];

                                //parse the date from backend
                                DateTime? startDate;
                                try {
                                  startDate =
                                      DateTime.parse(
                                        activity['Activity_start_datetime'],
                                      ).toLocal();
                                } catch (e) {
                                  startDate = null;
                                }

                                //tas convert na yung date into string
                                String dateString =
                                    startDate != null
                                        ? DateFormat(
                                          'MMMM d, yyyy • h:mm a',
                                        ).format(startDate)
                                        : "No date available";

                                return ViewRSOActivityCard(
                                  imageUrl: activity['Activity_image'],
                                  name: activity['Activity_name'],
                                  date: dateString,
                                  description: activity["Activity_description"],
                                  publicity: activity['Activity_publicity'],
                                  status: activity['Activity_date_status'],
                                  onTap: () {
                                    print(
                                      "Printing activity ID: ${activity["_id"]}",
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
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (rsoDetails?['RSO_membershipStatus'] == true &&
                      isCurrentMember == false) ...[
                    Positioned(
                      bottom: 30.h,
                      left: 20.w,
                      right: 20.w,
                      child: SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Register Membership",
                          fontSize: 14.r,
                          fontweight: FontWeight.bold,
                          onPressed: () {
                            print("Registering membership");
                            Navigator.of(context).pushNamed(
                              '/membershipForms',
                              arguments: {'rsoId': widget.rsoId},
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
    );
  }
}
