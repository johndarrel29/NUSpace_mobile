import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/services/api_service.dart';
import 'package:nuspace_app/widgets/custom_interestchip.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/custombutton.dart';
import '../../widgets/snackbarhelper.dart';

class InterestScreen extends StatefulWidget {
  const InterestScreen({super.key});

  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> {
  final storage = FlutterSecureStorage();
  List<String> selectedInterests = []; //to store selected tag IDs
  List<Map<String, String>> allTags = [];
  bool _isLoading = false;
  String? _errormessage;

  int limit = 25;
  int page = 1;
  bool hasNextPage = true;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    fetchTagsChoices();
  }

  void _toggleInterests(String tag) {
    setState(() {
      if (selectedInterests.contains(tag)) {
        selectedInterests.remove(tag);
      } else {
        if (selectedInterests.length >= 5) {
          SnackbarHelper.showSnackbar(
            "You can only select up to 5 interests.",
            backgroundColor: Colors.red,
          );
          return;
        }
        selectedInterests.add(tag);
        print("selected interests: $selectedInterests");
      }
    });
  }

  Future<void> fetchTagsChoices({bool loadMore = false}) async {
    setState(() {
      _errormessage = null;
    });

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .get(
              Uri.parse(
                '${AppConfig.baseUrl}/api/tags/tagsChoices?page=$page&limit=$limit',
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
      print("Response data: $responseData");
      if (response.statusCode == 200 && responseData['success'] == true) {
        final newTags = List<Map<String, String>>.from(
          responseData['tags'].map(
            (tag) => {
              'label': tag['label'].toString(),
              'value': tag['value'].toString(),
            },
          ),
        );

        if (mounted) {
          setState(() {
            if (loadMore) {
              allTags.addAll(newTags);
            } else {
              allTags = newTags;
            }

            hasNextPage = responseData['pagination']?['hasNextPage'] ?? false;
          });
          _isLoading = false;
        }
      } else {
        print(
          "error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          allTags = [];
          _errormessage = responseData['message'];
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitTags() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .patch(
              Uri.parse('${AppConfig.baseUrl}/api/student/user/addInterests'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': accessToken,
              },
              body: jsonEncode({"interests": selectedInterests}),
            )
            .timeout(Duration(seconds: 20));
      }, context: mounted ? context : null);

      if (response == null) return; //session expired

      final responseData = jsonDecode(response.body);
      print("Response data for interests: $responseData");

      if (response.statusCode == 200 && responseData['success'] == true) {
        print("Interests added successfully");

        SnackbarHelper.showSnackbar(
          "Interests added!",
          backgroundColor: Colors.green,
        );

        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/mainScreen', (route) => false);
        }
      } else {
        print("Error adding interests: ${responseData['message']}");

        SnackbarHelper.showSnackbar(
          responseData['message'],
          backgroundColor: Colors.red,
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whitetheme,
      appBar: AppBar(
        centerTitle: true,
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
          TextButton(
            //change textbutton style
            onPressed: selectedInterests.length >= 5 ? _submitTags : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomFont(
                  text: "Continue",
                  fontSize: 14.r,
                  color: selectedInterests.length >= 5 ? nuBlue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                if (_isLoading)
                  Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: SizedBox(
                      width: 10.r,
                      height: 10.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: nuBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body:
          allTags.isEmpty
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
                          _errormessage == null
                              ? "No interests choices available at the moment"
                              : _errormessage!,
                      fontSize: 16.r,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              )
              : Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Center(
                      child: CustomFont(
                        text: "Choose your interests",
                        fontSize: 24.r,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 40.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomFont(
                          text: "Interests:",
                          fontSize: 16.r,
                          fontWeight: FontWeight.w500,
                        ),
                        SizedBox(width: 3.w),
                        //display the number of chosen interests
                        CustomFont(
                          text: "${selectedInterests.length} / 5",
                          fontSize: 16.r,
                          fontWeight: FontWeight.bold,
                          color:
                              selectedInterests.length >= 5
                                  ? Colors.red
                                  : Colors.black,
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.manual,
                        child: Column(
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8.r,
                              runSpacing: 8.r,
                              children:
                                  allTags.map((tag) {
                                    final tagLabel = tag['label']!;
                                    final bool isSelected = selectedInterests
                                        .contains(tagLabel);
                                    final bool isDisabled =
                                        selectedInterests.length >= 5 &&
                                        !isSelected;

                                    return InterestChip(
                                      label: tag['label']!,
                                      isSelected: isSelected,
                                      isDisabled: isDisabled,
                                      onTap: () => _toggleInterests(tagLabel),
                                    );
                                  }).toList(),
                            ),
                            // Pagination button
                            if (hasNextPage)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: CustomButton(
                                  text: "See more",
                                  fontSize: 16.r,
                                  fontweight: FontWeight.bold,
                                  onPressed: () {
                                    setState(() => page += 1);
                                    fetchTagsChoices(loadMore: true);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
