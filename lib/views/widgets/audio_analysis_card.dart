import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioAnalysis {
  final String transcription;
  final String sentiment;
  final double predictionValue;

  AudioAnalysis({
    required this.transcription,
    required this.sentiment,
    required this.predictionValue,
  });

  factory AudioAnalysis.fromString(String message) {
    String transcription = '';
    String sentiment = '';
    double predictionValue = 0.0;

    try {
      final lines = message.split('\n');
      if (lines.length >= 3) {
        final transcriptionLine = lines[0];
        transcription = transcriptionLine
            .split(':')[1]
            .trim()
            .replaceAll('"', '');

        final sentimentLine = lines[2];
        sentiment = sentimentLine.split(':')[1].trim();

        final predictionLine = lines[3];
        final predictionText = predictionLine.split(':')[1].trim();
        predictionValue = double.parse(predictionText);
      }
    } catch (e) {
      print('Error parsing audio analysis data: $e');
    }

    return AudioAnalysis(
      transcription: transcription,
      sentiment: sentiment,
      predictionValue: predictionValue,
    );
  }
}

class AudioAnalysisMessageWidget extends StatelessWidget {
  final String message;
  final bool isUser;

  const AudioAnalysisMessageWidget({
    super.key,
    required this.isUser,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final audioAnalysis = AudioAnalysis.fromString(message);

    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue[400] : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transcription Section
          Text(
            'Transcription',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isUser ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            audioAnalysis.transcription,
            style: TextStyle(
              fontSize: 14.sp,
              color: isUser ? Colors.white : Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),

          // Sentiment Section
          Row(
            children: [
              Icon(
                audioAnalysis.sentiment == 'Negative'
                    ? Icons.sentiment_very_dissatisfied
                    : Icons.sentiment_very_satisfied,
                color:
                    audioAnalysis.sentiment == 'Negative'
                        ? Colors.red
                        : Colors.green,
                size: 20.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'Sentiment: ${audioAnalysis.sentiment}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Prediction Value Section
          Row(
            children: [
              Text(
                'Prediction: ',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${(audioAnalysis.predictionValue * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
