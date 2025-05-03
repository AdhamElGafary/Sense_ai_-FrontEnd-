import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';

/// A custom button widget for auth screens with consistent styling
class CustomButton extends StatelessWidget {
  /// Text to display on the button
  final String text;

  /// Callback function when button is pressed
  final VoidCallback? onPressed;

  /// Whether the button is in a loading state
  final bool isLoading;

  /// Width of the button (defaults to full width)
  final double? width;

  /// Height of the button (defaults to 56.h)
  final double? height;

  /// Background color of the button (defaults to white)
  final Color? backgroundColor;

  /// Text color of the button (defaults to primary color)
  final Color? textColor;

  /// Loading indicator color (defaults to primary color)
  final Color? loadingColor;

  /// Button elevation (defaults to 5)
  final double elevation;

  /// Font size for the button text
  final double? fontSize;

  /// Radius for button corners
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.loadingColor,
    this.elevation = 5,
    this.fontSize,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Colors.white,
          foregroundColor: textColor ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 16.r),
          ),
          elevation: elevation,
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      loadingColor ?? AppColors.primary,
                    ),
                  ),
                )
                : Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize ?? 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }
}
