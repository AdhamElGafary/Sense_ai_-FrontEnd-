import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sense_ai/views/widgets/message_content_widget.dart';

import '../../models/chat_message.dart';

/// A widget that displays a chat message bubble
/// Handles user and bot messages with different styling
class ChatBubble extends ConsumerWidget {
  final ChatMessage message;
  final Function(String, BuildContext)? onSummarize;

  const ChatBubble({super.key, required this.message, this.onSummarize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isUser = message.isUser;
    final backgroundColor = isUser ? Colors.blue[400] : Colors.white;

    // Create the content widget based on message type
    final contentWidget = MessageContentFactory.createContentWidget(
      message: message,
      onSummarize: onSummarize,
    );

    // Define border radius based on who sent the message
    final borderRadius =
        isUser
            ? BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(16.r),
            )
            : BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar for bot messages
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16.r,
              child: Padding(
                padding: EdgeInsets.all(2.r),
                child: ClipOval(
                  child: Image.asset('assets/sense.png', fit: BoxFit.cover),
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],

          // Message bubble
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: contentWidget,
            ),
          ),

          // Avatar for user messages
          if (isUser) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 16.r,
              child: Icon(Icons.person, color: Colors.white, size: 16.sp),
            ),
          ],
        ],
      ),
    );
  }
}
