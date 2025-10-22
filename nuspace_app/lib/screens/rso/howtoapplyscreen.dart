import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class HowToApplyScreen extends StatefulWidget {
  const HowToApplyScreen({super.key});

  @override
  State<HowToApplyScreen> createState() => _HowToApplyScreenState();
}

class _HowToApplyScreenState extends State<HowToApplyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whitetheme,
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        title: CustomFont(
          text: "RSO Application Guide",
          fontSize: 20.r,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: whitetheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "How to Apply for RSO Recognition",
              content:
                  "The University encourages its student organizations to continue their activities geared toward social, cultural, moral, literacy, and recreational aspects of student development. \n"
                  "The renewal of recognition of student clubs and organizations is also reflected in Section VI of the latest Student Handbook of National University. "
                  "Below are the guidelines on how to be recognized this Academic Year.",
            ),
            _buildSection(
              title: "1. Requirements",
              content:
                  "1. Letter of application addressed to the Director of the Student Development and Activities Office, Mr. Marc Rey D. Galido, and the Coordinator of Student Development and Activities Office, Ms. Ma. Avon N. Nario.\n\n"
                  "   • For co-curricular organizations: signed by the president and adviser of the organization, and endorsed by the college dean and/or program chair.\n"
                  "   • For special interest organizations: signed by the president and noted by the adviser.\n\n"
                  "2. A copy of the Constitution and By-Laws of the organization in accordance with the Mission and Vision of the University and the 2016 Student Constitution of National University.\n\n"
                  "3. A proposal for organization Membership Fee with liquidation. The organization may charge a maximum of Php 100.00 per member for the annual membership fee.\n\n"
                  "4. Organizational Chart and updated roster of officers/founders with the following information:\n"
                  "   • Position\n"
                  "   • Program, Year\n"
                  "   • Email address\n"
                  "   • Mobile number / Telephone number\n"
                  "   • Emergency contact name, address, and number\n"
                  "   • Faculty adviser’s name, college, and department\n\n"
                  "5. List of Members — at least 10 members (excluding officers).\n\n"
                  "6. For co-curricular organizations: a letter from the College Dean endorsing the faculty adviser (must be a full-time faculty).\n\n"
                  "7. General Plan of Action (GPOA): list of proposed projects or activities for the upcoming school year with timetable and estimated budget per project/activity.\n\n"
                  "8. Accomplishment Report of the organization for the previous academic year.",
            ),
            _buildSection(
              title: "2. Submission",
              content:
                  "All requirements must be submitted to the Student Development and Activities Office (SDAO) in Web Application.",
            ),
            _buildSection(
              title: "3. Review and Notification",
              content:
                  "The SDAO will review the application and notify the organization regarding the application status.",
            ),
            _buildSection(
              title: "Inquiries",
              content:
                  "For questions or concerns, feel free to email: mannario@national-u.edu.ph\n\nThank you and stay safe!",
            ),
          ],
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
            height: 1.5,
          ),
        ],
      ),
    );
  }
}
