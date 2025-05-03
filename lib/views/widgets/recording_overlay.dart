import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecordingOverlay extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSend; // Called when long press ends without cancel

  const RecordingOverlay({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<RecordingOverlay> createState() => RecordingOverlayState();
}

class RecordingOverlayState extends State<RecordingOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isCancelled = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  // Method to be called from GestureDetector's onLongPressMoveUpdate
  void updateGesture(Offset localPosition, Size overlaySize) {
    // Simple cancellation logic: sliding left significantly
    final bool cancelled = localPosition.dx < overlaySize.width * 0.2;
    if (cancelled != _isCancelled) {
      setState(() {
        _isCancelled = cancelled;
      });
    }
  }

  // Method to be called from GestureDetector's onLongPressEnd
  void finalizeGesture() {
    _timer?.cancel();
    if (_isCancelled) {
      widget.onCancel();
    } else {
      widget.onSend();
    }
    // Potentially add a slight delay before Navigator.pop if needed
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 30.w),
          decoration: BoxDecoration(
            color:
                _isCancelled
                    ? Colors.red.withOpacity(0.8)
                    : Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.8,
                      end: 1.0,
                    ).animate(_animationController),
                    child: Icon(
                      _isCancelled ? Icons.delete_outline : Icons.mic,
                      color: _isCancelled ? Colors.white : Colors.redAccent,
                      size: 40.sp,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Text(
                    _formatDuration(_secondsElapsed),
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: _isCancelled ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Text(
                _isCancelled ? "Release to cancel" : "< Slide to cancel",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: _isCancelled ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show the overlay
void showRecordingOverlay(
  BuildContext context, {
  required VoidCallback onCancel,
  required VoidCallback onSend,
}) {
  // Use a GlobalKey to access the state later
  final GlobalKey<RecordingOverlayState> overlayKey =
      GlobalKey<RecordingOverlayState>();

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false, // Make background transparent
      pageBuilder:
          (context, animation, secondaryAnimation) => RecordingOverlay(
            key: overlayKey, // Assign the key
            onCancel: onCancel,
            onSend: onSend,
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );

  // Return the key so the caller can interact with the state
  // IMPORTANT: This pattern is generally discouraged. We'll use it here
  // for simplicity but a better approach might involve a state management solution.
  // We will need this key to call updateGesture and finalizeGesture.
  // We store this key in the AudioButton's state.
}
