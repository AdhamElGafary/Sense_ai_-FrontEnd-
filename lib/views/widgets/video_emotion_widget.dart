import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A widget that displays video emotion analysis data including
/// dominant emotion, percentages for each emotion, and durations
class VideoEmotionWidget extends StatelessWidget {
  final String dominantEmotion;
  final Map<String, double> emotionPercentages;
  final Map<String, double> emotionDurations;

  const VideoEmotionWidget({
    super.key,
    required this.dominantEmotion,
    required this.emotionPercentages,
    required this.emotionDurations,
  });

  @override
  Widget build(BuildContext context) {
    // Helper method to get color for an emotion
    Color getEmotionColor(String emotion) {
      switch (emotion) {
        case 'Happy':
          return Colors.green;
        case 'Sad':
          return Colors.blue;
        case 'Angry':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    // Calculate the percentage for the dominant emotion
    final dominantPercentage =
        emotionPercentages.containsKey(dominantEmotion)
            ? emotionPercentages[dominantEmotion]! / 100
            : 0.5;

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
          // Title for the Emotion Analysis
          Text(
            "Dominant Emotion: $dominantEmotion",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
          SizedBox(height: 10.h),

          // Emotion Percentages with Progress Bars
          Column(
            children:
                emotionPercentages.keys.map((emotion) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Emotion name
                        Text(
                          emotion,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Percentage value
                        Text(
                          "${emotionPercentages[emotion]!.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Progress bar
                        SizedBox(
                          width: 100.w,
                          child: LinearProgressIndicator(
                            value: emotionPercentages[emotion]! / 100,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              getEmotionColor(emotion),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),

          SizedBox(height: 10.h),

          // Emotion Durations
          Text(
            "Emotion Durations (seconds):",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
          Column(
            children:
                emotionDurations.keys.map((emotion) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          emotion,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "${emotionDurations[emotion]?.toStringAsFixed(2)} sec",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),

          SizedBox(height: 10.h),

          // Circular percentage indicator for dominant emotion
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Create a pie chart-like indicator with multiple sections
                SizedBox(
                  height: 80.h,
                  width: 80.h,
                  child: CustomPaint(
                    painter: EmotionPieChartPainter(
                      emotionPercentages: emotionPercentages,
                      getColorForEmotion: getEmotionColor,
                    ),
                  ),
                ),

                // White circle in the center for text
                Container(
                  height: 60.h,
                  width: 60.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${(dominantPercentage * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: getEmotionColor(dominantEmotion),
                          ),
                        ),
                        Text(
                          dominantEmotion,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing the emotion pie chart
class EmotionPieChartPainter extends CustomPainter {
  final Map<String, double> emotionPercentages;
  final Color Function(String) getColorForEmotion;

  EmotionPieChartPainter({
    required this.emotionPercentages,
    required this.getColorForEmotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create a list of emotions ordered by percentage (largest first)
    final sortedEmotions =
        emotionPercentages.keys.toList()..sort(
          (a, b) => emotionPercentages[b]!.compareTo(emotionPercentages[a]!),
        );

    // Filter out "Neutral" emotion if present
    final filteredEmotions =
        sortedEmotions.where((e) => e != "Neutral").toList();

    // Calculate total percentage (excluding Neutral)
    double totalPercentage = 0;
    for (final emotion in filteredEmotions) {
      totalPercentage += emotionPercentages[emotion]!;
    }

    // Start angle is at the top (negative pi/2)
    double startAngle = -pi / 2;

    // Draw each emotion sector
    for (final emotion in filteredEmotions) {
      final percentage = emotionPercentages[emotion]!;

      // Calculate the sweep angle based on the percentage of total
      // We use the full 360 degrees (2*pi radians)
      final sweepAngle = 2 * pi * (percentage / totalPercentage);

      // Create a paint object for this emotion
      final paint =
          Paint()
            ..color = getColorForEmotion(emotion)
            ..style = PaintingStyle.fill;

      // Draw the sector
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Update start angle for the next sector
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint
  }
}
