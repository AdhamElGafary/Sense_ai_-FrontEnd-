import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sense_ai/views/widgets/custom_icon.dart';
import 'package:sense_ai/views/widgets/custom_popup_menu_button.dart';
import 'package:sense_ai/views/realtime_emotion_detection_screen.dart';

/// Button for video-related actions in the chat input
class VideoButton extends StatefulWidget {
  final Future<void> Function(String) onPickFile;
  final Future<void> Function()? onLiveVideoAction;

  const VideoButton({
    super.key,
    required this.onPickFile,
    this.onLiveVideoAction,
  });

  @override
  State<VideoButton> createState() => _VideoButtonState();
}

class _VideoButtonState extends State<VideoButton> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _isHandlingAction = false;

  void _handleMenuItemTap(String value) async {
    // Prevent duplicate actions
    if (_isHandlingAction) return;

    setState(() => _isHandlingAction = true);

    try {
      switch (value) {
        case "select_video":
          await widget.onPickFile("video");
          break;
        case "live_video":
          if (widget.onLiveVideoAction != null) {
            await widget.onLiveVideoAction!();
          }
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isHandlingAction = false);
      }
    }
  }

  void _showPopupMenu() {
    if (_isHandlingAction) return;

    // Capture the current focused node to restore it later
    final currentFocus = FocusScope.of(context);
    final focusedChild = currentFocus.focusedChild;

    List<CustomPopupMenuItem> menuItems = [
      CustomPopupMenuItem(
        icon: Icons.video_file,
        text: "Select video",
        value: "select_video",
        onTap: (String value) {
          _handleMenuItemTap(value);
        },
      ),
      CustomPopupMenuItem(
        icon: Icons.video_call,
        text: "Live Analysis",
        value: "live_video",
        onTap: (String value) {
          // Navigate to RealtimeEmotionDetectionScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RealtimeEmotionDetectionScreen(),
            ),
          );
        },
      ),
    ];

    // Use CustomPopupMenu to show the options
    CustomPopupMenu(
      context: context,
      buttonKey: _buttonKey,
      menuItems: menuItems,
      menuWidth: 200.w,
      backgroundColor: Colors.white,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return customImageButton(
      key: _buttonKey,
      imageColor:
          _isHandlingAction
              ? const Color(0xff7A8B9A) // Dimmed color when handling action
              : const Color(0xffA5B8C7),
      imageSize: 20.sp,
      imagePath: "assets/videocam.png",
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      onPressed: _isHandlingAction ? () {} : _showPopupMenu,
    );
  }
}
