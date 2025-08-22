import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/customfont.dart';
import '../../widgets/snackbarhelper.dart';

class RSOAnnouncementScreen extends StatefulWidget {
  final String? rsoId;
  const RSOAnnouncementScreen({super.key, required this.rsoId});

  @override
  State<RSOAnnouncementScreen> createState() => _RSOAnnouncementScreenState();
}

class _RSOAnnouncementScreenState extends State<RSOAnnouncementScreen> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? announcementResponse;
  List<dynamic> _announcements = [];
  bool _isLoading = true;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    print("View announcement screen rsoId: ${widget.rsoId}");
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
              '${AppConfig.baseUrl}/api/student/announcements/getStudentAnnouncement/${widget.rsoId}',
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
            final data = responseData['announcement'];
            final List<dynamic> announcementList = data['announcement'] ?? [];
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
              : ListView.builder(
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final announcement = _announcements[index];

                  String formattedDate = '';
                  final dateStr = announcement['createdAt'] ?? '';
                  final parsed = DateTime.tryParse(dateStr);
                  if (parsed != null) {
                    final local = parsed.toLocal();

                    final datePart =
                        "${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}";

                    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
                    final minute = local.minute.toString().padLeft(2, '0');
                    final second = local.second.toString().padLeft(2, '0');
                    final period = local.hour >= 12 ? "PM" : "AM";

                    final timePart = "$hour:$minute:$second $period";

                    formattedDate = "$datePart | $timePart";
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: SingleChildScrollView(
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
                    ),
                  );
                },
              ),
    );
  }
}
