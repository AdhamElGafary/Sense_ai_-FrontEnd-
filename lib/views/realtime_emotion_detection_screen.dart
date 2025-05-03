import 'dart:async';
import 'dart:io';
import 'dart:ui'; // Needed for ImageFilter.blur
// Importing the camera package to enable access to device cameras.
// This package provides utilities to list available cameras and
// manage a CameraController for capturing images.
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for DeviceOrientation
import 'package:sense_ai/services/realtime_emotion_service.dart';

/// A screen for real-time emotion detection using device camera
///
/// This screen captures video frames from the camera at regular intervals,
/// analyzes them for emotions, and displays the results in real-time.
class RealtimeEmotionDetectionScreen extends StatefulWidget {
  const RealtimeEmotionDetectionScreen({super.key});

  @override
  State<RealtimeEmotionDetectionScreen> createState() =>
      _RealtimeEmotionDetectionScreenState();
}

class _RealtimeEmotionDetectionScreenState
    extends State<RealtimeEmotionDetectionScreen>
    with WidgetsBindingObserver {
  /// Configuration constants
  static const int frameCaptureInterval = 100; // milliseconds
  static const ResolutionPreset cameraResolution = ResolutionPreset.medium;

  /// Controllers and services
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  late RealtimeEmotionService _emotionService;

  /// Timers and streams
  Timer? _frameTimer;
  late Stream<int> _timerStream;

  /// State variables
  bool _isSessionActive = false;
  String _currentEmotion = "Unknown";
  double _confidence = 0.0;
  Map<String, double> _emotionPercentages = {};
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  int _frameCount = 0;
  DateTime? _sessionStartTime;
  bool _isCameraPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _emotionService = RealtimeEmotionService(debug: true);
    _initializeCamera();
    _timerStream = Stream.periodic(
      const Duration(seconds: 1),
      (count) => count,
    );

    // Lock the device orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (pause/resume) for better camera resource management
    if (!_cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // Free up resources when app is inactive
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize camera when app is resumed
      _initializeCamera();
    }
  }

  /// Initialize camera with proper settings
  Future<void> _initializeCamera() async {
    if (_isCameraPermissionDenied) return;

    try {
      setState(() => _isCameraInitialized = false);

      // Get available cameras
      try {
        _cameras = await availableCameras();
        if (_cameras.isEmpty) throw Exception('No cameras available');
      } catch (e) {
        debugPrint('Error fetching cameras: $e');
        _showErrorSnackBar('No cameras available: $e');
        setState(() => _isCameraPermissionDenied = true);
        return;
      }

      // Find front camera (preferred) or use first available
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      // Dispose old controller if it exists
      await _disposeCamera();

      // Create and initialize new controller
      _cameraController = CameraController(
        camera,
        cameraResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController.initialize();
      await _cameraController.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      // Ensure highest quality settings available
      await _cameraController.setFlashMode(FlashMode.off);

      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _showErrorSnackBar('Failed to initialize camera: $e');
    }
  }

  /// Safely dispose camera controller
  Future<void> _disposeCamera() async {
    try {
      if (_cameraController.value.isInitialized) {
        await _cameraController.dispose();
      }
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
  }

  /// Start an emotion detection session
  Future<void> _startSession() async {
    if (!_cameraController.value.isInitialized) {
      _showErrorSnackBar('Camera not ready. Please wait or restart the app.');
      return;
    }

    setState(() {
      _isProcessingFrame = false;
      _isSessionActive = true;
      _sessionStartTime = DateTime.now();
      _frameCount = 0;
      _emotionPercentages = {};
    });

    try {
      final sessionId = await _emotionService.startSession();

      if (!mounted) return;

      if (sessionId != null) {
        setState(() {
          _isSessionActive = true;
          _frameCount = 0;
          _sessionStartTime = DateTime.now();
          _currentEmotion = "Detecting...";
          _confidence = 0.0;
        });

        _frameTimer = Timer.periodic(
          const Duration(milliseconds: frameCaptureInterval),
          (_) => _captureAndAnalyzeFrame(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Started emotion analysis session')),
        );
      } else {
        setState(() => _isSessionActive = false);
        _showErrorSnackBar('Failed to start session');
      }
    } catch (e) {
      debugPrint('Error starting session: $e');
      setState(() => _isSessionActive = false);
      _showErrorSnackBar('Error starting session: $e');
    }
  }

  /// Capture and analyze a single camera frame
  Future<void> _captureAndAnalyzeFrame() async {
    // Prevent concurrent frame processing
    if (!mounted ||
        !_cameraController.value.isInitialized ||
        !_isSessionActive ||
        _isProcessingFrame) {
      return;
    }

    try {
      setState(() => _isProcessingFrame = true);

      // Capture frame with camera
      final XFile imageFile = await _cameraController.takePicture();

      // Process frame with emotion service
      final result = await _emotionService.processFrame(File(imageFile.path));

      // <<< DEBUGGING POINT 1: Log raw result from service >>>
      debugPrint('[DEBUG] Raw analysis result: $result');

      // Cleanup temporary file
      try {
        await File(imageFile.path).delete();
      } catch (e) {
        debugPrint('Warning: Failed to delete temporary image file: $e');
      }

      // Update UI with results
      if (result != null && mounted) {
        // Prepare variables before setState for clarity
        final newEmotion = result['emotion'] ?? "Unknown";
        final newConfidence = (result['confidence'] ?? 0.0) * 100;
        Map<String, double> newPercentages = {};
        if (result['emotion_percentages'] is Map<String, dynamic>) {
          final jsonMap = result['emotion_percentages'] as Map<String, dynamic>;
          newPercentages = Map.fromEntries(
            jsonMap.entries
                .where((e) => e.value is num)
                .map((e) => MapEntry(e.key, (e.value as num).toDouble())),
          );
        }

        setState(() {
          _frameCount++;
          _currentEmotion = newEmotion;
          _confidence = newConfidence;
          _emotionPercentages = newPercentages;

          // <<< DEBUGGING POINT 2: Log values being set to state >>>
          debugPrint(
            '[DEBUG] Updating state: Emotion=$_currentEmotion, Confidence=$_confidence, Percentages=$_emotionPercentages',
          );
        });
      }
    } catch (e) {
      debugPrint('Error capturing frame: $e');
    } finally {
      if (mounted) setState(() => _isProcessingFrame = false);
    }
  }

  /// End the current emotion detection session
  Future<void> _endSession() async {
    // Cancel frame timer
    _frameTimer?.cancel();
    _frameTimer = null;

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ending session...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    setState(() => _isProcessingFrame = false);

    try {
      // Get session results
      final result = await _emotionService.endSession();

      if (mounted) {
        setState(() {
          _isSessionActive = false;
          _emotionPercentages = {};
          _currentEmotion = "Unknown";
          _confidence = 0.0;
        });
      }

      // Show results dialog
      if (mounted && result != null) {
        _showSessionResults(result);
      } else if (mounted) {
        _showErrorSnackBar('No analysis results available');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error in _endSession: $e');

      if (mounted) {
        setState(() => _isSessionActive = false);
        _showErrorSnackBar('Error ending session: $e');
        Navigator.pop(context);
      }
    }
  }

  /// Show results dialog with emotion analysis data
  void _showSessionResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Session Results',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dominant emotion: ${results['session_data']['dominant_emotion'] ?? "Unknown"}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Frames analyzed: ${results['session_data']['total_frames']}',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Emotion Distribution:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: _buildEmotionDistributionList(
                      results['session_data']['emotion_percentages'],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                child: const Text('Return to Chat'),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  Navigator.of(context).pop(); // Return to chat screen
                },
              ),
            ],
          ),
    );
  }

  /// Build a list of emotion distribution items
  Widget _buildEmotionDistributionList(Map<String, dynamic>? emotionData) {
    if (emotionData == null) {
      return const Center(child: Text('No emotion data available'));
    }

    // Convert to correct types and sort by percentage (highest first)
    final Map<String, double> emotionPercentages = {};
    emotionData.forEach((key, value) {
      if (value is num) {
        emotionPercentages[key] = value.toDouble();
      }
    });

    final sortedEmotions =
        emotionPercentages.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      itemCount: sortedEmotions.length,
      itemBuilder: (context, index) {
        final entry = sortedEmotions[index];
        return ListTile(
          dense: true,
          title: Text(entry.key),
          trailing: Text('${entry.value.toStringAsFixed(1)}%'),
          leading: Icon(
            Icons.circle,
            color: _getEmotionColor(entry.key),
            size: 16,
          ),
        );
      },
    );
  }

  /// Display an error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    // Cancel frame timer
    _frameTimer?.cancel();

    // End any active session
    if (_isSessionActive) {
      _emotionService.cancelSession();
    }

    // Dispose camera resources
    _disposeCamera();

    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Reset orientation settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCameraPermissionDenied) {
      return _buildPermissionDeniedScreen();
    }

    if (!_isCameraInitialized) {
      return _buildLoadingScreen();
    }

    // Main UI Structure: Stack for layering
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Layer 1: Full Screen Camera Preview
          _buildFullscreenCameraPreview(),

          // Layer 2: Top Status/Emotion Bar
          Positioned(top: 0, left: 0, right: 0, child: _buildTopStatusBar()),

          // Layer 3: Bottom Controls and Chart
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomOverlay(),
          ),
        ],
      ),
    );
  }

  /// Build the full-screen camera preview
  Widget _buildFullscreenCameraPreview() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController.value.previewSize!.height,
          height: _cameraController.value.previewSize!.width,
          child: CameraPreview(_cameraController),
        ),
      ),
    );
  }

  /// Build the top status bar displaying current emotion
  Widget _buildTopStatusBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.black.withOpacity(0.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emotion: $_currentEmotion (${_confidence.toStringAsFixed(1)}%)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isSessionActive && _sessionStartTime != null)
              _buildSessionTimer(),
          ],
        ),
      ),
    );
  }

  /// Build the bottom overlay containing controls and chart
  Widget _buildBottomOverlay() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          // Use padding within the container after blur
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ), // Adjust for safe area
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emotion Distribution Chart (if active)
              if (_isSessionActive && _emotionPercentages.isNotEmpty)
                _buildOverlayEmotionDistribution(),

              const SizedBox(height: 16),

              // Control Buttons
              _buildOverlayControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the emotion distribution chart for the overlay
  Widget _buildOverlayEmotionDistribution() {
    return SizedBox(
      height: 100,
      child:
          _emotionPercentages.isEmpty
              ? const Center(
                child: Text(
                  'Waiting for data...',
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : _buildEmotionBars(textColor: Colors.white),
    );
  }

  /// Build emotion bars visualization (modified for overlay)
  Widget _buildEmotionBars({Color textColor = Colors.black}) {
    final sortedEmotions =
        _emotionPercentages.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      itemCount: sortedEmotions.length,
      itemBuilder: (context, index) {
        final emotion = sortedEmotions[index].key;
        final percentage = sortedEmotions[index].value;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  '$emotion:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getEmotionColor(emotion),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 45,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(color: textColor, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build control buttons for the overlay
  Widget _buildOverlayControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Start analysis button (Bottom Left)
        ElevatedButton.icon(
          onPressed:
              (_isSessionActive || _isProcessingFrame) ? null : _startSession,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Colors.green.withOpacity(0.8),
            foregroundColor: Colors.white,
          ),
        ),

        // End analysis button (Bottom Right)
        ElevatedButton.icon(
          onPressed: _isSessionActive ? _endSession : null,
          icon: const Icon(Icons.stop),
          label: const Text('End'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Colors.red.withOpacity(0.8),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Build session timer widget
  Widget _buildSessionTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
      child: StreamBuilder<int>(
        stream: _timerStream,
        builder: (context, snapshot) {
          final duration = DateTime.now().difference(_sessionStartTime!);
          return Text(
            '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  /// Build camera loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time Emotion Detection')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Initializing camera...'),
          ],
        ),
      ),
    );
  }

  /// Build permission denied screen
  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Access Required')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Camera permission is required for emotion analysis',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please enable camera access in your device settings to use this feature.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isCameraPermissionDenied = false);
                  _initializeCamera();
                },
                child: const Text('Try Again'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get color for an emotion (Updated Colors)
  Color _getEmotionColor(String emotion) {
    final Map<String, Color> emotionColors = {
      'happy': Colors.green[400]!,
      'sad': Colors.blue[400]!,
      'angry': Colors.red[600]!,
      'surprised': Colors.purple[400]!,
      'fear': Colors.deepPurple[400]!,
      'disgust': Colors.brown[400]!,
      'neutral': Colors.grey[500]!,
    };

    return emotionColors[emotion.toLowerCase()] ?? Colors.grey[500]!;
  }
}
