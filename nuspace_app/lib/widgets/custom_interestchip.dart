import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const InterestChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled && !isSelected ? null : onTap,
      child: Opacity(
        opacity: isDisabled && !isSelected ? 0.4 : 1,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? nuBlue : Colors.white,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomFont(
                text: label,
                fontSize: 14.r,
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
              if (isSelected)
                Padding(
                  padding: EdgeInsets.only(left: 6.w),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16.r,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
