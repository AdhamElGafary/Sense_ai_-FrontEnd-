import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String imagePath;
  final double size;

  const CustomAvatar({super.key, required this.imagePath, this.size = 16.0});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      clipBehavior: Clip.none,
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
