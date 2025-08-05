// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final double? height, width;
  final VoidCallback? onPressed;
  final Color backgroundColor, textColor, splashColor;
  final Color? borderColor;
  final double fontSize, borderRadius, elevation, borderWidth;
  final bool isLoading;
  final FontWeight fontweight;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height,
    this.width,
    this.backgroundColor = nuBlue,
    this.textColor = Colors.white,
    this.fontSize = 12,
    this.isLoading = false,
    this.fontweight = FontWeight.normal,
    this.borderRadius = 50,
    this.elevation = 2,
    this.splashColor = nuGold,
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius.r),
        elevation: elevation,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius.r),
            border:
                borderColor != null
                    ? Border.all(color: borderColor!, width: borderWidth)
                    : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius.r),
            splashColor: splashColor,
            onTap: isLoading ? null : onPressed,
            child: Center(
              child:
                  isLoading
                      ? CircularProgressIndicator(
                        color: textColor,
                        strokeWidth: 4,
                      )
                      : CustomFont(
                        text: text,
                        fontSize: fontSize.r,
                        fontWeight: fontweight,
                        color: textColor,
                        useGoogleFont: true,
                        fontFamily: 'Inter',
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
