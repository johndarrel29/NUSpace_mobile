import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants.dart';
import '../../widgets/customfont.dart';

class TermsAndConditionScreen extends StatefulWidget {
  const TermsAndConditionScreen({super.key});

  @override
  State<TermsAndConditionScreen> createState() =>
      _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whitetheme,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
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
        title: CustomFont(
          text: "Terms and Conditions",
          fontSize: 18.r,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomFont(
                text: "Welcome to NU Space!",
                fontSize: 16.r,
                fontWeight: FontWeight.w600,
              ),
              SizedBox(height: 10.h),
              CustomFont(
                text:
                    "Before using the app, please read and understand the following terms and conditions.",
                fontSize: 14.r,
                fontWeight: FontWeight.normal,
              ),
              SizedBox(height: 20.h),

              // 1. Accuracy of Information
              _buildSection(
                title: "1. Accuracy of Information",
                content:
                    "Make sure that all the information you provide is true, correct, and complete. Once submitted, your details cannot be changed within the app. ",
              ),

              // 2. Form Submissions
              _buildSection(
                title: "2. Form Submissions",
                content:
                    "Each student is allowed to submit only one (1) response for the following forms:\n\n• Membership application\n• Pre-activity registration\n• Activity feedback\n\nMultiple or duplicate submissions will not be accepted. Please review your responses carefully before submitting.",
              ),

              // 3. Account Usage
              _buildSection(
                title: "3. Account Usage",
                content:
                    "Your NU Space account is for personal use only. Do not share your login credentials with anyone. You are responsible for all activities done under your account. If you suspect unauthorized access, report it immediately to the NU Space support team or Student Development and Activities Office (SDAO).",
              ),

              // 4. Respectful Conduct
              _buildSection(
                title: "4. Respectful Conduct",
                content:
                    "Users are expected to use NU Space responsibly and respectfully. Do not upload or submit content that is inappropriate, misleading, or offensive. Any misuse of the platform may result in account suspension or disciplinary action.",
              ),

              // 5. Data Privacy
              _buildSection(
                title: "5. Data Privacy",
                content:
                    "By using NU Space, you agree that your information may be collected and used by SDAO and the University for official purposes such as organization management, activity tracking, and analytics. All data will be handled confidentially and securely.",
              ),

              // 6. Agreement
              _buildSection(
                title: "6. Agreement",
                content:
                    "By creating an account to use NU Space, you confirm that you have read, understood, and agreed to these Terms and Conditions.",
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFont(text: title, fontSize: 16.r, fontWeight: FontWeight.w600),
          SizedBox(height: 8.h),
          CustomFont(
            text: content,
            fontSize: 14.r,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}
