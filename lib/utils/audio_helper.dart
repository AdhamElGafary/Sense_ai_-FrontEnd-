import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHelper {
  // Singleton pattern
  static final AudioPlayerHelper _instance = AudioPlayerHelper._internal();
  factory AudioPlayerHelper() => _instance;
  AudioPlayerHelper._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentAudioFile;

  // Public getter for player status
  bool get isPlaying => _isPlaying;

  // Get the current audio file path
  String? get currentAudioFile => _currentAudioFile;

  /// Plays an audio file from a file path
  Future<void> playAudio(
    String filePath, {
    Function? onComplete,
    Function(Duration)? onPositionChanged,
    Function(double)? onVolumeChanged,
  }) async {
    try {
      // If something is already playing, stop it
      if (_isPlaying) {
        await _audioPlayer.stop();
      }

      // Set the file path
      _currentAudioFile = filePath;

      // Set up the audio source
      await _audioPlayer.setFilePath(filePath);

      // Set up completion listener
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          if (onComplete != null) {
            onComplete();
          }
        }
      });

      // Set up position listener
      if (onPositionChanged != null) {
        _audioPlayer.positionStream.listen((position) {
          onPositionChanged(position);
        });
      }

      // Start playback
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint("Error playing audio: $e");
      rethrow;
    }
  }

  /// Pauses the current playback
  Future<void> pause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
    }
  }

  /// Resumes the current playback
  Future<void> resume() async {
    if (!_isPlaying && _currentAudioFile != null) {
      await _audioPlayer.play();
      _isPlaying = true;
    }
  }

  /// Stops the current playback
  Future<void> stop() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      _isPlaying = false;
    }
  }

  /// Seeks to a specific position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Sets the volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// Clean up resources when done
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }

  /// Gets the duration of the current audio file
  Future<Duration?> getDuration() async {
    return _audioPlayer.duration;
  }

  /// Creates an audio player dialog
  Future<void> showAudioPlayerDialog(
    BuildContext context,
    String filePath, {
    String title = 'Audio Player',
  }) async {
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AudioPlayerDialog(filePath: filePath, title: title);
        },
      );
    } catch (e) {
      debugPrint("Error showing audio dialog: $e");
      rethrow;
    }
  }
}

/// A dialog that shows an audio player
class AudioPlayerDialog extends StatefulWidget {
  final String filePath;
  final String title;

  const AudioPlayerDialog({
    super.key,
    required this.filePath,
    this.title = 'Audio Player',
  });

  @override
  State<AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<AudioPlayerDialog> {
  final AudioPlayerHelper _playerHelper = AudioPlayerHelper();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // First try to get duration before playback
      await _playerHelper._audioPlayer.setFilePath(widget.filePath);
      _duration = await _playerHelper.getDuration() ?? Duration.zero;

      // Set up the listeners before starting playback
      _setupPositionListener();
      _setupStateListener();

      // Start playback
      await _playerHelper._audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Error initializing player: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  void _setupPositionListener() {
    _playerHelper._audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Also listen to buffered position for more accurate updates
    _playerHelper._audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  void _setupStateListener() {
    _playerHelper._audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = _duration; // Set position to end when completed
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _playerHelper.stop();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // Make sure duration is at least 1 millisecond to avoid slider errors
    final maxDuration =
        _duration.inMilliseconds > 0
            ? _duration.inMilliseconds.toDouble()
            : 1.0;
    final currentPosition = _position.inMilliseconds.toDouble();
    // Make sure position is within valid range
    final safePosition =
        currentPosition < 0
            ? 0.0
            : (currentPosition > maxDuration ? maxDuration : currentPosition);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Position and duration text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_position)),
                Text(_formatDuration(_duration)),
              ],
            ),
            // Seek slider
            Slider(
              value: safePosition,
              min: 0,
              max: maxDuration,
              onChanged: (value) {
                if (_duration.inMilliseconds > 0) {
                  final position = Duration(milliseconds: value.toInt());
                  _playerHelper._audioPlayer.seek(position);
                  setState(() {
                    _position = position;
                  });
                }
              },
            ),
            // Volume slider
            Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      _playerHelper._audioPlayer.setVolume(value);
                      setState(() {
                        _volume = value;
                      });
                    },
                  ),
                ),
                const Icon(Icons.volume_up),
              ],
            ),
            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    if (_duration.inMilliseconds > 0) {
                      final newPosition = Duration(
                        milliseconds: max(0, _position.inMilliseconds - 10000),
                      );
                      _playerHelper._audioPlayer.seek(newPosition);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 48,
                  onPressed: () {
                    if (_isPlaying) {
                      _playerHelper._audioPlayer.pause();
                    } else {
                      _playerHelper._audioPlayer.play();
                    }
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    if (_duration.inMilliseconds > 0) {
                      final newPosition = Duration(
                        milliseconds: min(
                          _duration.inMilliseconds,
                          _position.inMilliseconds + 10000,
                        ),
                      );
                      _playerHelper._audioPlayer.seek(newPosition);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _playerHelper.stop();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  // Helper functions to avoid going out of bounds
  int min(int a, int b) => a < b ? a : b;
  int max(int a, int b) => a > b ? a : b;
}
