import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../controllers/chat_screen_controller.dart';
import '../../realtime_emotion_detection_screen.dart';
import 'live_streaming_controls.dart';

/// Custom app bar for the chat screen
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatScreenController controller;
  final bool liveStreaming;
  final VoidCallback onAfterCameraSwitch;

  const ChatAppBar({
    super.key,
    required this.controller,
    required this.liveStreaming,
    required this.onAfterCameraSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
      ),
      title: const Text(
        'Sense AI',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        if (!liveStreaming)
          IconButton(
            icon: const Icon(Icons.face_outlined, color: Colors.white),
            tooltip: 'Realtime Emotion',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RealtimeEmotionDetectionScreen(),
                ),
              );
            },
          ),
        if (liveStreaming)
          LiveStreamingControls(
            controller: controller,
            onAfterCameraSwitch: onAfterCameraSwitch,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
