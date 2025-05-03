import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A widget that displays the app logo with color effects
/// to make it blend better with the app's color scheme
class AppLogo extends StatelessWidget {
  /// Size of the logo, defaults to medium
  final LogoSize size;

  /// Whether to use special effects for the logo on dark backgrounds
  final bool useDarkModeEffects;

  const AppLogo({
    super.key,
    this.size = LogoSize.medium,
    this.useDarkModeEffects = true,
  });

  @override
  Widget build(BuildContext context) {
    // Size based on the enum
    double width;
    double height;

    switch (size) {
      case LogoSize.small:
        width = 80.w;
        height = 80.h;
        break;
      case LogoSize.medium:
        width = 100.w;
        height = 100.h;
        break;
      case LogoSize.large:
        width = 150.w;
        height = 150.h;
        break;
    }

    // Create container with subtle effects to enhance the logo
    return Container(
      width: width,
      height: height,
      decoration:
          useDarkModeEffects
              ? BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.transparent,
                //     blurRadius: 15,
                //     spreadRadius: 2,
                //   ),
                // ],
              )
              : null,
      child: Hero(
        tag: 'app_logo',
        child: Image.asset(
          fit: BoxFit.cover,
          'assets/sense_logo.png',
          width: width,
          height: height,
        ),
      ),
    );
  }
}

/// Enum for logo size options
enum LogoSize { small, medium, large }
