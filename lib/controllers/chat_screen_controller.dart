import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_controller.dart';
import 'file_controller.dart';
import 'image_controller.dart';
import 'text_controller.dart';
import 'video_controller.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

/// ChatScreenController: Primary controller that coordinates all chat functionality
///
/// This controller manages the chat screen UI and delegates specialized operations
/// to dedicated controllers for text, file, audio, video, and image handling.
/// It implements a facade pattern to provide a unified API for the chat interface
/// while keeping internal implementations modular and maintainable.
///
/// Key responsibilities:
/// - Manages chat UI state through specialized controllers
/// - Coordinates scrolling behavior for chat messages
/// - Implements hold-to-record audio functionality
/// - Handles error states and user feedback
class ChatScreenController {
  /// Reference to the Riverpod state management system
  final WidgetRef ref;

  /// Controller for scrolling the chat view to show latest messages
  final ScrollController scrollController;

  /// Service for API communication with the backend
  final ChatService _chatService = ChatService();

  /// Public getter for the text controller to access its methods
  TextController get textController => _textController;

  // Specialized controllers for different media types and operations
  late final TextController _textController;
  late final FileController _fileController;
  late final AudioController _audioController;
  late final VideoController _videoController;
  late final ImageController _imageController;

  /// Storage for active recording session data
  /// Contains the recorder instance and timing information
  Map<String, dynamic>? _recordingData;

  /// Constructor initializes all specialized controllers
  /// Each controller receives the ref and scrollController for state management
  ChatScreenController({required this.ref, required this.scrollController}) {
    // Initialize specialized controllers
    _textController = TextController(
      ref: ref,
      scrollController: scrollController,
    );
    _fileController = FileController(
      ref: ref,
      scrollController: scrollController,
    );
    _audioController = AudioController(
      ref: ref,
      scrollController: scrollController,
    );
    _videoController = VideoController(
      ref: ref,
      scrollController: scrollController,
    );
    _imageController = ImageController(
      ref: ref,
      scrollController: scrollController,
    );
  }

  //--------------------------------------------------------------------
  // TEXT MESSAGING METHODS
  //--------------------------------------------------------------------

  /// Sends a text message from the user to the chat
  /// Delegates to the TextController and ensures chat scrolls to show message
  Future<void> sendText(String text, BuildContext context) async {
    await _textController.sendText(text, context);
    scrollToEnd();
  }

  /// Sends a text summarization request
  /// Delegates to the TextController and ensures chat scrolls to latest message
  Future<void> sendSummarizeRequest(String text, BuildContext context) async {
    await _textController.sendSummarizeRequest(text, context);
    scrollToEnd();
  }

  //--------------------------------------------------------------------
  // FILE HANDLING METHODS
  //--------------------------------------------------------------------

  /// Handles picking and sending files from device storage
  /// Adds appropriate scrolling behavior to keep UI up-to-date
  Future<void> pickFile(BuildContext context, String fileType) async {
    await _fileController.pickFile(context, fileType);
    scrollToEnd();
    // Add delayed scroll to handle UI updates after file processing
    Future.delayed(const Duration(milliseconds: 500), () {
      scrollToEnd();
    });
  }

  //--------------------------------------------------------------------
  // AUDIO FUNCTIONALITY METHODS
  //--------------------------------------------------------------------

  /// Handles selecting and sending audio files for speech-to-text analysis
  /// This is for pre-recorded audio, not live recording
  Future<void> sendAudioForSpeechToText(BuildContext context) async {
    await _audioController.sendAudioForSpeechToText(context);
    scrollToEnd();
    // Add delayed scroll to handle UI updates
    Future.delayed(const Duration(milliseconds: 500), () {
      scrollToEnd();
    });
  }

  //--------------------------------------------------------------------
  // VIDEO FUNCTIONALITY METHODS
  //--------------------------------------------------------------------

  /// Starts the live video feed analysis process
  /// Captures and analyzes video frames for emotion detection
  Future<void> startLiveVideoAnalysis(BuildContext context) async {
    await _videoController.startLiveVideoAnalysis(context);
    scrollToEnd();
  }

