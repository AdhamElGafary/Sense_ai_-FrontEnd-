import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/text_controller.dart';

/// A provider for message-specific actions like summarization
class MessageHandlers {
  final Function(String, BuildContext) onSummarize;

  MessageHandlers({required this.onSummarize});
}

/// Provider for handlers that can be used in message bubbles
final messageHandlersProvider =
    Provider.family<MessageHandlers, TextController>(
      (ref, textController) => MessageHandlers(
        onSummarize:
            (text, context) =>
                textController.sendSummarizeRequest(text, context),
      ),
    );
