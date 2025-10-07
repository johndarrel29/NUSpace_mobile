import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/services/connectivity_service.dart';
import 'package:nuspace_app/widgets/custombutton.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import 'package:nuspace_app/widgets/customtextformfield.dart';
import 'package:nuspace_app/widgets/snackbarhelper.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../utils/internalserverdialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errormessage;

  final storage = FlutterSecureStorage();

  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      setState(() => _isLoading = false);
      return;
    }

    //validates all the form fields
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errormessage = null;
      });

      try {
        await FirebaseMessaging.instance.requestPermission();

        String? fcmToken;

        // Wait for APNS token on iOS before getting FCM token
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          String? apnsToken;
          int retries = 0;
          while (apnsToken == null && retries < 10) {
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            if (apnsToken == null) {
              await Future.delayed(const Duration(seconds: 1));
              retries++;
            }
          }
          print('APNS Token: $apnsToken');

          //only get fcm token if APNS token is available
          if (apnsToken != null) {
            fcmToken = await FirebaseMessaging.instance.getToken();
            print('FCM Token: $fcmToken');
          } else {
            print('APNS token not available, skipping FCM token');
            // You can still proceed with login without FCM token
            fcmToken = "temporary token not available";
          }
        } else {
          //android get fcm token directly
          fcmToken = await FirebaseMessaging.instance.getToken();
        }

        if (fcmToken != null) {
          await storage.write(key: "device_token", value: fcmToken);
        }

        final response = await http
            .post(
              Uri.parse('${AppConfig.baseUrl}/api/login/mobileLogin'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "email": _emailController.text.trim(),
                "password": _passwordController.text.trim(),
                "platform": "mobile",
                "deviceToken": fcmToken,
              }),
            )
            .timeout(Duration(seconds: 20));

        final responseData = jsonDecode(response.body);
        print('response data $responseData');

        if (response.statusCode == 200 &&
            responseData['success'] == true &&
            response.headers['content-type']?.contains("application/json") ==
                true) {
          //store token
          String token = responseData['token'];
          await storage.write(key: "auth_token", value: token);
          print("Stored token: $token");

          //store refresh token
          String refreshToken = responseData['refreshToken'];
          await storage.write(key: "refresh_token", value: refreshToken);
          print("stored refresh token: $refreshToken");

          final userData = responseData['user'];
          print(
            "Printing user $userData and printing email only ${userData['email']}",
          );

          String userId = userData['id'];
          await storage.write(key: "user_id", value: userId);

          String userRole = userData['role'];
          await storage.write(key: "user_role", value: userRole);

          //check if the student_interest is not null
          bool hasInterests =
              userData['student_interests'] != null &&
              userData['student_interests'].isNotEmpty;

          SnackbarHelper.showSnackbar(
            "Login Successful!",
            backgroundColor: Colors.green,
          );

          if (mounted) {
            if (hasInterests) {
              await Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/mainScreen', (route) => false);
            } else {
              await Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/interestScreen', (route) => false);
            }
          }
        } else {
          print("Non-JSON response: ${response.body}");
          //if the response is not successful and have errors
          if (responseData['success'] == false &&
              responseData['requiresEmailVerification'] == true) {
            //send the email code
            await _sendEmailCode(responseData['email']);

            //navigate to email verification screen
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/emailVerificationScreen',
                (route) => false,
                arguments: responseData['email'],
              );
            }
          }

          setState(() {
            _errormessage = responseData['message'] ?? "Invalid Credentials";
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
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendEmailCode(String email) async {
    //logic
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/auth/send-email-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"email": email}),
          )
          .timeout(Duration(seconds: 20));

      final responseData = jsonDecode(response.body);
      print("Response data: $responseData");

      if (response.statusCode == 200 && responseData['success'] == true) {
        print("Email verification code sent successfully");
      } else {
        print("Failed to send verification code: ${responseData['message']}");
        SnackbarHelper.showSnackbar(
          "Please wait before request a new code",
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

  Future<void> _forgotPassword() async {
    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(connectivityService.isConnected);
      return;
    }

    try {
      if (mounted) {
        Navigator.of(context).pushNamed('/checkEmailScreen');
      }

      print("Going to checkemail first before change password");
    } catch (e, stackTrace) {
      print("An error has occured in navigating to check email screen: $e");
      print("Stacktrace: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            tooltip: 'Back',
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
              children: [
                Center(
                  child: CustomFont(
                    text: "Welcome Back!",
                    fontSize: 24.r,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
                CustomTextFormField(
                  labelText: "NU Email",
                  hintText: "@students.national-u.edu.ph",
                  controller: _emailController,
                  height: 20.r,
                  width: 20.r,
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your NU email";
                    }
                    final emailRegExp = RegExp(
                      r'^[a-zA-Z._-]+@students\.national-u\.edu\.ph$',
                    );

                    if (!emailRegExp.hasMatch(value)) {
                      return "Please enter a valid NU student email";
                    }

                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                CustomTextFormField(
                  labelText: "Password",
                  hintText: "Enter your password",
                  controller: _passwordController,
                  height: 20.r,
                  width: 20.r,
                  isPassword: true,
                  prefixIcon: Icons.lock,
                  keyboardType: TextInputType.visiblePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: _forgotPassword,
                  child: CustomFont(
                    text: "Forgot Password?",
                    fontSize: 16.r,
                    color: nuBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 25.h),
                if (_errormessage != null) ...[
                  CustomFont(
                    text: _errormessage!,
                    fontSize: 14.r,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 25.h),
                ],

                CustomButton(
                  text: "Log in",
                  fontSize: 16.r,
                  fontweight: FontWeight.bold,
                  height: 45.h,
                  isLoading: _isLoading,
                  onPressed: () {
                    Duration(milliseconds: 300);
                    _login();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
