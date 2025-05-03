// A generic paginated response model
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List)
              .map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

// 1. Sentiment Analysis (Text)
class SentimentAnalysisResult {
  final int id;
  final String text;
  final double prediction;
  final String sentiment;
  final DateTime createdAt;

  SentimentAnalysisResult({
    required this.id,
    required this.text,
    required this.prediction,
    required this.sentiment,
    required this.createdAt,
  });

  factory SentimentAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SentimentAnalysisResult(
      id: json['id'] as int,
      text: json['text'] as String,
      prediction: (json['prediction'] as num).toDouble(),
      sentiment: json['sentiment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// 2. Emotion Analysis (Image)
class EmotionAnalysisResult {
  final String emotion;
  final double confidence;

  EmotionAnalysisResult({required this.emotion, required this.confidence});

  factory EmotionAnalysisResult.fromJson(Map<String, dynamic> json) {
    return EmotionAnalysisResult(
      emotion: json['emotion'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

// 3. Speech Analysis Result
class SpeechAnalysisResult {
  final int id;
  final String? audio;
  final String transcription;
  final String? summary;
  final String sentiment;
  final double predictionValue;
  final DateTime? createdAt;

  SpeechAnalysisResult({
    required this.id,
    this.audio,
    required this.transcription,
    this.summary,
    required this.sentiment,
    required this.predictionValue,
    this.createdAt,
  });

  factory SpeechAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SpeechAnalysisResult(
      id: json['id'] as int,
      audio: json['audio'] as String?,
      transcription: json['transcription'] as String,
      summary: json['summary'] as String?,
      sentiment: json['sentiment'] as String,
      predictionValue: (json['prediction_value'] as num).toDouble(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
    );
  }
}

// 4. Video Analysis Result
class VideoAnalysisResult {
  final int id;
  final String video;
  final String audioFile;
  final String pdfReport;
  final String dominantEmotion;
  final Map<String, dynamic> emotionPercentages;
  final Map<String, dynamic> emotionDurations;
  final int totalFrames;
  final double videoDuration;
  final int emotionTransitions;
  final double transitionRate;
  final String transcription;
  final String summary;
  final String sentiment;
  final double sentimentValue;
  final DateTime createdAt;

  VideoAnalysisResult({
    required this.id,
    required this.video,
    required this.audioFile,
    required this.pdfReport,
    required this.dominantEmotion,
    required this.emotionPercentages,
    required this.emotionDurations,
    required this.totalFrames,
    required this.videoDuration,
    required this.emotionTransitions,
    required this.transitionRate,
    required this.transcription,
    required this.summary,
    required this.sentiment,
    required this.sentimentValue,
    required this.createdAt,
  });

  factory VideoAnalysisResult.fromJson(Map<String, dynamic> json) {
    return VideoAnalysisResult(
      id: json['id'] as int,
      video: json['video'] as String,
      audioFile: json['audio_file'] as String,
      pdfReport: json['pdf_report'] as String,
      dominantEmotion: json['dominant_emotion'] as String,
      emotionPercentages: json['emotion_percentages'] as Map<String, dynamic>,
      emotionDurations: json['emotion_durations'] as Map<String, dynamic>,
      totalFrames: json['total_frames'] as int,
      videoDuration: (json['video_duration'] as num).toDouble(),
      emotionTransitions: json['emotion_transitions'] as int,
      transitionRate: (json['transition_rate'] as num).toDouble(),
      transcription: json['transcription'] as String,
      summary: json['summary'] as String,
      sentiment: json['sentiment'] as String,
      sentimentValue: (json['sentiment_value'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// 5. Summarize Result
class SummarizeResult {
  final int id;
  final String originalText;
  final String summary;
  final int? minLength;
  final int? maxLength;
  final DateTime createdAt;

  SummarizeResult({
    required this.id,
    required this.originalText,
    required this.summary,
    this.minLength,
    this.maxLength,
    required this.createdAt,
  });

  factory SummarizeResult.fromJson(Map<String, dynamic> json) {
    return SummarizeResult(
      id: json['id'] as int,
      originalText: json['original_text'] as String,
      summary: json['summary'] as String,
      minLength: json['min_length'] != null ? json['min_length'] as int : null,
      maxLength: json['max_length'] != null ? json['max_length'] as int : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// 6. Video Stream Result
class VideoStreamResult {
  final int id;
  final String sessionId;
  final String name;
  final DateTime createdAt;
  final DateTime? endedAt;
  final bool isRecorded;
  final String? videoFile;
  final String? dominantEmotion;
  final Map<String, dynamic> emotionData;
  final List<dynamic> frames; // Depending on your data format for frames.

  VideoStreamResult({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.createdAt,
    this.endedAt,
    required this.isRecorded,
    this.videoFile,
    this.dominantEmotion,
    required this.emotionData,
    required this.frames,
  });

  factory VideoStreamResult.fromJson(Map<String, dynamic> json) {
    return VideoStreamResult(
      id: json['id'] as int,
      sessionId: json['session_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      endedAt:
          json['ended_at'] != null
              ? DateTime.parse(json['ended_at'] as String)
              : null,
      isRecorded: json['is_recorded'] as bool,
      videoFile: json['video_file'] as String?,
      dominantEmotion: json['dominant_emotion'] as String?,
      emotionData: json['emotion_data'] as Map<String, dynamic>,
      frames: json['frames'] as List<dynamic>,
    );
  }
}
