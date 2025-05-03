import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../controllers/chat_screen_controller.dart';

/// Controls for live video streaming
class LiveStreamingControls extends StatelessWidget {
  final ChatScreenController controller;
  final VoidCallback? onAfterCameraSwitch;

  const LiveStreamingControls({
    super.key,
    required this.controller,
    this.onAfterCameraSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stop button
        IconButton(
          icon: const Icon(Icons.stop, color: Colors.red),
          tooltip: "Stop Live Analysis",
          onPressed: () async {
            await controller.stopLiveVideoAnalysis();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Live analysis stopped.'),
                  backgroundColor: Colors.white,
                ),
              );
            }
          },
        ),

        // Camera name
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Text(
            controller.getActiveCameraName(),
            style: TextStyle(fontSize: 14.sp, color: Colors.white),
          ),
        ),

        // Switch camera button
        IconButton(
          icon: const Icon(Icons.switch_camera, color: Colors.white),
          tooltip: controller.getAlternateCameraName(),
          onPressed: () async {
            await controller.switchCamera(context);
            if (onAfterCameraSwitch != null) {
              onAfterCameraSwitch!();
            }
          },
        ),
      ],
    );
  }
}
