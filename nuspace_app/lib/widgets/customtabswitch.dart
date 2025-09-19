import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class CustomTabSwitch extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final double fontSize;
  final ValueChanged<int> onTabSelected;
  final Color activeColor;
  final Color inactiveColor;
  final Color indicatorColor;

  const CustomTabSwitch({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.activeColor = nuBlue,
    this.inactiveColor = Colors.grey,
    this.indicatorColor = nuBlue,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localOffset = box.globalToLocal(details.globalPosition);
        final tabWidth = box.size.width / tabs.length;
        final tappedIndex = (localOffset.dx ~/ tabWidth);
        onTabSelected(tappedIndex);
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = index == selectedIndex;
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 8.h),
                  CustomFont(
                    text: tabs[index],
                    fontSize: fontSize.r,
                    fontWeight: FontWeight.w600,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                  SizedBox(height: 4.h),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 3.h,
                    width: isActive ? 24.w : 0,
                    decoration: BoxDecoration(
                      color: isActive ? indicatorColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
