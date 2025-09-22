import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/custom_code_input_field.dart';
import 'package:nuspace_app/widgets/custombutton.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/snackbarhelper.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;

  late ConnectivityService connectivityService;

  static const int cooldownSeconds = 120;
  late Timer _timer;
  int _remainingSeconds = cooldownSeconds;

  bool get isCooldownActive => _remainingSeconds > 0;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldownTimer() {
    _remainingSeconds = cooldownSeconds;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  //format cooldown timer5
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _resendEmailCode() async {
    setState(() => _isResending = true);
    try {
      await _resendCode();
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _resendCode() async {
    print("Printing email: ${widget.email}");

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      return;
    }

    if (widget.email == null) {
      print("No email found, ${widget.email}");
      SnackbarHelper.showSnackbar(
        "Email not found!",
        backgroundColor: Colors.red,
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/auth/send-email-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"email": widget.email}),
          )
          .timeout(Duration(seconds: 20));

      final responseData = jsonDecode(response.body);
      print("Response data: $responseData");

      if (response.statusCode == 200 && responseData['success'] == true) {
        print("Email verification code sent successfully");
        _startCooldownTimer();
      } else {
        print("Failed to send verification code: ${responseData['message']}");
        SnackbarHelper.showSnackbar(
          "Please wait before requesting a new code",
          backgroundColor: Colors.red,
        );
      }
    } on TimeoutException {
      print("Server Timeout! Navigating to Internal Sever Error Screen.");
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const InternalServerDialog(),
        );
      }
    } catch (e, stackTrace) {
      print("Error sending email code: $e");
      print("Email stacktrace: $stackTrace");
      SnackbarHelper.showSnackbar(
        "Something went wrong. Please try again.",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _submitCode() async {
    print("Email: ${widget.email}");
    //submit code
    if (_isLoading) return;

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      setState(() => _isLoading = false);
      return;
    }

    if (widget.email == null) {
      print("User not found, ${widget.email}");
      SnackbarHelper.showSnackbar(
        "Email not found!",
        backgroundColor: Colors.red,
      );
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final code = _codeController.text.trim();
        print("Code type by user: $code");

        if (code.length == 6) {
          final response = await http
              .post(
                Uri.parse('${AppConfig.baseUrl}/api/auth/verify-email-code'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({"email": widget.email, "code": code}),
              )
              .timeout(Duration(seconds: 20));

          final responseData = jsonDecode(response.body);
          print("Response data: $responseData");
          if (response.statusCode == 200 && responseData['success'] == true) {
            print("Email verification: ${responseData['message']}");

            if (mounted) {
              FocusScope.of(context).unfocus(); // Dismiss keyboard
              await Future.delayed(
                const Duration(milliseconds: 300),
              ); // Let keyboard close
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/landingScreen', (route) => false);
              }
            }

            SnackbarHelper.showSnackbar(
              responseData['message'] ?? "Email verified successfully!",
              backgroundColor: Colors.green,
            );
          } else {
            print("reponse message: ${responseData['message']}");
            SnackbarHelper.showSnackbar(
              "${responseData['message']}",
              backgroundColor: Colors.red,
            );
          }
        } else {
          print("Invalid code");
          SnackbarHelper.showSnackbar(
            "Invalid Code!",
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
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: whitetheme,
        appBar: AppBar(
          centerTitle: true,
          automaticallyImplyLeading: false,
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
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 15.h),
                CustomFont(
                  text: "Email Verification Code",
                  fontSize: 24.r,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 10.h),
                CustomFont(
                  text:
                      "We just sent a verification code to your email. \nPlease check your email.",
                  fontSize: 14.r,
                  height: 1.2,
                ),

                SizedBox(height: 10.h),

                SizedBox(
                  height: 60.h,
                  //it needs to be inside the sized box
                  child: CustomCodeInputField(controller: _codeController),
                ),

                //submit button
                SizedBox(height: 10.h),
                CustomButton(
                  text: "Verify",
                  height: 45.h,
                  fontSize: 16.r,
                  fontweight: FontWeight.bold,
                  isLoading: _isLoading,
                  onPressed: () {
                    _submitCode();
                  },
                ),
                SizedBox(height: 15.h),

                //resend email with timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomFont(
                      text:
                          isCooldownActive
                              ? "Resend available in ${_formatTime(_remainingSeconds)}"
                              : "Didn't receive the code?",
                      fontSize: 14.r,
                    ),
                    if (!isCooldownActive)
                      InkWell(
                        onTap: _isResending ? null : _resendEmailCode,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomFont(
                              text: " Resend",
                              fontSize: 14.r,
                              fontWeight: FontWeight.w600,
                              color: _isResending ? Colors.grey : nuBlue,
                            ),
                            if (_isResending)
                              Padding(
                                padding: EdgeInsets.only(left: 6.w),
                                child: SizedBox(
                                  width: 12.r,
                                  height: 12.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
