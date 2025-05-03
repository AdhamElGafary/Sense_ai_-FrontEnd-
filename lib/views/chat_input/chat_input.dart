import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_text_field.dart';
import 'media_buttons/audio_button.dart';
import 'media_buttons/image_button.dart';
import 'media_buttons/video_button.dart';
import 'send_button.dart';

/// Main input widget for the chat screen
class ChatInput extends StatefulWidget {
  final void Function(String) onSend;
  final Future<void> Function(String) onPickFile;
  final Future<bool> Function()? onStartRecording;
  final Future<void> Function(bool send)? onStopRecording;
  final Future<void> Function()? onLiveVideoAction;
  final Future<void> Function()? onImageAction;
  final Future<void> Function(String)? onSummarize;

  const ChatInput({
    super.key,
    required this.onSend,
    required this.onPickFile,
    this.onStartRecording,
    this.onStopRecording,
    this.onLiveVideoAction,
    this.onImageAction,
    this.onSummarize,
    required Function() onRecordAudio,
  });

  @override
  ChatInputState createState() => ChatInputState();
}

class ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Listen for focus changes
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      // Rebuild when focus changes to update UI
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 5.w,
        vertical: isKeyboardVisible ? 4.h : 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        // Add a subtle shadow to separate input from content
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hide media buttons when keyboard is visible on small screens
          if (!isKeyboardVisible ||
              MediaQuery.of(context).size.width > 360.w) ...[
            // Image button for image-related actions
            ImageButton(
              onPickFile: widget.onPickFile,
              onImageAction: widget.onImageAction,
            ),

            // Audio button for audio-related actions
            AudioButton(
              onPickFile: widget.onPickFile,
              onStartRecording: widget.onStartRecording,
              onStopRecording: widget.onStopRecording,
            ),

            // Video button for video-related actions
            VideoButton(
              onPickFile: widget.onPickFile,
              onLiveVideoAction: widget.onLiveVideoAction,
            ),
          ],

          // Text input field - expanded to take available space
          Expanded(
            child: Align(
              alignment: Alignment.center, // Center the text field vertically
              child: ChatTextField(
                controller: _controller,
                focusNode: _focusNode,
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),

          // Send button
          SendButton(onPressed: _handleSend),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}
