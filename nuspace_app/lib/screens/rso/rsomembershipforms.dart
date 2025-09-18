import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/services/api_service.dart';
import 'package:nuspace_app/widgets/customform.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/customfont.dart';
import '../../widgets/snackbarhelper.dart';

class RSOMembershipForms extends StatefulWidget {
  final String? rsoId;
  const RSOMembershipForms({super.key, required this.rsoId});

  @override
  State<RSOMembershipForms> createState() => _RSOMembershipFormsState();
}

class _RSOMembershipFormsState extends State<RSOMembershipForms> {
  final storage = FlutterSecureStorage();
  Map<String, dynamic> membershipForm = {};
  bool _isLoading = true;
  String? formId, rsoYearlyDataID;
  bool? alreadySubmitted;
  bool _isSubmittingResponse = false;

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    _fetchMembershipForms();
  }

  Future<void> _fetchMembershipForms() async {
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
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await apiRequest((accessToken) {
        return http
            .get(
              Uri.parse(
                '${AppConfig.baseUrl}/api/student/forms/fetch-membership-forms/${widget.rsoId}',
              ),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': token,
              },
            )
            .timeout(Duration(seconds: 20));
      }, context: mounted ? context : null);

      if (response == null) return; //session expired

      final responseData = jsonDecode(response.body);
      print("printing raw response: $responseData");
      if (response.statusCode == 200 && responseData['success'] == true) {
        final form = responseData['form'] ?? {};
        final rsoData = responseData['rsoData'] ?? {};

        if (mounted) {
          setState(() {
            membershipForm = form;
            formId = form['_id'];
            rsoYearlyDataID = rsoData['_id'];
            _isLoading = false;
            alreadySubmitted = responseData['alreadySubmitted'];
          });
        }
        print("already submitted: $alreadySubmitted");
        print("Printing membership form: $membershipForm");
        print("Form ID: $formId");
        print("RSO Yearly Data ID: $rsoYearlyDataID");
      } else {
        print(
          "Error code ${response.statusCode} and message ${responseData['message']}",
        );
        setState(() {
          membershipForm = {};
        });
        print("Printing rso details failed: $membershipForm");
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

  Future<void> _submitResponse(Map<String, dynamic> answers) async {
    if (_isSubmittingResponse) {
      print("Already submitting, ignoring duplicate call");
      return;
    }
    setState(() => _isSubmittingResponse = true);
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

    if (formId == null || rsoYearlyDataID == null) {
      SnackbarHelper.showSnackbar(
        "Form data missing. Please refresh and try again.",
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      final uri = Uri.parse(
        "${AppConfig.baseUrl}/api/student/forms/membership-forms/submit",
      );
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = token;

      // Attach non-file fields
      request.fields['formId'] = formId!;
      request.fields['rsoYearlyDataID'] = rsoYearlyDataID!;

      // Traverse nested answers to attach files
      for (final page in answers['pages']) {
        for (final element in page['elements']) {
          final answer = element['answer'];
          final name = element['name'] ?? 'file';

          if (answer is String && File(answer).existsSync()) {
            final mimeType =
                lookupMimeType(answer) ?? 'application/octet-stream';
            final typeParts = mimeType.split('/');

            request.files.add(
              await http.MultipartFile.fromPath(
                name,
                answer,
                contentType: MediaType(typeParts[0], typeParts[1]),
              ),
            );

            // Mark that backend should replace with GCS path
            element['answer'] = null;
          }
        }
      }

      request.fields['answers'] = jsonEncode(answers);

      debugPrint("Printing requests ${request.fields}");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decodedBody = jsonDecode(responseBody);

      print("Response body $responseBody");

      if (response.statusCode == 200 && decodedBody['success'] == true) {
        SnackbarHelper.showSnackbar(
          "Submitted successfully!",
          backgroundColor: Colors.green,
        );

        Navigator.of(context).pop();
      } else {
        final errorMessage = decodedBody['message'];
        SnackbarHelper.showSnackbar(errorMessage, backgroundColor: Colors.red);
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
        setState(() => _isSubmittingResponse = false);
      } else {
        _isSubmittingResponse = false;
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
              : membershipForm.isEmpty
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
                      text: "No forms found",
                      fontSize: 16.r,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ],
                ),
              )
              : alreadySubmitted == true
              ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 60.r),
                      SizedBox(height: 16.h),
                      CustomFont(
                        text: "Form Submitted",
                        fontSize: 20.r,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 10.h),
                      CustomFont(
                        text: "You've already submitted this membership form.",
                        fontSize: 16.r,
                        color: Colors.grey.shade700,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
              : CustomForm(
                formJSON: membershipForm,
                isSubmitting: _isSubmittingResponse,
                onSubmit: (responses) async {
                  print("Raw response: $responses");
                  await _submitResponse(responses);
                  responses.forEach((key, value) {
                    print("$key : $value");
                  });
                },
              ),
    );
  }
}
