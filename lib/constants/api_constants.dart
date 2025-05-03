/// API Constants for the Analyzer app
class ApiConstants {
  /// Base URL for API
  // For physical devices, use your computer's actual IP address instead of localhost/127.0.0.1
  // For emulator use 10.0.2.2 instead of localhost/127.0.0.1

  // IMPORTANT: "localhost" in a mobile app refers to the device itself, not your development machine
  // For Android emulator, use 10.0.2.2 to connect to the host machine
  static const String baseUrl = "http://192.168.1.8:8000/api";
  //for me "http://192.168.1.27:8000/api"
  // If on a physical device, uncomment and use your computer's IP address:
  // static const String baseUrl = "http://192.168.x.x:8000/api";

  /// API Endpoints

  // Sentiment analysis endpoint for text processing
  static const String sentimentAnalysis = "$baseUrl/sentiment/analysis/";

  // Image emotion analysis endpoint
  static const String imageEmotion = "$baseUrl/emotion/analyze/";

  // Speech analysis endpoint for audio processing
  // Note: This endpoint specifically expects 'audio' field in multipart form data
  static const String speechAnalysis = "$baseUrl/speech/analyze/";

  // Video analysis endpoint for emotional analysis of videos
  static const String videoAnalysis = "$baseUrl/emotion-video/analyses/";

  // Text summarization endpoint
  static const String summarize = "$baseUrl/summarize/summaries/";

  // Realtime video streaming endpoint
  static const String realtimeVideo = "$baseUrl/realtime-video/streams/";

  // New real-time emotion detection endpoints
  static const String realtimeStart = "$baseUrl/realtime-video/start/";
  static const String realtimeProcess = "$baseUrl/realtime-video/process/";
  static const String realtimeEnd = "$baseUrl/realtime-video/end/";
  static const String realtimeStatistics =
      "$baseUrl/realtime-video/statistics/";

  // Authentication endpoints
  static const String login = "$baseUrl/users/login/";
  static const String register = "$baseUrl/users/register/";
  static const String logout = "$baseUrl/users/logout/";
  static const String currentUser = "$baseUrl/users/me/";
}
