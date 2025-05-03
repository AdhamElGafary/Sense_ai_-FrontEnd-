import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A custom text field widget for auth screens with consistent styling
class CustomTextField extends StatelessWidget {
  /// Controller for the text field
  final TextEditingController controller;

  /// Hint text to display when the field is empty
  final String hintText;

  /// Icon to display at the start of the text field
  final IconData prefixIcon;

  /// Whether to obscure the text (for password fields)
  final bool obscureText;

  /// Optional widget to display at the end of the text field (e.g., visibility toggle)
  final Widget? suffixIcon;

  /// Validation function for the field
  final String? Function(String?)? validator;

  /// Optional keyboard type (defaults to text)
  final TextInputType keyboardType;

  /// Optional text capitalization
  final TextCapitalization textCapitalization;

  /// Optional auto-correction
  final bool autocorrect;

  /// Optional text input action (e.g., next, done)
  final TextInputAction? textInputAction;

  /// Optional on field submission callback
  final Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = false,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(prefixIcon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      ),
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
