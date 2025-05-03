import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:sense_ai/views/widgets/custom_icon.dart';
import 'package:sense_ai/views/widgets/custom_popup_menu_button.dart'; // Import for CustomPopupMenu

/// Button for audio-related actions in the chat input
class AudioButton extends StatefulWidget {
  final Future<void> Function(String) onPickFile;
  final Future<bool> Function()? onStartRecording;
  final Future<void> Function(bool send)? onStopRecording;

  const AudioButton({
    super.key,
    required this.onPickFile,
    this.onStartRecording,
    this.onStopRecording,
  });

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _isHandlingAction = false;
  bool _isRecording = false;

  // Show popup menu
  void _showPopupMenu() {
    if (_isHandlingAction || _isRecording) return;

    // Calculate appropriate offset based on keyboard visibility
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Capture the current focused node to restore it later
    final currentFocus = FocusScope.of(context);
    final focusedChild = currentFocus.focusedChild;

    // Create menu items with the same style as VideoButton
    List<CustomPopupMenuItem> menuItems = [
      CustomPopupMenuItem(
        icon: Icons.folder_open,
        text: "Select audio",
        value: "select_audio",
        onTap: (String value) {
          _handlePickFile();
        },
      ),
      CustomPopupMenuItem(
        icon: Icons.mic,
        text: "Record audio",
        value: "record_audio",
        onTap: (String value) {
          _showSimpleRecordingUI();
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

  // Handle file picking
  Future<void> _handlePickFile() async {
    if (_isHandlingAction) return;
    setState(() => _isHandlingAction = true);
    try {
      await widget.onPickFile("audio");
    } finally {
      if (mounted) {
        setState(() => _isHandlingAction = false);
      }
    }
  }

  // A very simple approach with a bare minimum of complexity
  Future<void> _showSimpleRecordingUI() async {
    if (widget.onStartRecording == null || widget.onStopRecording == null) {
      return;
    }

    // Start recording
    bool recordingStarted = await widget.onStartRecording!();
    if (!recordingStarted || !mounted) return;

    print("Debug: Recording started successfully");
    setState(() => _isRecording = true);

    // Initialize values
    bool shouldSend = true;
    ValueNotifier<int> seconds = ValueNotifier<int>(0);
    ValueNotifier<bool> isCancelled = ValueNotifier<bool>(false);
    Timer? timer;
    Offset? startPosition;

    try {
      // Set up the timer with a ValueNotifier for reliable updates
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        seconds.value++;
        // Print time for debugging
        if (seconds.value % 5 == 0) {
          print(
            "Debug: Recording in progress - ${seconds.value} seconds elapsed",
          );
        }
      });

      // Show the UI
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                // Invisible full-screen gesture detector
                Positioned.fill(
                  child: GestureDetector(
                    onHorizontalDragStart: (details) {
                      startPosition = details.globalPosition;
                      print("Debug: Drag started at ${startPosition!.dx}");
                    },
                    onHorizontalDragUpdate: (details) {
                      if (startPosition == null) return;

                      // Calculate horizontal distance
                      double delta =
                          details.globalPosition.dx - startPosition!.dx;
                      print("Debug: DRAG DISTANCE: $delta");

                      // Update cancelled state if dragged far enough
                      bool newCancelled = delta < -25;
                      if (newCancelled != isCancelled.value) {
                        print(
                          "Debug: Cancellation state changed to $newCancelled",
                        );
                        isCancelled.value = newCancelled;
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      print(
                        "Debug: Drag ended, cancelled=${isCancelled.value}",
                      );
                      if (isCancelled.value) {
                        shouldSend = false;
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    // Make it actually detect gestures by having a color
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Actual dialog UI
                Center(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isCancelled,
                    builder: (context, cancelled, _) {
                      return Container(
                        margin: EdgeInsets.all(16.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: cancelled ? Colors.red.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon
                                Icon(
                                  cancelled ? Icons.delete : Icons.mic,
                                  color: cancelled ? Colors.red : Colors.blue,
                                  size: 24.sp,
                                ),
                                SizedBox(width: 12.w),
                                // Timer
                                ValueListenableBuilder<int>(
                                  valueListenable: seconds,
                                  builder: (context, value, _) {
                                    String time = _formatDuration(value);
                                    return Text(
                                      time,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            cancelled
                                                ? Colors.red
                                                : Colors.black87,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(width: 12.w),
                                // Instructions
                                Text(
                                  cancelled
                                      ? "Release to cancel"
                                      : "← Drag left to cancel",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color:
                                        cancelled ? Colors.red : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            // Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    print("Debug: Cancel button pressed");
                                    shouldSend = false;
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: Text("Cancel"),
                                ),
                                SizedBox(width: 8.w),
                                TextButton(
                                  onPressed: () {
                                    print("Debug: Send button pressed");
                                    shouldSend = true;
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: Text("Send"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      // Clean up
      timer?.cancel();
      if (mounted) {
        setState(() => _isRecording = false);
      }

      // Debug the final state
      print("Debug: Dialog closed, shouldSend=$shouldSend");

      try {
        // Stop recording
        print("Debug: Stopping recording with shouldSend=$shouldSend");
        await widget.onStopRecording!(shouldSend);
        print("Debug: Recording stopped successfully");
      } catch (e) {
        print("Debug: Error stopping recording: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error processing audio: $e")));
        }
      }
    }
  }

  // Format duration as mm:ss
  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return customImageButton(
      key: _buttonKey,
      imageColor:
          _isHandlingAction || _isRecording
              ? const Color(0xff7A8B9A)
              : const Color(0xffA5B8C7),
      imageSize: 20.sp,
      imagePath: "assets/microphone-2.png",
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      onPressed: () {
        if (!_isHandlingAction && !_isRecording) {
          _showPopupMenu();
        }
      },
    );
  }
}
