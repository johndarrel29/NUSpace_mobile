import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/services/api_service.dart';
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
  List<dynamic> _activities = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool isCurrentMember = false;

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
    _fetchRSODetails();
    _fetchRSOActivities();
  }

  //remove activities from the endpoint
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
                          title: CustomFont(
                            text:
                                rsoDetails?['RSO_snapshot']?['acronym'] ??
                                "RSO Acronym",
                            fontSize: 18.r,
                            fontWeight: FontWeight.w600,
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 5.h),
                            child: CustomFont(
                              text:
                                  rsoDetails?['RSO_snapshot']?['name'] ??
                                  "RSO Name",
                              fontSize: 16.r,
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
                          fontSize: 16,
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
                                        text: "Description",
                                        fontSize: 16.r,
                                        textAlign: TextAlign.justify,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: CustomFont(
                                        text:
                                            rsoDetails?['RSO_snapshot']?['description'] ??
                                            "RSO Description",
                                        fontSize: 16.r,
                                        textAlign: TextAlign.justify,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: CustomFont(
                                        text: "Officers",
                                        fontSize: 16.r,
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
                                    SizedBox(height: 100.h),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else
                          Expanded(child: _rsoActivities()),
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
                            if (!connectivityService.isConnected) {
                              print("No Internet Connection");
                              SnackbarHelper.showConnectivityStatus(false);
                              return;
                            }
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
            if (!connectivityService.isConnected) {
              print("No Internet Connection");
              SnackbarHelper.showConnectivityStatus(false);
              return;
            }
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
