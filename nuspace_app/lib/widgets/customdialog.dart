import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart'; // adjust import as needed

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50.r),
            SizedBox(height: 15.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 20.r,
                fontWeight: FontWeight.bold,
                color: nuBlue,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            Text(
              message,
              style: TextStyle(fontSize: 14.r),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: nuBlue,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  "Close",
                  style: TextStyle(fontSize: 16.r, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
