import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

/// A class to represent the position data of the audio player
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

/// A widget that displays an audio player within a chat bubble.
///
/// This widget is designed to handle audio playback for chat messages. It supports
/// audio files provided as URLs, local file paths, or base64-encoded strings. The
/// widget adapts its appearance based on whether the message is from the user or
/// another participant in the chat.
///
/// Key Features:
/// - Automatically detects and handles different audio sources (URL, file path, base64).
/// - Provides playback controls (play, pause, seek).
/// - Displays a progress slider and duration information.
/// - Handles errors gracefully and allows retrying audio loading.
///
/// Usage:
/// ```dart
/// ChatAudioPlayer(
///   audioUrl: 'https://example.com/audio.mp3',
///   isUserMessage: true,
/// )
/// ```
class ChatAudioPlayer extends StatefulWidget {
  /// The URL or base64 string of the audio file
  final String audioUrl;

  /// Whether this is the user's message (affects styling)
  final bool isUserMessage;

  const ChatAudioPlayer({
    super.key,
    required this.audioUrl,
    this.isUserMessage = false,
  });

  @override
  State<ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<ChatAudioPlayer>
    with AutomaticKeepAliveClientMixin {
  late AudioPlayer _audioPlayer;
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _errorMessage;
  StreamSubscription? _playerStateSubscription;
  bool _disposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    if (_disposed) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First determine if we're dealing with a URL or base64 data
      final trimmedUrl = widget.audioUrl.trim();

      if (trimmedUrl.startsWith('http://') ||
          trimmedUrl.startsWith('https://')) {
        // Handle URL - try a simple Android emulator fix first
        final url = _fixEmulatorUrl(trimmedUrl);
        await _loadFromUrl(url);
      } else if (trimmedUrl.startsWith('file://') ||
          trimmedUrl.startsWith('/')) {
        // Handle local file path
        final filePath =
            trimmedUrl.startsWith('file://')
                ? trimmedUrl.replaceFirst('file://', '')
                : trimmedUrl;
        await _loadFromFilePath(filePath);
      } else {
        // Assume base64 encoded data
        await _loadFromBase64(trimmedUrl);
      }

      // Set up state listener to monitor playback
      _playerStateSubscription = _audioPlayer.playerStateStream.handleError((e) {
        debugPrint('ChatAudioPlayer: Error in player state stream: $e');
      }).listen(
        (state) {
          if (_disposed) return;

          if (mounted) {
            setState(() {
              // Update playing state based on player state
              _isPlaying =
                  state.playing &&
                  state.processingState != ProcessingState.completed &&
                  state.processingState != ProcessingState.idle;

              // Don't auto-seek back to beginning when completed
              // Just update UI state to show as not playing
            });
          }
        },
      );

      if (!_disposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ChatAudioPlayer: Error initializing player: $e');
      if (!_disposed && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load audio: $e';
        });
      }
    }
  }

  // Simple fix for Android emulator localhost URLs
  String _fixEmulatorUrl(String url) {
    if (Platform.isAndroid && url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  Future<void> _loadFromUrl(String url) async {
    try {
      debugPrint('ChatAudioPlayer: Loading from URL: $url');

      // Set a reasonable timeout to prevent hanging
      if (_disposed) return;
      await _audioPlayer
          .setUrl(url)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('URL loading timed out after 15 seconds');
            },
          );
      if (_disposed) return;
    } catch (e) {
      debugPrint('ChatAudioPlayer: Error loading from URL: $e');
      throw Exception('Failed to load audio from URL: $e');
    }
  }

  Future<void> _loadFromFilePath(String filePath) async {
    try {
      debugPrint('ChatAudioPlayer: Loading from file: $filePath');

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file does not exist at path: $filePath');
      }

      // Set a reasonable timeout
      if (_disposed) return;
      await _audioPlayer
          .setFilePath(filePath)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('File loading timed out after 10 seconds');
            },
          );
      if (_disposed) return;
    } catch (e) {
      debugPrint('ChatAudioPlayer: Error loading from file: $e');
      throw Exception('Failed to load audio from file: $e');
    }
  }

  Future<void> _loadFromBase64(String base64String) async {
    try {
      debugPrint('ChatAudioPlayer: Loading from base64 data');

      // Check if the string looks like base64
      final bool isProbablyBase64 = RegExp(
        r'^[A-Za-z0-9+/=]+$',
      ).hasMatch(base64String.trim());
      if (!isProbablyBase64) {
        throw FormatException('Invalid base64 format');
      }

      // Use a try-catch specifically for decoding to handle malformed base64
      Uint8List audioBytes;
      try {
        audioBytes = base64Decode(base64String);
      } catch (e) {
        throw Exception('Failed to decode base64 data: $e');
      }

      // Limit file size to prevent memory issues (10MB max)
      if (audioBytes.length > 10 * 1024 * 1024) {
        throw Exception(
          'Audio file too large (${(audioBytes.length / 1024 / 1024).toStringAsFixed(2)}MB)',
        );
      }

      // Create a temporary file with proper error handling
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      final File file = File(filePath);
      if (_disposed) return;
      await file.writeAsBytes(audioBytes);

      if (_disposed) return;
      await _audioPlayer.setFilePath(filePath);
    } catch (e) {
      debugPrint('ChatAudioPlayer: Error loading from base64: $e');
      throw Exception('Failed to decode base64 audio: $e');
    }
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        // If we're at the end, seek to beginning first
        final position = _audioPlayer.position;
        final duration = _audioPlayer.duration;

        if (duration != null && position >= duration) {
          await _audioPlayer.seek(Duration.zero);
        }

        await _audioPlayer.play();
      } catch (e) {
        debugPrint('ChatAudioPlayer: Error playing audio: $e');
        if (mounted && !_disposed) {
          setState(() {
            _errorMessage = 'Error playing audio: $e';
          });
        }
      }
    }
  }

  // Stream with proper error handling
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream.handleError((Object e) {
          debugPrint('Error in position stream: $e');
          return Duration.zero;
        }),
        _audioPlayer.bufferedPositionStream.handleError((Object e) {
          debugPrint('Error in buffered position stream: $e');
          return Duration.zero;
        }),
        _audioPlayer.durationStream.handleError((Object e) {
          debugPrint('Error in duration stream: $e');
          return null;
        }),
        (position, bufferedPosition, duration) {
          final safeDuration = duration ?? Duration.zero;
          final nonZeroDuration =
              safeDuration.inMilliseconds > 0
                  ? safeDuration
                  : const Duration(milliseconds: 1);

          final safePosition =
              position > nonZeroDuration ? nonZeroDuration : position;

          return PositionData(safePosition, bufferedPosition, nonZeroDuration);
        },
      ).handleError((Object e) {
        debugPrint('Error in combined position stream: $e');
        return PositionData(
          Duration.zero,
          Duration.zero,
          const Duration(milliseconds: 1),
        );
      });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _retryLoading() async {
    if (_disposed) return;

    // Clean up existing resources first
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio player: $e');
    }

    // Create a new player instance to avoid lingering issues
    await _playerStateSubscription?.cancel();
    await _audioPlayer.dispose();

    // Create fresh player
    _audioPlayer = AudioPlayer();
    await _initAudioPlayer();
  }

  @override
  void dispose() {
    _disposed = true;
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final textColor = widget.isUserMessage ? Colors.white : Colors.black87;
    final iconColor = widget.isUserMessage ? Colors.white : Colors.blue;

    if (_isLoading) {
      return SizedBox(
        height: 48.h,
        child: Center(
          child: SizedBox(
            width: 20.w,
            height: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audio error: $_errorMessage',
            style: TextStyle(color: Colors.red, fontSize: 14.sp),
          ),
          SizedBox(height: 8.h),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.isUserMessage
                      ? Colors.white.withOpacity(0.3)
                      : Colors.blue[400],
              foregroundColor:
                  widget.isUserMessage ? Colors.white : Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            onPressed: _retryLoading,
          ),
        ],
      );
    }

    return SizedBox(
      width: 220.w,
      child: StreamBuilder<PositionData>(
        stream: _positionDataStream,
        builder: (context, snapshot) {
          final positionData =
              snapshot.data ??
              PositionData(
                Duration.zero,
                Duration.zero,
                const Duration(milliseconds: 1),
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player controls and slider
              Row(
                children: [
                  // Play/pause button
                  IconButton(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: iconColor,
                      size: 36.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      maxWidth: 36.w,
                      maxHeight: 36.h,
                    ),
                    onPressed: _togglePlay,
                  ),

                  SizedBox(width: 8.w),

                  // Progress slider and duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Slider for seeking
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4.h,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 6.r,
                            ),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: 14.r,
                            ),
                            trackShape: const RoundedRectSliderTrackShape(),
                            activeTrackColor: iconColor,
                            inactiveTrackColor: iconColor.withOpacity(0.3),
                            thumbColor: iconColor,
                            overlayColor: iconColor.withOpacity(0.4),
                          ),
                          child: Slider(
                            min: 0.0,
                            max:
                                positionData.duration.inMilliseconds.toDouble(),
                            value: positionData.position.inMilliseconds
                                .toDouble()
                                .clamp(
                                  0.0,
                                  positionData.duration.inMilliseconds
                                      .toDouble(),
                                ),
                            onChanged: (value) {
                              _audioPlayer.seek(
                                Duration(milliseconds: value.round()),
                              );
                            },
                          ),
                        ),

                        // Time display
                        Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: Text(
                            '${_formatDuration(positionData.position)} / ${_formatDuration(positionData.duration)}',
                            style: TextStyle(
                              color: textColor.withOpacity(0.8),
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
