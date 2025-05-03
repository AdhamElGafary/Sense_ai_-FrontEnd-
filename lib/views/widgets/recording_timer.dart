import 'dart:async';
import 'package:flutter/material.dart';

class RecordingTimer extends StatefulWidget {
  final int initialSeconds;
  const RecordingTimer({super.key, this.initialSeconds = 0});

  @override
  RecordingTimerState createState() => RecordingTimerState();
}

class RecordingTimerState extends State<RecordingTimer> {
  late final StreamController<int> _controller;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _elapsedSeconds = widget.initialSeconds;
    _controller = StreamController<int>.broadcast();

    // Add initial data immediately
    _controller.add(_elapsedSeconds);

    // Start timer after a small delay to ensure proper initialization
    Future.microtask(() {
      if (!_isDisposed) {
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
          if (_isDisposed) {
            timer.cancel();
            return;
          }
          _elapsedSeconds++;
          _controller.add(_elapsedSeconds);
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    _controller.close();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutesStr = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsStr = (seconds % 60).toString().padLeft(2, '0');
    return "$minutesStr:$secondsStr";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _controller.stream,
      initialData: _elapsedSeconds,
      builder: (context, snapshot) {
        final seconds = snapshot.data ?? _elapsedSeconds;
        return Text(
          "Recording time: ${_formatTime(seconds)}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        );
      },
    );
  }
}
