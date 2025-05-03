import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sense_ai/views/widgets/audio_analysis_card.dart';
import 'package:sense_ai/views/widgets/breathind_dot.dart';
import 'package:sense_ai/views/widgets/chat_audio_player.dart';
import 'package:sense_ai/views/widgets/emotion_analysis_card.dart';
import 'package:sense_ai/views/widgets/video_emotion_widget.dart';
import '../../models/chat_message.dart';
import '../../utils/file_helper.dart';

/// Base class for all message content widgets
abstract class MessageContentWidget extends StatelessWidget {
  final bool isUser;

  const MessageContentWidget({super.key, required this.isUser});
}

/// Widget for loading state messages
class LoadingMessageWidget extends MessageContentWidget {
  const LoadingMessageWidget({super.key, required super.isUser});

  @override
  Widget build(BuildContext context) {
    return const BreathingDot(color: Colors.grey);
  }
}

/// Widget for PDF messages
class PdfMessageWidget extends MessageContentWidget {
  final String? pdfData;

  const PdfMessageWidget({
    super.key,
    required super.isUser,
    required this.pdfData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (pdfData != null) {
          try {
            await openPdfLink(pdfData!, context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Could not open PDF: $e")));
            }
          }
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red),
          SizedBox(width: 8.w),
          Text(
            "Download PDF Report",
            style: TextStyle(
              fontSize: 16.sp,
              color: isUser ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for audio messages with error handling
class AudioMessageWidget extends MessageContentWidget {
  final String? audioData;
  final String message;
  final bool isDownload;

  const AudioMessageWidget({
    super.key,
    required super.isUser,
    required this.audioData,
    required this.message,
    this.isDownload = false,
  });

  @override
  Widget build(BuildContext context) {
    if (audioData == null || audioData!.isEmpty) {
      return Text(
        message.isEmpty ? "Audio message" : message,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 16.sp,
        ),
      );
    }

    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show a label for user recordings
          if (isUser && !isDownload) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, color: Colors.white70, size: 16.sp),
                SizedBox(width: 4.w),
                Text(
                  "Your recording",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
          // For downloaded audio, add a custom label
          if (isDownload) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.audiotrack,
                  color: isUser ? Colors.white70 : Colors.green,
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  "Audio message",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isUser ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
          // The actual audio player
          ChatAudioPlayer(audioUrl: audioData!, isUserMessage: isUser),
        ],
      );
    } catch (e) {
      debugPrint("AudioMessageWidget: Error creating audio player: $e");
      return _buildAudioErrorWidget(context, e);
    }
  }

  Widget _buildAudioErrorWidget(BuildContext context, dynamic error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: isUser ? Colors.white70 : Colors.red,
              size: 24.w,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                "Audio couldn't be loaded",
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isUser ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          "Error loading audio player: ${error.toString()}",
          style: TextStyle(
            fontSize: 12.sp,
            color: isUser ? Colors.white70 : Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (audioData != null && audioData!.isNotEmpty) ...[
          SizedBox(height: 8.h),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isUser ? Colors.white.withOpacity(0.3) : Colors.blue[400],
              foregroundColor: isUser ? Colors.white : Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              visualDensity: VisualDensity.compact,
              textStyle: TextStyle(fontSize: 12.sp),
            ),
            onPressed: () async {
              try {
                await saveAndOpenAudio(
                  audioData!,
                  fileName:
                      'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
                  context: context,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Still couldn't load audio: $e")),
                  );
                }
              }
            },
          ),
        ],
      ],
    );
  }
}

/// Widget for speech-to-text messages
class SpeechToTextMessageWidget extends MessageContentWidget {
  final String message;

  const SpeechToTextMessageWidget({
    super.key,
    required super.isUser,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }
}

/// Widget for text messages with optional summarize button
class TextMessageWidget extends MessageContentWidget {
  final String message;
  final Function(String, BuildContext)? onSummarize;

  const TextMessageWidget({
    super.key,
    required super.isUser,
    required this.message,
    this.onSummarize,
  });

