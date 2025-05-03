// lib/views/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/chat_screen_controller.dart';
import '../../providers/chat_provider.dart';
import '../../providers/live_streaming_provider.dart';
import '../../utils/constants.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/chat_list.dart';
import '../chat_input/chat_input.dart';
import 'components/chat_app_bar.dart';

/// The main chat screen, showing messages and input field.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  /// Controller for scrolling the chat list.
  final ScrollController _scrollController = ScrollController();
  late ChatScreenController _controller;

  @override
  void initState() {
    super.initState();
    // 1) Observe window metrics (to detect keyboard).
    WidgetsBinding.instance.addObserver(this);
    // 2) After the very first frame, scroll to bottom so latest messages show.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Instantiate your controller now that `ref` is ready
    _controller = ChatScreenController(
      ref: ref,
      scrollController: _scrollController,
    );
  }

  @override
  void dispose() {
    // Stop observing and dispose scroll controller
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  /// Called whenever window metrics change (e.g. keyboard opening/closing).
  @override
  void didChangeMetrics() {
    // If the keyboard just appeared (bottom inset > 0),
    // wait for animation then scroll to bottom.
    if (WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .viewInsets
            .bottom >
        0) {
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    }
  }

  /// Smoothly scrolls the chat list to its bottom.
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for chat messages and live‑stream flag
    final messages = ref.watch(chatProvider);
    final liveStreaming = ref.watch(liveStreamingProvider);

    return Scaffold(
      // Allow the gradient to extend behind the status bar / app bar
      extendBodyBehindAppBar: true,
      // Automatically resize body when keyboard appears
      resizeToAvoidBottomInset: true,

      // Top app bar with your live‑video and camera controls
      appBar: ChatAppBar(
        controller: _controller,
        liveStreaming: liveStreaming,
        onAfterCameraSwitch: () => setState(() {}),
      ),

      // Side menu drawer
      drawer: const ChatDrawer(),

      // Main content gradient background
      body: Container(
        decoration: customGradient,
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              // Chat message list
              Expanded(
                child: ChatList(
                  messages: messages,
                  scrollController: _scrollController,
                  textController: _controller.textController,
                ),
              ),

              // Input area (exactly as you provided, unmodified)
              ChatInputArea(
                controller: _controller,
                onStartRecording: () => _controller.startRecording(context),
                onStopRecording:
                    (send) => _controller.stopRecording(context, send),
                onKeyboardVisibilityChanged: (isVisible) {
                  if (isVisible) {
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      _scrollToBottom,
                    );
                  }
                },
              ),

              // Optional extra spacing to taste
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin wrapper around ChatInput to handle padding and forward callbacks.
/// ***This is exactly your code, unaltered.***
class ChatInputArea extends StatelessWidget {
  final ChatScreenController controller;
  final Future<bool> Function()? onStartRecording;
  final Future<void> Function(bool send)? onStopRecording;
  final Function(bool)? onKeyboardVisibilityChanged;

  const ChatInputArea({
    super.key,
    required this.controller,
    this.onStartRecording,
    this.onStopRecording,
    this.onKeyboardVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the keyboard is up
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Notify parent of keyboard changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onKeyboardVisibilityChanged != null) {
        onKeyboardVisibilityChanged!(isKeyboardVisible);
      }
    });

    // Pad by the system bottom inset (e.g. gesture bar)
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Container(
        color: Colors.transparent,
        child: ChatInput(
          onSend: (text) => controller.sendText(text, context),
          onPickFile: (fileType) => controller.pickFile(context, fileType),
          onStartRecording: onStartRecording,
          onStopRecording: onStopRecording,
          onLiveVideoAction: () => controller.startLiveVideoAnalysis(context),
          onImageAction: () => controller.sendImageFromCamera(context),
          onSummarize: (text) => controller.sendSummarizeRequest(text, context),
          onRecordAudio: () {}, // unchanged placeholder
        ),
      ),
    );
  }
}
