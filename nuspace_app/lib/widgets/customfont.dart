import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class CustomFont extends StatelessWidget {
  const CustomFont({
    super.key,
    required this.text,
    required this.fontSize,
    this.color = Colors.black,
    this.letterSpacing = 0,
    this.fontFamily = 'Inter',
    this.fontStyle = FontStyle.normal,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.useGoogleFont = true,
    this.height = 1,
  });

  final String text;
  final double fontSize, letterSpacing, height;
  final int? maxLines;
  final TextOverflow overflow;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final String fontFamily;
  final FontStyle fontStyle;
  final bool useGoogleFont;

  @override
  Widget build(BuildContext context) {
    final style =
        useGoogleFont
            ? GoogleFonts.getFont(
              fontFamily,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              fontStyle: fontStyle,
              color: color,
              height: height,
            )
            : TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: letterSpacing,
              fontStyle: fontStyle,
              color: color,
              height: height,
            );

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }
}
