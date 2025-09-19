import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/config/config.dart';
import 'package:nuspace_app/widgets/custombutton.dart';
import 'package:nuspace_app/widgets/customdropdown.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import 'package:nuspace_app/widgets/snackbarhelper.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart';
import '../../services/connectivity_service.dart';
import '../../utils/internalserverdialog.dart';
import '../../widgets/customtextformfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errormessage, selectedCollege;

  late ConnectivityService connectivityService;

  final List<Map<String, dynamic>> collegesWithIcons = [
    {"label": "CCIT", "icon": Icons.computer},
    {"label": "CBA", "icon": Icons.business},
    {"label": "COA", "icon": Icons.account_balance},
    {"label": "COE", "icon": Icons.engineering},
    {"label": "CAH", "icon": Icons.medical_services},
    {"label": "CEAS", "icon": Icons.school},
    {"label": "CTHM", "icon": Icons.travel_explore},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
  }

  Future<void> _createAccount() async {
    if (_isLoading) return;
    if (!connectivityService.isConnected) {
      print('No Internet Connection');
      SnackbarHelper.showConnectivityStatus(connectivityService.isConnected);
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
              Uri.parse(
                '${AppConfig.baseUrl}/api/student/user/createStudentAccount',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                "firstName": _firstNameController.text.trim(),
                "lastName": _lastNameController.text.trim(),
                "email": _emailController.text.trim(),
                "password": _passwordController.text.trim(),
                "confirmpassword": _confirmPasswordController.text.trim(),
                "college": selectedCollege?.trim() ?? "",
              }),
            )
            .timeout(Duration(seconds: 20));

        final responseData = jsonDecode(response.body);
        print('Response data: $responseData');

        if (response.statusCode == 200 && responseData['success'] == true) {
          //if successful registration then proceed to email verification
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/emailVerificationScreen',
            (route) => false,
            arguments: responseData['email'],
          );
          SnackbarHelper.showSnackbar(
            "Registered Succesfully!",
            backgroundColor: Colors.green,
          );
        } else {
          String errorMessage = "";

          if (responseData.containsKey("errors")) {
            // Validation errors array
            List<dynamic> errors = responseData["errors"];
            errorMessage = errors.map((e) => "${e['msg']}").join("\n");
          } else if (responseData.containsKey("message")) {
            // Single message (like email already registered)
            errorMessage = responseData["message"];
          } else {
            // Fallback for unknown error
            errorMessage = "An unexpected error occurred.";
          }

          setState(() {
            _errormessage = errorMessage;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: whitetheme,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          centerTitle: true,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () async {
              FocusScope.of(context).unfocus(); // First dismiss keyboard
              await Future.delayed(
                const Duration(milliseconds: 300),
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
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Center(
                    child: CustomFont(
                      text: "Create an account",
                      fontSize: 24.r,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  CustomTextFormField(
                    labelText: "First Name",
                    hintText: "Ex. Juan",
                    controller: _firstNameController,
                    height: 10.r,
                    width: 20.r,
                    prefixIcon: Icons.person,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your first name";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),
                  CustomTextFormField(
                    labelText: "Last Name",
                    hintText: "Ex. Dela Cruz",
                    controller: _lastNameController,
                    height: 10.r,
                    width: 20.r,
                    prefixIcon: Icons.person,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your last name";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),
                  CustomTextFormField(
                    labelText: "NU Email",
                    hintText: "@students.national-u.edu.ph",
                    controller: _emailController,
                    height: 10.r,
                    width: 20.r,
                    prefixIcon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your NU email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),
                  CustomTextFormField(
                    labelText: "Password",
                    hintText: "Enter your password",
                    controller: _passwordController,
                    height: 10.r,
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
                  SizedBox(height: 20.h),
                  CustomTextFormField(
                    labelText: "Confirm Password",
                    hintText: "Enter your password",
                    controller: _confirmPasswordController,
                    height: 10.r,
                    width: 20.r,
                    isPassword: true,
                    prefixIcon: Icons.lock,
                    keyboardType: TextInputType.visiblePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      }
                      if (value.trim() != _passwordController.text.trim()) {
                        return "Your passwords do not match";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  CustomDropDownMenu(
                    labelText: "Select College",
                    options: collegesWithIcons,
                    selectedValue: selectedCollege,
                    onChanged: (value) {
                      setState(() {
                        selectedCollege = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select college";
                      }
                      return null;
                    },
                    prefixIcon: Icons.school,
                  ),
                  SizedBox(height: 25.h),
                  if (_errormessage != null)
                    CustomFont(
                      text: _errormessage!,
                      fontSize: 14.r,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  SizedBox(height: 25.h),
                  CustomButton(
                    text: "Create Account",
                    height: 45.h,
                    fontSize: 14.r,
                    fontweight: FontWeight.bold,
                    isLoading: _isLoading,
                    onPressed: () {
                      _createAccount();
                    },
                  ),
                  SizedBox(height: 25.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
