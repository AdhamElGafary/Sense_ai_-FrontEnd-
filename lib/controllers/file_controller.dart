import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../utils/file_helper.dart';
import '../utils/audio_helper.dart';
import 'base_controller.dart';

/// Controller for handling file uploads and processing
/// Manages the entire file lifecycle - from selection to processing and display
/// Supports multiple file types: image, video, audio, and documents
class FileController extends BaseController {
  FileController({required super.ref, required super.scrollController});

  // MARK: - File Upload Methods

  /// Sends a file (image, video, audio) message to be processed
  /// Shows appropriate UI feedback during the upload process
  /// @param file The file to send
  /// @param fileType The type of file (image, video, audio)
  /// @param context The BuildContext for UI interactions
  Future<void> sendFile(
    File file,
    String fileType,
    BuildContext context,
  ) async {
    final fileName = file.path.split('/').last;

    // Show user message and loading indicator
    _showUploadingMessage(fileType, fileName);

    // Process different file types with specialized handlers
    switch (fileType) {
      case "image":
        await _processImageFile(file);
        break;
      case "video":
        await _processVideoFile(file, context);
        break;
      case "audio":
        await _processAudioFile(file, context);
        break;
    }

    // Ensure chat scrolls to latest message after processing
    scrollToEnd();
  }

  // MARK: - File Type Processing Helpers

  /// Shows an uploading message in the chat to provide user feedback
  void _showUploadingMessage(String fileType, String fileName) {
    ref
        .read(chatProvider.notifier)
        .sendTextMessage("Sending $fileType.. $fileName", true);
    scrollToEnd();
    ref.read(chatProvider.notifier).addLoadingMessage();
    scrollToEnd();
  }

  /// Processes image files by sending them to the emotion analysis API
  /// @param file The image file to process
  Future<void> _processImageFile(File file) async {
    final imageResponse = await chatService.sendImageMessage(file);
    _handleImageResponse(imageResponse);
    scrollToEnd();
  }

  /// Handles the response from the image emotion analysis API
  /// Creates an EmotionAnalysisWidget for displaying the result visually
  /// Also provides a text fallback version for compatibility
  /// @param imageResponse The response from the API
  void _handleImageResponse(dynamic imageResponse) {
    if (imageResponse != null) {
      // Format a text response version for compatibility
      final textFallback = _formatEmotionResponse(imageResponse);

      // Update the chat with the emotion analysis result as text
      // The EmotionAnalysisWidget will be built in the chat bubble when displaying this message
      ref
          .read(chatProvider.notifier)
          .updateLoadingMessage(textFallback, type: MessageType.image);
    } else {
      ref
          .read(chatProvider.notifier)
          .updateLoadingMessage("No response from server");
    }
  }

  /// Format emotion analysis response according to requirements
  /// Format: "Emotion: [emotion]\nConfidence: [percentage]%\nMood: [mood]"
  /// @param response The EmotionAnalysisResult from the API
  /// @return The formatted response string
  String _formatEmotionResponse(EmotionAnalysisResult response) {
    final confidencePercent = (response.confidence * 100).toStringAsFixed(2);
    final emotion = response.emotion;
    final mood = _determineMood(emotion);

    return "Emotion: $emotion\nConfidence: $confidencePercent%\nMood: $mood";
  }

  /// Determine if an emotion is positive, negative, or neutral
  /// @param emotion The emotion string from the API
  /// @return "Positive", "Negative", or "Neutral"
  String _determineMood(String emotion) {
    final negativeEmotions = ['Sad', 'Angry', 'Fearful', 'Disgusted'];
    final positiveEmotions = ['Happy', 'Surprised', 'Neutral'];

    if (negativeEmotions.contains(emotion)) {
      return 'Negative';
    } else if (positiveEmotions.contains(emotion)) {
      return 'Positive';
    } else {
      return 'Neutral';
    }
  }

  /// Processes video files by sending them to the video analysis API
  /// @param file The video file to process
  /// @param context The BuildContext for UI interactions
  Future<void> _processVideoFile(File file, BuildContext context) async {
    final videoResponse = await chatService.sendVideoMessage(file);
    if (!context.mounted) return;
    await _handleVideoResponse(videoResponse);
    scrollToEnd();
  }

