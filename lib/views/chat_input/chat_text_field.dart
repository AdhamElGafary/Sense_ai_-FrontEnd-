import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Custom text field component for the chat input
class ChatTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Function(String) onSubmitted;

  const ChatTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is visible
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xffA5B8C7),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xffA5B8C7), width: 1.w),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: "Ask anything",
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
          // Adjust padding based on keyboard visibility
          contentPadding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: isKeyboardVisible ? 4.h : 8.h,
          ),
          border: InputBorder.none,
          isDense:
              isKeyboardVisible, // Make more compact when keyboard is visible
        ),
        // Force chat to scroll up when text field grows
        onTap: () {
          if (!isKeyboardVisible) {
            // Scroll to ensure the text field is visible
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Give time for keyboard to appear
              Future.delayed(const Duration(milliseconds: 300), () {
                // This is just to trigger a rebuild when keyboard appears
                try {
                  (context as Element).markNeedsBuild();
                } catch (e) {
                  // Context might no longer be valid, which is fine
                }
              });
            });
          }
        },
        maxLines:
            isKeyboardVisible
                ? 3
                : null, // Limit lines when keyboard is visible
        onSubmitted: onSubmitted,
      ),
    );
  }
}
