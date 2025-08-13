import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class CustomRSOListTile extends StatelessWidget {
  final String? imageUrl, acronym, college, category;
  final bool probationary;
  final VoidCallback? onTap;

  const CustomRSOListTile({
    super.key,
    required this.imageUrl,
    required this.acronym,
    required this.college,
    required this.category,
    required this.probationary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 50.r,
                height: 50.r,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      width: 50.r,
                      height: 50.r,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      width: 50.r,
                      height: 50.r,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
              ),
            ),
            title: CustomFont(
              text: acronym ?? 'Undefined Name',
              fontSize: 16.r,
              fontWeight: FontWeight.bold,
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (college != null && college!.trim().isNotEmpty) ...[
                    CustomFont(
                      text: college!,
                      fontSize: 13.r,
                      color: Colors.grey.shade700,
                    ),
                    SizedBox(height: 2.h),
                  ],

                  //show either category or probationary
                  if (!probationary)
                    CustomFont(
                      text: category ?? '',
                      fontSize: 13.r,
                      color: Colors.grey.shade700,
                    )
                  else
                    CustomFont(
                      text: "Probationary",
                      fontSize: 13.r,
                      color: Colors.grey.shade700,
                    ),
                ],
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
