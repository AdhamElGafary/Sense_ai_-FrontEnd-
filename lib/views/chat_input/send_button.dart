import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Send button for the chat input
class SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SendButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.send, color: const Color(0xffA5B8C7), size: 20.sp),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      constraints: BoxConstraints.tightFor(width: 32.w, height: 32.h),
      onPressed: onPressed,
    );
  }
}