  /// Stops the live video analysis and cleans up resources
  Future<void> stopLiveVideoAnalysis() =>
      _videoController.stopLiveVideoAnalysis();

  /// Returns the current active camera name (e.g., "Front" or "Back")
  String getActiveCameraName() => _videoController.getActiveCameraName();

  /// Returns the name of the alternate camera for switching
  String getAlternateCameraName() => _videoController.getAlternateCameraName();

  /// Switches between front and back cameras during live video analysis
  Future<void> switchCamera(BuildContext context) =>
      _videoController.switchCamera(context);

  //--------------------------------------------------------------------
  // IMAGE FUNCTIONALITY METHODS
  //--------------------------------------------------------------------

  /// Captures an image using the device camera and sends for analysis
  Future<void> sendImageFromCamera(BuildContext context) async {
    await _imageController.sendImageFromCamera(context);
    scrollToEnd();
    // Add delayed scroll to handle UI updates
    Future.delayed(const Duration(milliseconds: 500), () {
      scrollToEnd();
    });
  }

  /// Selects an image from the device gallery and sends for analysis
  Future<void> sendImageFromGallery(BuildContext context) async {
    await _imageController.sendImageFromGallery(context);
    scrollToEnd();
    // Add delayed scroll to handle UI updates
    Future.delayed(const Duration(milliseconds: 500), () {
      scrollToEnd();
    });
  }

  //--------------------------------------------------------------------
  // HOLD-TO-RECORD AUDIO FUNCTIONALITY
  // These methods implement a custom recording experience with real-time
  // feedback and error handling
  //--------------------------------------------------------------------

  /// Starts recording audio using the device microphone
  ///
  /// This method:
  /// 1. Checks for existing recordings to prevent overlap
  /// 2. Verifies recording permissions
  /// 3. Creates a temporary WAV file with optimized settings
  /// 4. Updates UI state to indicate recording is in progress
  ///
  /// Returns true if recording started successfully, false otherwise
  Future<bool> startRecording(BuildContext context) async {
    print("ChatScreenController: Start Recording called");
    try {
      // Audio controller doesn't expose all the methods we need directly
      // So we'll implement the recording logic directly here

      // Create recorder and check if already recording
      if (_audioController.isRecording.value) {
        print("ChatScreenController: Already recording");
        return false;
      }

      // Initialize recorder
      final recorder = AudioRecorder();

      // Check permission
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording permission not granted.')),
        );
        return false;
      }

      // Get temporary directory directly instead of through AudioController
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      print("ChatScreenController: Recording to file: $filePath");

