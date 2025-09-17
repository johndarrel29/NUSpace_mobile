import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import 'customfont.dart';

class ActivityCard extends StatelessWidget {
  final String rsoName,
      college,
      rsoImage,
      activityName,
      activityImage,
      date,
      description,
      status;
  final bool publicity;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.rsoName,
    required this.college,
    required this.rsoImage,
    required this.activityName,
    required this.activityImage,
    required this.date,
    required this.status,
    required this.description,
    required this.publicity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //rso image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50.r),
                    child: CachedNetworkImage(
                      imageUrl: rsoImage,
                      width: 40.r,
                      height: 40.r,
                      memCacheHeight: 100,
                      memCacheWidth: 100,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: nuBlue,
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 20.r,
                            ),
                          ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  //rso name and college
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomFont(
                          text: rsoName,
                          fontSize: 16.r,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: 5.h),
                        CustomFont(text: college, fontSize: 14.r),
                      ],
                    ),
                  ),

                  //activity date status
                  CustomFont(
                    text:
                        status == 'upcoming'
                            ? 'Upcoming '
                            : status == 'ongoing'
                            ? 'Ongoing'
                            : status == 'done'
                            ? 'Done'
                            : 'Unknown',
                    fontSize: 14.r,
                    color:
                        status == 'upcoming'
                            ? nuBlue
                            : status == 'ongoing'
                            ? Colors.red
                            : status == 'done'
                            ? Colors.green
                            : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: activityImage,
                fit: BoxFit.cover,
                memCacheWidth: 800,
                memCacheHeight: 600,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: nuBlue,
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.grey, size: 100),
                    ),
              ),
            ),

            // text section
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomFont(
                    text:
                        publicity == true
                            ? "Open For All"
                            : "Only For RSO Members",
                    fontSize: 14.r,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 5.h),
                  CustomFont(
                    text: activityName,
                    fontSize: 18.r,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 3.h),
                  CustomFont(text: date, fontSize: 14.r),
                  SizedBox(height: 5.h),
                  CustomFont(
                    text: description,
                    fontSize: 14.r,
                    color: Colors.grey,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
