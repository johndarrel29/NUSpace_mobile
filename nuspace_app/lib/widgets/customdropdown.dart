import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'customfont.dart';

class CustomDropDownMenu extends StatefulWidget {
  final String labelText;
  final List<Map<String, dynamic>> options;
  final String? selectedValue;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Color backgroundColor;
  final double fontSize;
  final double? width, height;
  final EdgeInsetsGeometry? padding;

  const CustomDropDownMenu({
    super.key,
    required this.labelText,
    required this.options,
    required this.onChanged,
    this.selectedValue,
    this.prefixIcon,
    this.backgroundColor = Colors.white,
    this.validator,
    this.fontSize = 14,
    this.height,
    this.width,
    this.padding,
  });

  @override
  State<CustomDropDownMenu> createState() => _CustomDropDownMenuState();
}

class _CustomDropDownMenuState extends State<CustomDropDownMenu> {
  String? selectedItem;

  @override
  void initState() {
    super.initState();

    if (widget.options.any(
      (option) => option["label"] == widget.selectedValue,
    )) {
      selectedItem = widget.selectedValue;
    } else {
      selectedItem = null;
    }
  }

  @override
  void didUpdateWidget(CustomDropDownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedValue != widget.selectedValue) {
      if (widget.options.any(
        (option) => option["label"] == widget.selectedValue,
      )) {
        setState(() {
          selectedItem = widget.selectedValue;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData selectedIcon =
        widget.options.firstWhere(
              (item) => item["label"] == selectedItem,
              orElse: () => {"icon": Icons.school},
            )["icon"]
            as IconData? ??
        Icons.school;

    return Padding(
      padding: widget.padding ?? EdgeInsets.all(0),
      child: FormField<String>(
        validator: widget.validator,
        builder: (FormFieldState<String> state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: widget.height ?? 60.r,
                width: widget.width ?? double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color:
                        state.hasError
                            ? Colors.red.shade400
                            : const Color(0x9C000000),
                    width: 1.5.sp,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: widget.backgroundColor,
                    value: selectedItem,
                    hint: Row(
                      children: [
                        Icon(
                          selectedItem != null ? selectedIcon : Icons.school,
                          color: state.hasError ? Colors.red.shade900 : nuBlue,
                        ),
                        SizedBox(width: 12),
                        CustomFont(
                          text: selectedItem ?? widget.labelText,
                          fontSize: widget.fontSize,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: 24.r,
                      color: state.hasError ? Colors.red.shade900 : nuBlue,
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedItem = value;
                      });
                      state.didChange(value);
                      widget.onChanged(value);
                    },
                    items:
                        widget.options.map((option) {
                          return DropdownMenuItem<String>(
                            value: option["label"],
                            child: Row(
                              children: [
                                Icon(option["icon"], color: nuBlue),
                                SizedBox(width: 10.w),
                                CustomFont(
                                  text: option["label"],
                                  fontSize: widget.fontSize,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: EdgeInsets.only(left: 12.w, top: 5.h),
                  child: Text(
                    state.errorText!,
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