  @override
  Widget build(BuildContext context) {
    final bool needsSummarize =
        isUser &&
        !message.contains("Sending") &&
        !message.contains("Processing") &&
        message.length > 15 &&
        onSummarize != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16.sp,
          ),
        ),
        if (needsSummarize) ...[
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.summarize, size: 16),
              label: const Text('Summarize'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isUser ? Colors.white.withOpacity(0.3) : Colors.blue[400],
                foregroundColor: isUser ? Colors.white : Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                visualDensity: VisualDensity.compact,
                textStyle: TextStyle(fontSize: 12.sp),
              ),
              onPressed: () {
                if (onSummarize != null) {
                  onSummarize!(message, context);
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget for image emotion analysis messages
class ImageEmotionMessageWidget extends MessageContentWidget {
  final String message;

  const ImageEmotionMessageWidget({
    super.key,
    required super.isUser,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // Default values in case parsing fails
    String emotion = 'Happy';
    double confidence = 0.5;

    try {
      // Parse the message text to extract emotion and confidence
      final lines = message.split('\n');
      if (lines.length >= 2) {
        // Parse primary emotion
        final emotionLine = lines[0];
        emotion = emotionLine.split(':')[1].trim();

        // Parse confidence
        final confidenceLine = lines[1];
        final confidenceText = confidenceLine.split(':')[1].trim();
        final confidencePercent = double.parse(
          confidenceText.replaceAll('%', ''),
        );
        confidence =
            confidencePercent / 100; // Convert from percentage to fraction
      }
    } catch (e) {
      debugPrint('Error parsing emotion data: $e');
      // In case of parsing error, just show the raw message
      return Text(
        message,
        style: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 16.sp,
        ),
      );
    }

    // Return the EmotionAnalysisWidget with the parsed data
    return EmotionImageAnalysisWidget(emotion: emotion, percentage: confidence);
  }
}

/// Widget for video emotion analysis messages
class VideoEmotionMessageWidget extends MessageContentWidget {
  final String message;

  const VideoEmotionMessageWidget({
    super.key,
    required super.isUser,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // Default values in case parsing fails
    String dominantEmotion = 'Neutral';
    Map<String, double> emotionPercentages = {
      'Happy': 50.0,
      'Sad': 30.0,
      'Angry': 20.0,
    };
    Map<String, double> emotionDurations = {
      'Happy': 2.5,
      'Sad': 1.5,
      'Angry': 1.0,
    };

    // Debug the incoming message
    debugPrint('Video Emotion Message to parse: $message');

    try {
      // Parse the message text to extract dominant emotion, durations and percentages
      final lines = message.split('\n');
      debugPrint('Message has ${lines.length} lines');

      if (lines.length >= 2) {
        // Parse dominant emotion
        final dominantLine = lines[0]; // "Dominant Emotion: Happy"
        debugPrint('Dominant line: $dominantLine');
        if (dominantLine.contains(':')) {
          dominantEmotion = dominantLine.split(':')[1].trim();
          debugPrint('Extracted dominant emotion: $dominantEmotion');
        }

        // Parse emotion durations
        final durationsLine = lines.firstWhere(
          (line) => line.startsWith('Emotion Durations:'),
          orElse: () => '',
        );

        if (durationsLine.isNotEmpty) {
          debugPrint('Durations line: $durationsLine');
          final durationsText = durationsLine.split(':')[1].trim();
          final durationsParts = durationsText.split(', ');

          emotionDurations = {}; // Clear default values

          for (final part in durationsParts) {
            final emotionParts = part.split(' - ');
            if (emotionParts.length == 2) {
              final emotion = emotionParts[0].trim();
              final durationText = emotionParts[1].replaceAll('s', '').trim();
              debugPrint('Parsing duration for $emotion: $durationText');
              final duration = double.tryParse(durationText);
              if (duration != null) {
                emotionDurations[emotion] = duration;
              }
            }
          }
          debugPrint('Parsed durations: $emotionDurations');
        }

        // Parse emotion percentages
        final percentagesLine = lines.firstWhere(
          (line) => line.startsWith('Emotion Percentages:'),
          orElse: () => '',
        );

        if (percentagesLine.isNotEmpty) {
          debugPrint('Percentages line: $percentagesLine');
          final percentagesText = percentagesLine.split(':')[1].trim();
          final percentagesParts = percentagesText.split(', ');

          emotionPercentages = {}; // Clear default values

          for (final part in percentagesParts) {
            final emotionParts = part.split(' - ');
            if (emotionParts.length == 2) {
              final emotion = emotionParts[0].trim();
              final percentageText = emotionParts[1].replaceAll('%', '').trim();
              debugPrint('Parsing percentage for $emotion: $percentageText');
              final percentage = double.tryParse(percentageText);
              if (percentage != null) {
                emotionPercentages[emotion] = percentage;
              }
            }
          }
          debugPrint('Parsed percentages: $emotionPercentages');
        }
      }

      // Use the extracted VideoEmotionWidget
      return VideoEmotionWidget(
        dominantEmotion: dominantEmotion,
        emotionPercentages: emotionPercentages,
        emotionDurations: emotionDurations,
      );
    } catch (e) {
      debugPrint('Error parsing video emotion data: $e');
      // In case of error, show a simplified error widget
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        width: 250.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Video Emotion Analysis",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              "Failed to parse video data. Error: $e",
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              "Raw message: $message",
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
  }
}

/// Factory class for creating message content widgets based on message type
class MessageContentFactory {
  static MessageContentWidget createContentWidget({
    required ChatMessage message,
    required Function(String, BuildContext)? onSummarize,
  }) {
    final bool isUser = message.isUser;

    switch (message.messageType) {
      case MessageType.loading:
        return LoadingMessageWidget(isUser: isUser);

      case MessageType.image:
        return ImageEmotionMessageWidget(
          isUser: isUser,
          message: message.message,
        );

      case MessageType.video:
        return VideoEmotionMessageWidget(
          isUser: isUser,
          message: message.message,
        );

      case MessageType.pdf:
        return PdfMessageWidget(isUser: isUser, pdfData: message.fileData);

      case MessageType.downloadAudio:
        return AudioMessageWidget(
          isUser: isUser,
          audioData: message.fileData,
          message: message.message,
          isDownload: true,
        );

      case MessageType.audio:
        return AudioMessageWidget(
          isUser: isUser,
          audioData: message.fileData,
          message: message.message,
        );

      case MessageType.speechToText:
        return AudioEmotionMessageWidget(
          isUser: isUser,
          message: message.message,
        );

      default:
        return TextMessageWidget(
          isUser: isUser,
          message: message.message,
          onSummarize: onSummarize,
        );
    }
  }
}

class AudioEmotionMessageWidget extends MessageContentWidget {
  final String message;

  const AudioEmotionMessageWidget({
    super.key,
    required super.isUser,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // Return the EmotionAnalysisWidget with the parsed data
    return AudioAnalysisMessageWidget(isUser: isUser, message: message);
  }
}
