import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/chat_service.dart';

/// Base controller with common functionality shared across feature-specific controllers
class BaseController {
  final WidgetRef ref;
  final ScrollController scrollController;
  final ChatService chatService = ChatService();

  BaseController({required this.ref, required this.scrollController});

  /// Scrolls the chat list to the bottom.
  void scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
} 