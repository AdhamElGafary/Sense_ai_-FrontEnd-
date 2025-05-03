import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sense_ai/models/chat_message.dart';
import 'package:sense_ai/models/chat_models.dart';
import 'package:sense_ai/views/widgets/recording_timer.dart';

import '../providers/chat_provider.dart';
import 'base_controller.dart';

/// Controller for handling audio recording and processing
/// Manages all audio recording functionality including permissions, recording UI,
/// and communication with backend services for speech-to-text and audio analysis
class AudioController extends BaseController {
  // Audio recording fields
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  final ValueNotifier<String> recordingTime = ValueNotifier<String>('00:00');
  final ValueNotifier<bool> isRecording = ValueNotifier<bool>(false);
  final ValueNotifier<String> errorMessage = ValueNotifier<String>('');
  AudioRecorder? _audioRecorder;
  bool _isStartingRecording = false; // Prevent concurrent starts

  AudioController({required super.ref, required super.scrollController});

  // MARK: - Timer Management

  /// Starts a timer to track recording duration and update UI
  /// Updates recordingTime ValueNotifier every second with formatted time
  void _startTimer() {
    _recordingDuration = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration++;
      final minutes = (_recordingDuration ~/ 60).toString().padLeft(2, '0');
      final seconds = (_recordingDuration % 60).toString().padLeft(2, '0');
      recordingTime.value = '$minutes:$seconds';
    });
  }

  /// Stops the recording timer and resets the display time
  void _stopTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    recordingTime.value = '00:00';
  }

  // MARK: - Recording Management

  /// Cleans up all recording resources
  /// Stops the timer, resets recording state, and disposes of the recorder
  Future<void> _cleanupAudioRecording() async {
    _stopTimer();
    isRecording.value = false;
    if (_audioRecorder != null) {
      await _audioRecorder?.dispose();
      _audioRecorder = null;
    }
  }

  /// Handles the complete audio recording process
  /// 1. Sets up the recorder
  /// 2. Checks permissions
  /// 3. Starts recording
  /// 4. Shows recording dialog
  /// 5. Returns the recorded file or null if canceled/error
  /// @param context The BuildContext for UI interactions
  /// @return File? The recorded audio file or null if canceled/error
  Future<File?> _recordAndReturnFile(BuildContext context) async {
    await _cleanupAudioRecording();
    _audioRecorder = AudioRecorder();
    String? recordedPath;
    bool dialogDismissed = false;

    try {
      // Check permissions
      final hasPermission = await _checkRecordingPermission(context);
      if (!hasPermission) return null;

      // Set up recording path
      final filePath = await _prepareRecordingPath();

      // Start recording
      await _startRecording(filePath);

      if (!context.mounted) return null;

      // Show recording dialog and get file path
      recordedPath = await _showRecordingDialog(context, dialogDismissed);
    } catch (e) {
      if (context.mounted) {
        _handleRecordingError(e, context);
      }

      if (!dialogDismissed) {
        await _cleanupAudioRecording();
      }
    }

    if (!context.mounted) return null;

    return (recordedPath != null && recordedPath.isNotEmpty)
        ? File(recordedPath)
        : null;
  }

  // MARK: - Helper Methods for Recording

  /// Verifies that the app has permission to record audio
  /// Shows a snackbar if permission is denied
  /// @param context The BuildContext for UI interactions
  /// @return bool True if permission granted, false otherwise
  Future<bool> _checkRecordingPermission(BuildContext context) async {
    final hasPermission = await _audioRecorder!.hasPermission();
    if (!hasPermission && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording permission not granted.')),
      );
    }
    return hasPermission;
  }

  /// Generates a unique path for saving the recording in temporary storage
  /// @return String The file path for saving the recording
  Future<String> _prepareRecordingPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
  }

  /// Starts the actual audio recording process
  /// 1. Configures and initiates the recording
  /// 2. Starts the timer
  /// 3. Updates UI state
  /// @param filePath The path where the recording will be saved
  Future<void> _startRecording(String filePath) async {
    await _audioRecorder!.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: filePath,
    );
    _startTimer();
    isRecording.value = true;
  }

  /// Shows a dialog with recording controls and timer
  /// Returns the path to the recorded file when stopped
  /// @param context The BuildContext for UI interactions
  /// @param dialogDismissed Reference to track if dialog was dismissed
  /// @return String? Path to the recorded file or null if canceled
  Future<String?> _showRecordingDialog(
    BuildContext context,
    bool dialogDismissed,
  ) async {
    // Use a completer to ensure we only complete once
    final completer = Completer<String?>();

    // Track if we're processing the stop action to prevent multiple taps
    bool isProcessingStop = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Recording..."),
              content: const RecordingTimer(),
              actions: [
                TextButton(
                  onPressed:
                      isProcessingStop
                          ? null
                          : () async {
                            if (!completer.isCompleted && !isProcessingStop) {
                              // Set processing flag to prevent multiple taps
                              setState(() => isProcessingStop = true);

                              dialogDismissed = true;
                              final path = await _audioRecorder?.stop();
                              await _cleanupAudioRecording();
                              completer.complete(path);

                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                  child: Text(isProcessingStop ? "Processing..." : "Stop"),
                ),
              ],
            );
          },
        );
      },
    );

    // Wait for the dialog to complete
    return await completer.future;
  }

  /// Handles errors during recording
  /// Updates error message state and shows a snackbar
  /// @param error The error that occurred
  /// @param context The BuildContext for UI interactions
  void _handleRecordingError(dynamic error, BuildContext context) {
    errorMessage.value = 'Error during recording: $error';
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage.value)));
    }
  }

  // MARK: - Public API Methods

  /// Records audio and sends it for speech-to-text processing
  /// 1. Records audio from the microphone
  /// 2. Saves the recorded file
  /// 3. Shows the audio in chat
  /// 4. Processes the audio with the backend service
  /// 5. Displays formatted results in chat
  /// @param context The BuildContext for UI interactions
  /// @return SpeechAnalysisResult? The analysis result or null if error/canceled
  Future<SpeechAnalysisResult?> sendAudioForSpeechToText(
    BuildContext context,
  ) async {
    // Prevent concurrent recording starts
    if (_isStartingRecording || isRecording.value) {
      debugPrint(
        'AudioController: Recording already in progress, ignoring request',
      );
      return null;
    }

    _isStartingRecording = true;

    debugPrint(
      'AudioController: sendAudioForSpeechToText called with context: $context',
    );

    // Record audio
    debugPrint('AudioController: Calling _recordAndReturnFile');
    File? audioFile;
    try {
      audioFile = await _recordAndReturnFile(context);
    } finally {
      _isStartingRecording = false;
    }

    if (audioFile == null) {
      debugPrint('AudioController: _recordAndReturnFile returned null');
      return null;
    }

    debugPrint('AudioController: Audio file obtained: ${audioFile.path}');

    try {
      // Save the recording to a permanent location
      final savedFilePath = await _saveAudioFile(audioFile);
      debugPrint('AudioController: Audio saved to: $savedFilePath');

      // Add the audio message to the chat - IMPORTANT: This shows the audio player
      ref.read(chatProvider.notifier).sendUserAudioMessage(savedFilePath);
      scrollToEnd();
      debugPrint(
        'AudioController: User audio message added to chat with path: $savedFilePath',
      );

      // Prepare UI for processing
      _showProcessingInChat("Processing audio for analysis");
      debugPrint('AudioController: Processing message shown in chat');

      // Process the audio
      debugPrint('AudioController: Processing audio file');
      final reply = await _processAudioFile(audioFile);
      debugPrint('AudioController: Audio processing complete');

      if (!context.mounted) {
        debugPrint('AudioController: Context no longer mounted');
        _handleNoServerResponse();
        return null;
      }

      if (reply == null) {
        debugPrint('AudioController: No reply received from server');
        _handleNoServerResponse();
        return null;
      }

      // Show formatted results (like the FileController does)
      debugPrint('AudioController: Showing formatted transcription result');
      _showFormattedTranscriptionResult(reply);
      return reply;
    } catch (e) {
      debugPrint('AudioController: Error processing audio: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing audio: $e')));
      }
      return null;
    }
  }

  /// Records audio for analysis - identical to speech-to-text but with different UI flow
  /// This method exists to provide a semantic distinction for the UI layer
  /// @param context The BuildContext for UI interactions
  /// @return SpeechAnalysisResult? The analysis result or null if error/canceled
  Future<SpeechAnalysisResult?> sendAudioForAnalysis(
    BuildContext context,
  ) async {
    // Recording is identical
    return await sendAudioForSpeechToText(context);
  }

  /// Saves a temporary audio file to permanent storage
  /// Creates a unique filename based on current timestamp
  /// @param audioFile The temporary audio file to save
  /// @return String The path to the saved file
  Future<String> _saveAudioFile(File audioFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = '${directory.path}/$fileName';

      // Copy the file to the permanent location
      final newFile = await audioFile.copy(filePath);
      debugPrint('Saved audio file to: $filePath');
      return newFile.path;
    } catch (e) {
      debugPrint('Error saving audio file: $e');
      // Return the original path if there was an error
      return audioFile.path;
    }
  }

  // MARK: - Helper Methods for Processing

  /// Shows processing status in the chat
  /// 1. Adds a message indicating processing
  /// 2. Shows a loading indicator
  /// @param message The message to display in chat
  void _showProcessingInChat(String message) {
    ref.read(chatProvider.notifier).sendTextMessage(message, true);
    scrollToEnd();
    ref.read(chatProvider.notifier).addLoadingMessage();
    scrollToEnd();
  }

  /// Sends the audio file to the backend for processing
  /// Uses ChatService to communicate with the API
  /// @param audioFile The audio file to process
  /// @return SpeechAnalysisResult? The analysis result or null if error
  Future<SpeechAnalysisResult?> _processAudioFile(File audioFile) async {
    return await chatService.sendSpeechToTextMessage(audioFile);
  }

  /// Handles cases where no response is received from the server
  /// Updates the loading message with an error
  void _handleNoServerResponse() {
    ref
        .read(chatProvider.notifier)
        .updateLoadingMessage("Error: No response from server");
    scrollToEnd();
  }

  /// Shows the formatted transcription result in the chat
  /// Uses the same formatting as FileController for consistency
  /// @param response The speech analysis result to display
  void _showFormattedTranscriptionResult(SpeechAnalysisResult response) {
    final formattedResponse = _formatSpeechResponse(response);
    ref
        .read(chatProvider.notifier)
        .updateLoadingMessage(
          formattedResponse,
          type: MessageType.speechToText,
        );
    scrollToEnd();
  }

  /// Formats the speech analysis response according to the required format
  /// Format: "Transcription: [text]\nSummary: [summary]\nSentiment: [sentiment]\nPrediction Value: [value]"
  /// @param response The SpeechAnalysisResult from the API
  /// @return String The formatted response text
  String _formatSpeechResponse(SpeechAnalysisResult response) {
    final transcription = response.transcription;
    final summary = response.summary ?? "No summary available";
    final sentiment = response.sentiment;
    final predictionValue = response.predictionValue.toStringAsFixed(2);

    return "Transcription: \"$transcription\"\nSummary: \"$summary\"\nSentiment: $sentiment\nPrediction Value: $predictionValue";
  }

  /// Handles audio response from the backend
  /// Adds the audio to the chat as a bot message
  /// @param audioData The audio data or file path
  /// @param context The BuildContext for UI interactions
  Future<void> handleAudioResponse(
    String audioData,
    BuildContext context,
  ) async {
    if (!context.mounted) return;
    debugPrint('AudioController: Received audio response, adding to chat');
    // Use sendBotAudioMessage to properly display audio in chat
    ref
        .read(chatProvider.notifier)
        .sendBotAudioMessage(
          audioData,
          message: "Audio response from assistant",
        );
    scrollToEnd();
  }
}
