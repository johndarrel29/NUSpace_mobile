import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';

// ignore: must_be_immutable
class CustomTextFormField extends StatefulWidget {
  final String hintText;
  final String? labelText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword, isMultiline;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final TextInputAction textInputAction;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final Color fillColor;
  final Color fontColor;
  int maxLength, maxLine;
  final double hintTextSize;
  final double height, width, floatingLabelSize;

  CustomTextFormField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.controller,
    required this.height, //minimum height ay 10 & width
    required this.width,
    this.validator,
    this.keyboardType =
        TextInputType.text, //nacocostumize yung keyboard depende sa need
    this.isPassword = false, //kapag yung need is for password
    this.isMultiline = false,
    this.prefixIcon,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.focusNode,
    this.fillColor = Colors.white,
    this.fontColor = Colors.black,
    this.fontSize = 16.0,
    this.padding,
    this.hintTextSize = 16.0,
    this.maxLength = 200,
    this.floatingLabelSize = 18.0,
    this.maxLine = 5,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _isObsure = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.all(0),
      child: TextFormField(
        controller: widget.controller,
        keyboardType:
            widget.isMultiline ? TextInputType.multiline : widget.keyboardType,
        obscureText: widget.isPassword ? _isObsure : false,
        textInputAction:
            widget.isMultiline
                ? TextInputAction.newline
                : widget.textInputAction,
        validator: (value) {
          if (widget.validator != null) {
            final errorText = widget.validator!(value);
            setState(() {
              _hasError = errorText != null;
            });
            return errorText;
          }
          return null;
        },
        onChanged: widget.onChanged,
        focusNode: widget.focusNode,
        inputFormatters: [LengthLimitingTextInputFormatter(widget.maxLength)],
        maxLines: widget.isMultiline ? widget.maxLine : 1,
        expands: false,
        style: TextStyle(fontSize: widget.fontSize.r, color: widget.fontColor),
        decoration: InputDecoration(
          contentPadding:
              widget.isMultiline
                  ? EdgeInsets.all(20.r)
                  : EdgeInsets.fromLTRB(
                    widget.width,
                    widget.height,
                    widget.width,
                    widget.height,
                  ),
          filled: true,
          fillColor: widget.fillColor,
          labelText: widget.labelText,
          labelStyle: TextStyle(
            fontSize: widget.fontSize.r,
            color: _hasError ? Colors.red.shade300 : Colors.grey.shade600,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: widget.floatingLabelSize.r,
            color: _hasError ? Colors.red.shade300 : nuBlue,
            fontWeight: FontWeight.bold,
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: widget.hintTextSize.r,
            color: Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: const Color(0x9C8B8B8B),
              width: 1.5.sp,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            //outline border for unfocus
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: const Color(0xFF8B8B8B),
              width: 1.5.sp,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: nuBlue, // Highlight color when focused
              width: 2.sp, // Thicker border when focused
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: Colors.red.shade400, // Error state border color
              width: 1.5.sp,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(
              color: Colors.red.shade900, // Error color when focused
              width: 2.sp,
            ),
          ),
          prefixIcon:
              widget.prefixIcon != null
                  ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Icon(
                      widget.prefixIcon,
                      color: _hasError ? Colors.red.shade900 : nuBlue,
                      size: 24.r,
                    ),
                  )
                  : null,
          suffixIcon:
              widget.isPassword
                  ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: IconButton(
                      icon: Icon(
                        _isObsure ? Icons.visibility_off : Icons.visibility,
                        color: _hasError ? Colors.red.shade900 : nuBlue,
                        size: 24.r,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObsure = !_isObsure;
                        });
                      },
                    ),
                  )
                  : null,
        ),
      ),
    );
  }
}
