import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class CustomCodeInputField extends StatefulWidget {
  final TextEditingController controller;

  const CustomCodeInputField({super.key, required this.controller});

  @override
  State<CustomCodeInputField> createState() => _CustomCodeInputFieldState();
}

class _CustomCodeInputFieldState extends State<CustomCodeInputField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text.padRight(6);
    final currentIndex = widget.controller.text.length.clamp(0, 5);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_focusNode);
      },
      child: Stack(
        children: [
          // Hidden TextFormField
          Opacity(
            opacity: 0.0,
            child: TextFormField(
              focusNode: _focusNode,
              controller: widget.controller,
              maxLength: 6,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),

          // Visible Boxes
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                bool hasValue = widget.controller.text.length > index;
                bool isCurrent = _focusNode.hasFocus && currentIndex == index;

                Color borderColor = Colors.grey;
                if (isCurrent || hasValue) borderColor = nuBlue;

                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 40.r,
                  height: 55.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: CustomFont(
                    text: hasValue ? code[index] : '',
                    fontSize: 16.r,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
