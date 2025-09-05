import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/widgets/custombutton.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import 'package:http/http.dart' as http;
import 'package:nuspace_app/widgets/customtextformfield.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/snackbarhelper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? email;
  const ForgotPasswordScreen({super.key, required this.email});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errormessage;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    print("Email checked: ${widget.email}");
    if (_isLoading) return;

    //check for internet connection
    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(false);
      setState(() => _isLoading = false);
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _errormessage = null;
        _isLoading = true;
      });

      try {
        final response = await http
            .post(
              Uri.parse('${AppConfig.baseUrl}/api/auth/reset-password'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "email": widget.email,
                "newPassword": _passwordController.text.trim(),
                "confirmPassword": _confirmPasswordController.text.trim(),
                "platform": "mobile",
              }),
            )
            .timeout(Duration(seconds: 20));

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200 && responseData['success'] == true) {
          print("Password has been reset successfully");

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
            responseData['message'],
            backgroundColor: Colors.green,
          );
        } else {
          print(
            "error in finding email: ${responseData['message']} and Errors: ${responseData['error']}",
          );
          setState(() {
            _errormessage = responseData['message'] ?? 'Internal Server Error';
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
          setState(() {
            _isLoading = false;
          });
        }
      }
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
          scrolledUnderElevation: 0,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 15.h),
                Center(
                  child: CustomFont(
                    text: "Reset Your Password",
                    fontSize: 24.r,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                CustomFont(
                  text: "Enter your new password.",
                  fontSize: 14.r,
                  fontWeight: FontWeight.w500,
                ),
                SizedBox(height: 20.h),
                CustomTextFormField(
                  labelText: "New Password",
                  hintText: "Enter your new password",
                  controller: _passwordController,
                  height: 10.h,
                  width: 20.w,
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.h),
                CustomTextFormField(
                  labelText: "Confirm Password",
                  hintText: "Enter your confirm password",
                  controller: _confirmPasswordController,
                  height: 10.h,
                  width: 20.w,
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your confirm password";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
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
                  text: "Submit",
                  height: 40.h,
                  fontSize: 14.r,
                  fontweight: FontWeight.bold,
                  isLoading: _isLoading,
                  onPressed: _changePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
