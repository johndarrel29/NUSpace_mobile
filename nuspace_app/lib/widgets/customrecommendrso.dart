import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class CustomRecommendRSO extends StatelessWidget {
  final String? imageUrl, acronym, priority, explanation;
  final VoidCallback? onTap;
  final int? rank;

  const CustomRecommendRSO({
    super.key,
    required this.imageUrl,
    required this.acronym,
    required this.priority,
    required this.explanation,
    required this.onTap,
    this.rank,
  });

  @override
  Widget build(BuildContext context) {
    bool hasValidImage = imageUrl != null && imageUrl!.startsWith("https");
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rank != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: nuBlue,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: CustomFont(
                    text: "Top $rank",
                    fontSize: 12.r,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              SizedBox(height: 10.h),

              //RSO Image
              ClipRRect(
                borderRadius: BorderRadius.circular(50.r),
                child:
                    hasValidImage
                        ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          width: 80.r,
                          height: 80.r,
                          memCacheWidth: 256,
                          memCacheHeight: 256,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                width: 80.r,
                                height: 80.r,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                width: 80.r,
                                height: 80.r,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                ),
                              ),
                        )
                        : Container(
                          width: 80.r,
                          height: 80.r,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.white),
                        ),
              ),

              SizedBox(height: 10.h),

              //acronym
              CustomFont(
                text: acronym!,
                fontSize: 18.r,
                fontWeight: FontWeight.bold,
              ),

              SizedBox(height: 10.r),

              //priority
              CustomFont(
                text: priority!,
                fontSize: 16.r,
                fontWeight: FontWeight.w600,
                color: nuBlue,
              ),
              SizedBox(height: 4.h),
              CustomFont(text: explanation!, fontSize: 14.r),
            ],
          ),
        ),
      ),
    );
  }
}
