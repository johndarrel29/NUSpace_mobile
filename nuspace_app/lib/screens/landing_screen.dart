import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/services/connectivity_service.dart';
import 'package:nuspace_app/services/notification_service.dart';
import 'package:nuspace_app/widgets/custombutton.dart';
import 'package:nuspace_app/widgets/customfont.dart';
import 'package:nuspace_app/widgets/snackbarhelper.dart';
import 'package:provider/provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool isLoading = true;
  bool isConnected = true;
  bool _navigateLogin = false;
  bool _navigateRegister = false;
  late ConnectivityService connectivityService;

  @override
  void initState() {
    super.initState();
    connectivityService = Provider.of<ConnectivityService>(
      context,
      listen: false,
    );
    NotificationService.requestPermission();
    NotificationService.initializeFCMListerners();
  }

  Future<void> _toLogin() async {
    if (_navigateLogin) return;

    setState(() {
      _navigateLogin = true;
    });

    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(connectivityService.isConnected);
      setState(() {
        _navigateLogin = false;
      });
      return;
    }

    try {
      if (mounted) {
        Navigator.of(context).pushNamed('/loginScreen');
      }

      print("Going to login");
      setState(() {
        _navigateLogin = false;
      });
    } catch (e, stackTrace) {
      print("An error has occured in navigating to Login Screen: $e");
      print("Stacktrace: $stackTrace");
    }
  }

  Future<void> _toRegistration() async {
    if (_navigateRegister) return;

    setState(() {
      _navigateRegister = true;
    });

    if (!connectivityService.isConnected) {
      print("No Internet Connection");
      SnackbarHelper.showConnectivityStatus(connectivityService.isConnected);
      setState(() {
        _navigateRegister = false;
      });
      return;
    }

    try {
      if (mounted) {
        Navigator.of(context).pushNamed('/registerAccountScreen');
      }

      print("Going to register");
      setState(() {
        _navigateRegister = false;
      });
    } catch (e, stackTrace) {
      print("An error has occured in navigating to Login Screen: $e");
      print("Stacktrace: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nuBlue,
      body: Column(
        children: [
          //blue top section
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              color: nuBlue,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 110.r,
                      width: 110.r,
                      child: Image.asset("assets/images/nuspace_whitelogo.png"),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomFont(
                          text: "NU",
                          fontSize: 60.r,
                          fontFamily: 'ClanOT',
                          fontWeight: FontWeight.bold,
                          useGoogleFont: false,
                          color: nuGold,
                        ),
                        CustomFont(
                          text: "Space",
                          fontSize: 60.r,
                          fontFamily: 'ClanOT',
                          fontWeight: FontWeight.bold,
                          useGoogleFont: false,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          //lower
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  CustomButton(
                    text: "Log in",
                    fontSize: 16.r,
                    fontweight: FontWeight.bold,
                    isLoading: _navigateLogin,
                    onPressed: _toLogin,
                  ),
                  SizedBox(
                    height: 20.h,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Divider(color: Colors.grey),
                    ),
                  ),

                  CustomButton(
                    text: "Sign up",
                    textColor: Colors.black,
                    fontSize: 16.r,
                    fontweight: FontWeight.bold,
                    backgroundColor: Colors.white,
                    borderColor: Colors.grey,
                    onPressed: _toRegistration,
                    isLoading: _navigateRegister,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