  /// Handles the response from the video analysis API
  /// Updates the loading message with video emotion analysis
  /// Also provides the PDF report and audio file as separate messages
  /// @param videoResponse The response from the API
  Future<void> _handleVideoResponse(dynamic videoResponse) async {
    if (videoResponse != null) {
      // Format the response for the EmotionVedioAnalysisWidget
      // The widget expects this specific format to parse properly
      final formattedResponse = _formatVideoResponse(videoResponse);

      // Update the loading message with video emotion analysis
      // Use MessageType.video to ensure it's displayed with the EmotionVedioAnalysisWidget
      ref
          .read(chatProvider.notifier)
          .updateLoadingMessage(formattedResponse, type: MessageType.video);

      // Process additional files (PDF report and audio) - these remain unchanged
      await _processVideoAdditionalFiles(videoResponse);
    } else {
      ref
          .read(chatProvider.notifier)
          .updateLoadingMessage("No response from server");
    }
  }

  /// Format video analysis response for the EmotionVedioAnalysisWidget
  /// Format must contain the dominant emotion and emotion percentages/durations
  /// @param response The VideoAnalysisResult from the API
  /// @return The formatted response string that can be parsed by the widget
  String _formatVideoResponse(VideoAnalysisResult response) {
    final dominantEmotion = response.dominantEmotion;

    // Format emotion durations as a string
    List<String> durationParts = [];
    response.emotionDurations.forEach((emotion, duration) {
      // Convert to seconds with one decimal place
      final seconds = double.parse(duration.toString()).toStringAsFixed(1);
      durationParts.add("$emotion - ${seconds}s");
    });
    final emotionDurations = durationParts.join(", ");

    // Format emotion percentages as a string
    List<String> percentageParts = [];
    response.emotionPercentages.forEach((emotion, percentage) {
      final percent = double.parse(percentage.toString()).toStringAsFixed(1);
      percentageParts.add("$emotion - $percent%");
    });
    final emotionPercentages = percentageParts.join(", ");

    return "Dominant Emotion: $dominantEmotion\nEmotion Durations: $emotionDurations\nEmotion Percentages: $emotionPercentages";
  }

  /// Processes additional files from the video analysis response
  /// This includes the PDF report and the audio file
  /// @param videoResponse The response from the API
  Future<void> _processVideoAdditionalFiles(dynamic videoResponse) async {
    try {
      // Fix PDF URL for emulator environment
      final pdfUrl = translateEmulatorUrl(videoResponse.pdfReport);
      final audioUrl = translateEmulatorUrl(videoResponse.audioFile);

      // Send PDF message first - explicitly using MessageType.pdf to avoid video type
      ref.read(chatProvider.notifier).sendPdfMessage(pdfUrl);
      scrollToEnd();

      // Add a small delay to prevent overwhelming the UI thread
      await Future.delayed(const Duration(milliseconds: 500));

      // Then handle audio message separately - explicitly using MessageType.downloadAudio to avoid video type
      debugPrint(
        'FileController: Adding audio message from video response: $audioUrl',
      );
      ref
          .read(chatProvider.notifier)
          .sendBotAudioMessage(audioUrl, message: "Processed audio from video");
      scrollToEnd();
    } catch (e) {
      debugPrint('FileController: Error processing video additional files: $e');
      ref
          .read(chatProvider.notifier)
          .sendTextMessage("Error processing video attachments: $e", false);
      scrollToEnd();
    }
  }

  /// Processes audio files by sending them to the speech analysis API
  /// @param file The audio file to process
  /// @param context The BuildContext for UI interactions
  Future<void> _processAudioFile(File file, BuildContext context) async {
    final audioResponse = await chatService.sendSpeechToTextMessage(file);
    if (!context.mounted) return;
    _handleAudioResponse(audioResponse);
    scrollToEnd(); // Ensure we scroll to end after processing audio response
  }

  /// Handles the response from the speech analysis API
  /// Formats the response according to the specified format
  /// @param audioResponse The response from the API
  void _handleAudioResponse(dynamic audioResponse) {
    if (audioResponse != null) {
      // Format the speech analysis response according to requirements
      final formattedResponse = _formatSpeechResponse(audioResponse);
      ref
          .read(chatProvider.notifier)
          .updateLoadingMessage(
            formattedResponse,
            type: MessageType.speechToText,
          );
    } else {
      ref
          .read(chatProvider.notifier)
          .updateLoadingMessage("No response from server");
    }
  }

