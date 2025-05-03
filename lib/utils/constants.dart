import 'package:flutter/material.dart';

final customGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      // #000C7C with ~53% alpha => 0.53 * 255 ≈ 135 => 0x87
      Color(0x87000C7C),
      Color(0xFF050133), // 100% opacity
      Color(0xFF050133), // extend the same color to the end
    ],
    stops: [0.0, 0.34, 1.0],
  ),
);
