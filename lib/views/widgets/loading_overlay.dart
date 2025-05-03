import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';

/// A simple overlay with a loading spinner and optional text
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  // Static variable to keep track of visible overlays
  static bool _isVisible = false;
  static Timer? _timeoutTimer;

  /// Show loading overlay as a modal barrier
  /// Automatically dismisses after timeout (defaults to 10 seconds)
  static Future<void> show(
    BuildContext context, {
    String? message,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // If already visible, hide first to prevent stacking
    if (_isVisible) {
      hide();
    }

    _isVisible = true;

    // Cancel any existing timer
    _timeoutTimer?.cancel();

    // Create a timer to auto-dismiss the overlay if it gets stuck
    _timeoutTimer = Timer(timeout, () {
      // Auto-dismiss after timeout
      hide();
    });

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black26, // Lighter barrier for faster rendering
        useSafeArea: false, // Avoid safe area calculations for speed
        builder: (_) => LoadingOverlay(message: message),
      ).then((_) {
        // Mark as no longer visible when dismissed
        _isVisible = false;

        // Cancel the timer when dialog is dismissed normally
        if (_timeoutTimer != null && _timeoutTimer!.isActive) {
          _timeoutTimer!.cancel();
        }
      });
    } catch (e) {
      // If showing fails, make sure we reset the state
      _isVisible = false;
      _timeoutTimer?.cancel();
    }
  }

  /// Hide any active loading overlay
  /// Context is optional - will use navigator key if not provided
  static void hide([BuildContext? context]) {
    // Cancel the timeout timer
    _timeoutTimer?.cancel();

    // If not visible, nothing to do
    if (!_isVisible) return;

    // Mark as not visible immediately to prevent multiple calls
    _isVisible = false;

    try {
      // Try using the global navigator key first for fastest response
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pop();
      }
      // Fall back to context if provided
      else if (context != null) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      // Ignore errors from trying to pop a non-existent dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissal with back button
      child: Dialog(
        backgroundColor: Colors.black45, // Slightly more transparent
        elevation: 0,
        insetPadding: EdgeInsets.zero, // Remove padding for faster rendering
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3.0, // Thinner stroke for better performance
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    message!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
