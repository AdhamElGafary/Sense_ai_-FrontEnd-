import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter/material.dart';

class EmotionImageAnalysisWidget extends StatelessWidget {
  final String emotion;
  final double percentage;

  const EmotionImageAnalysisWidget({
    super.key,
    required this.emotion,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0), // Reduce padding to make it smaller
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          12.0,
        ), // Slightly smaller border radius
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      width: 200, // Limit the width of the card
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Emotion Analysis",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 6),

          // Custom image icon based on emotion (Happy, Sad, Neutral)
          Center(
            child: Image.asset(
              emotion == "Happy"
                  ? 'assets/happy.png'
                  : emotion == "Sad"
                  ? 'assets/sad.png'
                  : 'assets/neutral.png', // Neutral image if emotion is 'Neutral'
              width: 40, // Smaller image size
              height: 40, // Smaller image size
            ),
          ),
          Center(
            child: Text(
              emotion,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          SizedBox(height: 6),

          // Circular percentage indicator
          Center(
            child: CircularPercentIndicator(
              radius: 40.0, // Smaller circle
              lineWidth: 6.0, // Thinner progress line
              percent: percentage,
              center: Text("${(percentage * 100).toInt()}%"),
              progressColor:
                  emotion == "Happy"
                      ? Colors.green
                      : emotion == "Sad"
                      ? Colors.blue
                      : Colors.grey, // Gray for Neutral
            ),
          ),

          SizedBox(height: 10),

          // Emotion bars for Happy, Sad, Neutral
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              EmotionBar(
                label: "Happy",
                color: Colors.green,
                percentage: percentage,
              ),
              EmotionBar(
                label: "Sad",
                color: Colors.blue,
                percentage: 1 - percentage,
              ),
              EmotionBar(label: "Neutral", color: Colors.grey, percentage: 0.2),
            ],
          ),
        ],
      ),
    );
  }
}

class EmotionBar extends StatelessWidget {
  final String label;
  final Color color;
  final double percentage;

  const EmotionBar({
    super.key,
    required this.label,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40, // Smaller width for the bars
          height: 4, // Smaller height for the bars
          color: color.withOpacity(0.5),
        ),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
