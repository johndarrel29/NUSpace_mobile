import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class InternalServerDialog extends StatelessWidget {
  const InternalServerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CustomFont(
        text: "Server Timeout!",
        fontSize: 24.r,
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),
      content: CustomFont(
        text:
            "The server is taking too long to respond. Please try again later.",
        fontSize: 16.r,
        color: Colors.red,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: CustomFont(text: "OK", fontSize: 14.r, color: Colors.red),
        ),
      ],
    );
  }
}
