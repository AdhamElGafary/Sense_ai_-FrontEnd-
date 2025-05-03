import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sense_ai/constants/api_constants.dart';
import 'package:sense_ai/models/chat_models.dart';

/// ChatService: Manages all API communication with the backend server
///
/// This service is responsible for sending data to the backend API endpoints
/// and handling responses. It supports multiple media types including:
/// - Text messages (for sentiment analysis)
/// - Audio recordings (for speech-to-text processing)
/// - Images (for emotion detection)
/// - Video files (for emotion analysis over time)
/// - Live video frames (for real-time emotion analysis)
///
/// Each method handles a specific type of request, manages file processing
/// and properly formats API payloads.
class ChatService {
  /// Dio HTTP client configured with appropriate timeouts
  /// Used for all API requests to ensure consistent behavior
  late final Dio _dio;

  /// Constructor
  ChatService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Sends a text message for sentiment analysis
  ///
  /// Takes a text input and sends it to the sentiment analysis endpoint.
  /// Returns a SentimentAnalysisResult with emotion scores and prediction.
  ///
  /// @param text The message text to analyze
  /// @returns SentimentAnalysisResult containing sentiment scores or null on failure
  Future<SentimentAnalysisResult?> sendTextMessage(String text) async {
    try {
      final response = await _dio.post(
        ApiConstants.sentimentAnalysis,
        data: {'text': text},
      );
      return SentimentAnalysisResult.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Sends an audio file for speech-to-text processing
  ///
  /// Takes an audio file (WAV format), performs validation checks, and
  /// sends it to the backend for speech-to-text processing.
  ///
  /// Includes comprehensive error handling and debugging to help
  /// identify issues with audio processing.
  ///
  /// @param audioFile A File object containing WAV audio to process
  /// @returns SpeechAnalysisResult with transcription and analysis or throws exception
  Future<SpeechAnalysisResult?> sendSpeechToTextMessage(File audioFile) async {
    // Verify file exists and has content
    if (!await audioFile.exists()) {
      throw Exception('Audio file not found at path: ${audioFile.path}');
    }

    final fileSize = await audioFile.length();
    if (fileSize <= 0) {
      throw Exception('Audio file is empty (0 bytes)');
    }

    final fileName = audioFile.path.split('/').last;

    // Use application/octet-stream content type for raw audio
    try {
      // Create multipart form data with octet-stream content type
      FormData formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: fileName,
          contentType: MediaType('application', 'octet-stream'),
        ),
      });

      // Send the request with appropriate timeouts
      final response = await _dio.post(
        ApiConstants.speechAnalysis,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
        ),
      );

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SpeechAnalysisResult.fromJson(response.data);
      }

      // If we get here, the request was not successful
      throw Exception('Server returned status code ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to process audio file: $e');
    }
  }

  /// Sends an image for emotion analysis
  ///
  /// Takes an image file, formats it for upload, and sends it to the
  /// emotion analysis endpoint for processing.
  ///
  /// @param imageFile A File object containing the image to analyze
  /// @returns EmotionAnalysisResult containing detected emotions or null on failure
  Future<EmotionAnalysisResult?> sendImageMessage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        'fileType': 'image',
      });
      final response = await _dio.post(
        ApiConstants.imageEmotion,
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      return EmotionAnalysisResult.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Sends a video file for emotion analysis over time
  ///
  /// Takes a video file, uploads it to the server, and processes it for
  /// emotion detection across multiple frames.
  ///
  /// Uses longer timeouts to accommodate larger file sizes and
  /// extended processing time.
  ///
  /// @param videoFile A File object containing the video to analyze
  /// @returns VideoAnalysisResult containing emotion timeline or null on failure
  Future<VideoAnalysisResult?> sendVideoMessage(File videoFile) async {
    try {
      final fileName = videoFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
        ),
        'fileType': 'video',
      });

      // Longer timeout for video uploads due to larger file size
      final response = await _dio.post(
        ApiConstants.videoAnalysis,
        data: formData,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 5),
        ),
      );
      return VideoAnalysisResult.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Sends a single video frame for real-time emotion analysis
  ///
  /// Part of the live video streaming functionality. Sends a captured
  /// frame along with session and timing information to enable
  /// continuous emotion tracking.
  ///
  /// @param sessionId Unique identifier for the streaming session
  /// @param timestamp The time position of this frame in the video stream
  /// @param frameFile A File object containing the image frame to analyze
  /// @returns VideoStreamResult with frame analysis or null on failure
  Future<VideoStreamResult?> sendLiveVideoFrame(
    String sessionId,
    double timestamp,
    File frameFile,
  ) async {
    try {
      final fileName = frameFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'session_id': sessionId,
        'timestamp': timestamp,
        'frame': await MultipartFile.fromFile(
          frameFile.path,
          filename: fileName,
        ),
      });
      final response = await _dio.post(
        ApiConstants.realtimeVideo,
        data: formData,
      );
      return VideoStreamResult.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Sends text for summarization
  ///
  /// Takes a potentially long text and requests a concise summary.
  /// Useful for condensing large blocks of text into key points.
  ///
  /// @param originalText The full text to be summarized
  /// @returns SummarizeResult containing the summary or null on failure
  Future<SummarizeResult?> sendSummarizeRequest(String originalText) async {
    try {
      // Calculate appropriate max_length based on input length
      // Count the number of words in the input text
      final wordCount =
          originalText.split(' ').where((s) => s.trim().isNotEmpty).length;

      // Set max_length to 50% of the input length, with minimum of 5 and maximum of 100
      final maxLength = (wordCount * 0.5).clamp(5, 100).toInt();

      final response = await _dio.post(
        ApiConstants.summarize,
        data: {
          'original_text': originalText,
          "min_length": maxLength ~/ 2, // Set min_length to half of max_length
          "max_length": maxLength,
        },
      );
      return SummarizeResult.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}
