import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class CustomOfficerCard extends StatelessWidget {
  final String name, imageUrl, position;
  final double? width;

  const CustomOfficerCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.position,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? (MediaQuery.of(context).size.width - 52.w) / 2,
      constraints: BoxConstraints(minHeight: 150.h),
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50.r),
            child:
                imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 80.r,
                      height: 80.r,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            width: 80.r,
                            height: 80.r,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            width: 80.r,
                            height: 80.r,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                    )
                    : Container(
                      width: 80.r,
                      height: 80.r,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.white),
                    ),
          ),
          SizedBox(height: 12.h),
          CustomFont(
            text: name,
            fontSize: 16.r,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5.h),
          CustomFont(
            text: position,
            fontSize: 14.r,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            fontStyle: FontStyle.italic,
          ),
        ],
      ),
    );
  }
}
