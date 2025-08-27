import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:nuspace_app/constants.dart';
import 'package:nuspace_app/widgets/customfont.dart';

class CustomNotification extends StatelessWidget {
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final VoidCallback onTap;

  const CustomNotification({
    super.key,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.onTap,
  });

  String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: isRead ? Colors.transparent : Colors.blue.shade50,
      leading: Icon(
        isRead ? Icons.notifications_none : Icons.notifications_active,
        color: isRead ? Colors.grey : nuBlue,
      ),
      title: Padding(
        padding: EdgeInsets.only(bottom: 5.h),
        child: CustomFont(
          text: title,
          fontSize: 16.r,
          fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      subtitle: CustomFont(
        text: message,
        fontSize: 14.r,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: CustomFont(
        text: getTimeAgo(createdAt),
        fontSize: 12.r,
        color: Colors.grey,
      ),
    );
  }
}