  /// Format speech analysis response according to requirements
  /// Format: "Transcription: [transcription]\nSummary: [summary]\nSentiment: [sentiment]\nPrediction Value: [value]"
  /// @param response The SpeechAnalysisResult from the API
  /// @return The formatted response string
  String _formatSpeechResponse(SpeechAnalysisResult response) {
    final transcription = response.transcription;
    final summary = response.summary ?? "No summary available";
    final sentiment = response.sentiment;
    final predictionValue = response.predictionValue.toStringAsFixed(2);

    return "Transcription: \"$transcription\"\nSummary: \"$summary\"\nSentiment: $sentiment\nPrediction Value: $predictionValue";
  }

  // MARK: - File Picker Methods

  /// Determines the FilePicker type based on the file type string
  /// @param fileType The type of file to pick (image, video, audio)
  /// @return The FileType enum value for the FilePicker
  FileType _getFilePickerType(String fileType) {
    switch (fileType) {
      case 'audio':
        return FileType.audio;
      case 'video':
        return FileType.video;
      case 'image':
        return FileType.image;
      default:
        return FileType.any;
    }
  }

  /// Opens the file picker for the user to select a file
  /// @param context The BuildContext for UI interactions
  /// @param fileType The type of file to pick (image, video, audio)
  Future<void> pickFile(BuildContext context, String fileType) async {
    // Determine file type for picker
    final type = _getFilePickerType(fileType);

    // Show file picker
    final result = await FilePicker.platform.pickFiles(type: type);

    if (!context.mounted) return;

    // Process selected file or show cancel message
    if (result != null && result.files.single.path != null) {
      await _processSelectedFile(result, fileType, context);
    } else {
      _showFileSelectionCancelled(context);
    }
  }

  /// Processes the selected file from the file picker
  /// @param result The FilePickerResult containing the selected file
  /// @param fileType The type of file that was picked
  /// @param context The BuildContext for UI interactions
  Future<void> _processSelectedFile(
    FilePickerResult result,
    String fileType,
    BuildContext context,
  ) async {
    final file = File(result.files.single.path!);
    await sendFile(file, fileType, context);
  }

  /// Shows a snackbar message when file selection is cancelled
  /// @param context The BuildContext for UI interactions
  void _showFileSelectionCancelled(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('File selection cancelled.')));
  }

  // MARK: - File Opening Methods

  /// Handles opening PDF files using the PDF viewer
  /// @param pdfUrl The URL or file path of the PDF to open
  /// @param context The BuildContext for UI interactions
  Future<void> openPdf(String pdfUrl, BuildContext context) async {
    try {
      await openPdfLink(pdfUrl, context);
    } catch (e) {
      if (context.mounted) {
        _showFileOpenError('PDF', e, context);
      }
    }
  }

  /// Handles opening audio files with the improved audio player
  /// @param audioUrl The URL or file path of the audio to open
  /// @param context The BuildContext for UI interactions
  Future<void> openAudio(String audioUrl, BuildContext context) async {
    try {
      // Use saveAndOpenAudio which now uses our custom player
      await saveAndOpenAudio(
        audioUrl,
        fileName: 'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
        context: context,
      );
    } catch (e) {
      if (context.mounted) {
        _showFileOpenError('audio', e, context);
      }
    }
  }

  /// Plays audio directly with custom player dialog
  /// @param filePath The file path of the audio to play
  /// @param context The BuildContext for UI interactions
  Future<void> playAudioWithDialog(
    String filePath,
    BuildContext context,
  ) async {
    try {
      final audioHelper = AudioPlayerHelper();
      await audioHelper.showAudioPlayerDialog(
        context,
        filePath,
        title: 'Audio Player',
      );
    } catch (e) {
      if (context.mounted) {
        _showFileOpenError('audio', e, context);
      }
    }
  }

  /// Shows a snackbar message when file opening fails
  /// @param fileType The type of file that failed to open
  /// @param error The error that occurred
  /// @param context The BuildContext for UI interactions
  void _showFileOpenError(
    String fileType,
    dynamic error,
    BuildContext context,
  ) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening $fileType: $error')),
      );
    }
  }
}
