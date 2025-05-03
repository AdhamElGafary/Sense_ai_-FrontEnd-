import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sense_ai/constants/api_constants.dart';

/// RealtimeEmotionService: Manages session-based real-time emotion detection API requests
///
/// This service handles the complete lifecycle of a real-time emotion analysis session:
/// - Starting a new session
/// - Processing individual camera frames
/// - Ending the session and getting summary statistics
///
/// It maintains session state (session ID and frame counters) and provides
/// both file-based and base64-encoded methods for sending frame data.
class RealtimeEmotionService {
  /// Dio HTTP client for API requests
  late final Dio _dio;

  /// Current active session ID
  String? sessionId;

  /// Frame counter for the current session
  int frameNumber = 0;

  /// Flag to track if a session is being processed (starting/ending)
  bool _isProcessing = false;

  /// Debug mode flag for additional logging
  final bool debug;

  /// Constructor
  RealtimeEmotionService({this.debug = false}) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    // Add logging interceptor if debug mode is enabled
    if (debug) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (Object object) {
            debugPrint('REALTIME SERVICE: $object');
          },
        ),
      );
    }
  }

  /// Starts a new emotion analysis session
  ///
  /// Creates a new session on the server and stores the session ID
  /// for subsequent frame processing requests.
  ///
  /// @returns Session ID if successful, null otherwise
  Future<String?> startSession() async {
    // Prevent starting a new session if one is already active or being processed
    if (sessionId != null) {
      debugPrint('Session already active with ID: $sessionId');
      return sessionId;
    }

    if (_isProcessing) {
      debugPrint('Another session operation is in progress, please wait');
      return null;
    }

    _isProcessing = true;

    if (debug) debugPrint('Starting new emotion analysis session');

    try {
      final response = await _dio.post(
        ApiConstants.realtimeStart,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          // Add shorter timeout for session operations
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Reset session state
        sessionId = response.data['session_data']['session_id'];
        frameNumber = 0;

        if (debug) debugPrint('Session started with ID: $sessionId');
        return sessionId;
      } else {
        if (debug) {
          debugPrint('Failed to start session: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error starting session: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a camera frame using file upload
  ///
  /// Sends an image file to the server with the current session ID
  /// and frame number for emotion analysis.
  ///
  /// @param imageFile The camera frame as a File
  /// @returns Analysis result or null on failure
  Future<Map<String, dynamic>?> processFrame(File imageFile) async {
    if (sessionId == null) {
      debugPrint('No active session. Call startSession() first.');
      return null;
    }

    // Don't process frames if we're in the middle of starting/ending a session
    if (_isProcessing) {
      if (debug) debugPrint('Session operation in progress, skipping frame');
      return null;
    }

    try {
      if (debug) debugPrint('Processing frame #$frameNumber');

      // Check if the file exists and is readable
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist: ${imageFile.path}');
        return null;
      }

      // Create multipart form data
      FormData formData = FormData.fromMap({
        'session_id': sessionId!,
        'frame_number': frameNumber.toString(),
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'frame_$frameNumber.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      // Send the request
      final response = await _dio.post(
        ApiConstants.realtimeProcess,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      // Increment frame counter
      frameNumber++;

      if (response.statusCode == 200) {
        if (debug) debugPrint('Frame processed successfully');
        return response.data;
      } else {
        debugPrint('Failed to process frame: ${response.statusCode}');
        debugPrint('Response: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
      return null;
    }
  }

  /// Process a camera frame using base64 encoding
  ///
  /// Converts the image to base64 and sends it as JSON payload
  /// instead of as a file. This can be more efficient for small images
  /// or when multipart requests are problematic.
  ///
  /// @param imageBytes Raw image bytes to process
  /// @returns Analysis result or null on failure
  Future<Map<String, dynamic>?> processFrameBase64(Uint8List imageBytes) async {
    if (sessionId == null) {
      debugPrint('No active session. Call startSession() first.');
      return null;
    }

    try {
      if (debug) debugPrint('Processing frame #$frameNumber (base64)');

      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Send the request
      final response = await _dio.post(
        ApiConstants.realtimeProcess,
        data: {
          'session_id': sessionId,
          'frame_number': frameNumber,
          'frame_data': base64Image,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      // Increment frame counter
      frameNumber++;

      if (response.statusCode == 200) {
        if (debug) debugPrint('Frame processed successfully');
        return response.data;
      } else {
        debugPrint('Failed to process frame: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
      return null;
    }
  }

  /// End the current emotion analysis session
  ///
  /// Notifies the server that the session is complete and retrieves
  /// the final analysis results and statistics.
  ///
  /// @returns Session summary data or null on failure
  Future<Map<String, dynamic>?> endSession() async {
    if (sessionId == null) {
      debugPrint('No active session to end');
      return null;
    }

    // Prevent concurrent operations on the session
    if (_isProcessing) {
      debugPrint('Another session operation is in progress, please wait');
      return null;
    }

    _isProcessing = true;
    final String currentSessionId =
        sessionId!; // Store for use even if state is reset

    try {
      if (debug) debugPrint('Ending session: $currentSessionId');

      // Set a timeout to ensure we don't get stuck waiting for the server
      final response = await _dio.post(
        ApiConstants.realtimeEnd,
        data: {'session_id': currentSessionId},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      // Clear session state immediately regardless of response
      sessionId = null;
      frameNumber = 0;

      if (response.statusCode == 200) {
        if (debug) debugPrint('Session ended successfully');
        return response.data;
      } else {
        debugPrint('Failed to end session: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error ending session: $e');

      // Clear session state even on error
      sessionId = null;
      frameNumber = 0;

      rethrow; // Rethrow to allow caller to handle the error
    } finally {
      _isProcessing = false;
    }
  }

  /// Retrieve statistics for a completed session
  ///
  /// Fetches detailed analytics for a past session by ID.
  /// Useful for viewing results of previous sessions.
  ///
  /// @param sessionId ID of the session to retrieve
  /// @returns Session statistics or null on failure
  Future<Map<String, dynamic>?> getSessionStatistics(String sessionId) async {
    try {
      if (debug) debugPrint('Fetching statistics for session: $sessionId');

      final response = await _dio.get(
        '${ApiConstants.realtimeStatistics}/$sessionId/',
      );

      if (response.statusCode == 200) {
        if (debug) debugPrint('Statistics retrieved successfully');
        return response.data;
      } else {
        debugPrint('Failed to get statistics: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return null;
    }
  }

  /// Cancel the current session if needed
  ///
  /// Resets the session state without contacting the server.
  /// Use this when you need to clean up local state without
  /// formally ending the session.
  void cancelSession() {
    if (sessionId != null) {
      debugPrint('Locally canceling session: $sessionId');
      sessionId = null;
      frameNumber = 0;
    }
    _isProcessing = false; // Reset processing flag to prevent deadlocks
  }
}
