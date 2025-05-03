import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_message_handlers_provider.dart';
import '../../controllers/text_controller.dart';
import 'chat_bubble.dart';

class ChatList extends ConsumerWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final TextController textController;

  const ChatList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.textController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the message handlers
    final messageHandlers = ref.watch(messageHandlersProvider(textController));

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(12.w),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(
          message: messages[index],
          onSummarize: messageHandlers.onSummarize,
        );
      },
    );
  }
}
