import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class ViewRSOActivityCard extends StatelessWidget {
  final String imageUrl, name, date, description, status;
  final bool publicity;
  final VoidCallback onTap;

  const ViewRSOActivityCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.date,
    required this.description,
    required this.publicity,
    required this.status,
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
            AspectRatio(
              aspectRatio: 4 / 3,
              child:
                  imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: imageUrl,
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
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                      )
                      : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image,
                          color: Colors.white,
                          size: 100,
                        ),
                      ),
            ),

            // text section
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomFont(
                        text:
                            publicity == true
                                ? "Open For All"
                                : "Only For RSO Members",
                        fontSize: 14.r,
                        color: Colors.grey,
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
                  SizedBox(height: 5.h),
                  CustomFont(
                    text: name,
                    fontSize: 18.r,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 3.h),
                  CustomFont(text: date, fontSize: 14.r),
                  SizedBox(height: 15.h),
                  CustomFont(
                    text: description,
                    fontSize: 14.r,
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