      // UPDATED: Configure WAV format with very standard settings for Django compatibility
      // Django often uses 8kHz mono PCM as a baseline format
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav, // Standard WAV format
          bitRate: 8000, // 8kbps - Very basic rate
          sampleRate: 8000, // 8kHz - Standard minimum for speech
          numChannels: 1, // Mono - Simplest channel layout
        ),
        path: filePath,
      );
      print(
        "ChatScreenController: Started recording with Django-compatible WAV settings",
      );

      // Store recorder reference in a property for later use
      _recordingData = {'recorder': recorder, 'startTime': DateTime.now()};

      // Set recording state
      _audioController.isRecording.value = true;

      return true;
    } catch (e) {
      print("ChatScreenController: Error starting recording: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }

      // Clean up
      await _cleanupRecording();
      return false;
    }
  }

  /// Cleans up recording resources when recording is completed or canceled
  ///
  /// This helper method ensures proper release of the recorder instance
  /// and updates the recording state to inactive
  Future<void> _cleanupRecording() async {
    if (_recordingData != null && _recordingData!['recorder'] != null) {
      await (_recordingData!['recorder'] as AudioRecorder).dispose();
      _recordingData = null;
    }
    _audioController.isRecording.value = false;
  }

  /// Stops the active audio recording and processes the result
  ///
  /// This method:
  /// 1. Stops any active recording and retrieves the file path
  /// 2. Verifies the audio file exists and has valid content
  /// 3. Copies the recording to permanent storage
  /// 4. Sends recording to backend for processing if send=true
  /// 5. Updates UI with results or error messages
  ///
  /// @param context The BuildContext for UI operations
  /// @param send Whether to send the recording for processing (true)
  ///        or discard it (false)
  Future<void> stopRecording(BuildContext context, bool send) async {
    print("ChatScreenController: Stop Recording called with send: $send");
    try {
      if (!_audioController.isRecording.value || _recordingData == null) {
        print("ChatScreenController: No recording in progress");
        return;
      }

      // Stop recording and get file path
      final recorder = _recordingData!['recorder'] as AudioRecorder;
      final path = await recorder.stop();
      print("ChatScreenController: Recording stopped, file at: $path");

      // Clean up recording resources
      await _cleanupRecording();

      // If path is null, empty or we're not sending, just return
      if (path == null || path.isEmpty || !send) {
        print("ChatScreenController: Recording discarded or failed");
        return;
      }

      final audioFile = File(path);

      // Enhanced debugging for the audio file
      print(
        "ChatScreenController: Audio file size: ${await audioFile.length()} bytes",
      );
      print(
        "ChatScreenController: Audio file exists: ${await audioFile.exists()}",
      );

      // Debug the file headers (first 50 bytes) to verify WAV format
      try {
        if (await audioFile.exists() && await audioFile.length() > 50) {
          final bytes = await audioFile.openRead(0, 50).toList();
          final headerBytes = bytes.expand((x) => x).take(50).toList();
          final header = String.fromCharCodes(
            headerBytes.where((b) => b >= 32 && b <= 126),
          );
          print("ChatScreenController: Audio file header: $header");
          print("ChatScreenController: Raw header bytes: $headerBytes");

          // Check if it starts with RIFF (WAV format identifier)
          if (!header.contains("RIFF") || !header.contains("WAVE")) {
            print(
              "ChatScreenController: WARNING - File doesn't appear to be a valid WAV file!",
            );
          } else {
            print("ChatScreenController: Confirmed WAV format header");
          }
        }
      } catch (headerError) {
        print("ChatScreenController: Error reading file header: $headerError");
      }

      try {
        // Save the recording to a permanent location
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
        final filePath = '${directory.path}/$fileName';
        final savedFile = await audioFile.copy(filePath);
        print("ChatScreenController: Audio saved to: ${savedFile.path}");
        print(
          "ChatScreenController: Saved audio file size: ${await savedFile.length()} bytes",
        );

        // Verify file exists
        if (!await savedFile.exists()) {
          print("ChatScreenController: ERROR - Saved file doesn't exist!");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: Created audio file not found')),
            );
          }
          return;
        }

        // --- RESTORE ORIGINAL UI FLOW BUT PREVENT DUPLICATE API CALLS ---
        // Use the local variable for better code readability
        final chatNotifier = ref.read(chatProvider.notifier);

        // 1. Add the audio message to the chat (visual only, skip API processing)
        print("ChatScreenController: Adding audio message to chat UI");
        chatNotifier.sendUserAudioMessage(
          savedFile.path,
          skipApiProcessing: true, // This prevents any automatic API processing
        );
        scrollToEnd();

        // 2. Show processing message
        print("ChatScreenController: Adding processing message");
        chatNotifier.sendTextMessage("Processing audio for analysis", true);
        scrollToEnd();

        // Add delayed scroll to ensure processing message is visible
        Future.delayed(const Duration(milliseconds: 300), () {
          scrollToEnd();
        });

        // 3. Add loading message
        print("ChatScreenController: Adding loading message");
        chatNotifier.addLoadingMessage();
        scrollToEnd();

        // 4. NOW make the single API call ourselves with detailed error handling
        print(
          "ChatScreenController: Sending WAV audio to backend API (single controlled request)",
        );
        print("ChatScreenController: File path: ${savedFile.path}");
        print(
          "ChatScreenController: File size: ${await savedFile.length()} bytes",
        );

        // Debug information about the ChatService
        print(
          "ChatScreenController: Using ChatService for API call: ${_chatService.runtimeType}",
        );

        try {
          // Log the request about to be made
          print(
            "ChatScreenController: About to call sendSpeechToTextMessage...",
          );

          final reply = await _chatService.sendSpeechToTextMessage(savedFile);

          print(
            "ChatScreenController: API Response received successfully: $reply",
          );

          if (!context.mounted || reply == null) {
            print(
              "ChatScreenController: No valid response from server (null reply)",
            );
            chatNotifier.updateLoadingMessage("Error: No response from server");
            scrollToEnd();
            return;
          }

          // Format and show the result
          final formattedResponse = _formatSpeechResponse(reply);

          chatNotifier.updateLoadingMessage(
            formattedResponse,
            type: MessageType.speechToText,
          );
          scrollToEnd();

          // Add additional scroll after a delay to ensure UI has updated
          Future.delayed(const Duration(milliseconds: 500), () {
            scrollToEnd();
          });
        } catch (apiError) {
          print("ChatScreenController: API error: $apiError");

          // More detailed error information
          print("ChatScreenController: Error type: ${apiError.runtimeType}");
          print("ChatScreenController: Error details: $apiError");

          if (context.mounted) {
            String errorMessage = "Error processing audio: $apiError";

            // Provide more user-friendly error message with troubleshooting info
            if (apiError.toString().contains("400") ||
                apiError.toString().contains("Bad Request")) {
              errorMessage =
                  "Server could not process the audio. Please try again with a shorter recording (under 30 seconds) or make sure you're in a quiet environment.";
              print(
                "ChatScreenController: Bad request detected, providing user-friendly error message",
              );
            } else if (apiError.toString().contains(
              "Failed to upload audio file",
            )) {
              errorMessage =
                  "Could not upload the audio file to the server. Please check your internet connection and try again.";
              print(
                "ChatScreenController: Audio file upload failed, providing connection troubleshooting message",
              );
            } else if (apiError.toString().contains("Connection")) {
              errorMessage =
                  "Connection error. Please check your internet connection and server status.";
              print(
                "ChatScreenController: Network connectivity issue detected",
              );
            }

            chatNotifier.updateLoadingMessage(errorMessage);
            scrollToEnd();

            // Add delayed scroll to ensure UI updates are complete
            Future.delayed(const Duration(milliseconds: 500), () {
              scrollToEnd();
            });
          }
        }
      } catch (e) {
        print("ChatScreenController: Error processing audio: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving audio file: $e')),
          );

          // Add error message to chat and scroll
          ref
              .read(chatProvider.notifier)
              .updateLoadingMessage("Error saving audio file: $e");
          scrollToEnd();

          // Add delayed scroll to ensure UI updates are complete
          Future.delayed(const Duration(milliseconds: 500), () {
            scrollToEnd();
          });
        }
      }
    } catch (e) {
      print("ChatScreenController: Error stopping recording: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing audio: $e')));

        // Add error message to chat and scroll
        final chatNotifier = ref.read(chatProvider.notifier);
        chatNotifier.addLoadingMessage();
        scrollToEnd();
        chatNotifier.updateLoadingMessage("Error processing audio: $e");
        scrollToEnd();

        // Add delayed scroll to ensure UI updates are complete
        Future.delayed(const Duration(milliseconds: 500), () {
          scrollToEnd();
        });
      }
      await _cleanupRecording();
    }
  }

  /// Helper method to scroll the chat to the most recent message
  ///
  /// This ensures that new messages are visible to the user
  /// Uses a smooth animation for better user experience
  void scrollToEnd() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Formats the speech analysis response for display in the chat
  ///
  /// Creates a user-friendly string containing:
  /// - The transcribed text
  /// - A summary of the content
  /// - The detected sentiment
  /// - Confidence score
  String _formatSpeechResponse(SpeechAnalysisResult response) {
    final transcription = response.transcription;
    final summary = response.summary ?? "No summary available";
    final sentiment = response.sentiment;
    final predictionValue = response.predictionValue.toStringAsFixed(2);

    return "Transcription: \"$transcription\"\nSummary: \"$summary\"\nSentiment: $sentiment\nPrediction Value: $predictionValue";
  }
}
