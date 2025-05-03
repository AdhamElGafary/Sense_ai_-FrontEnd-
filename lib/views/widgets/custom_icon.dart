import 'package:flutter/material.dart';

Widget customImageButton({
  required Key key,
  required String imagePath,
  required Color imageColor,
  final double? imageSize, // You can use 20.sp or a fixed size value
  final EdgeInsets? padding,
  final BoxConstraints? constraints,
  required VoidCallback onPressed,
}) {
  return GestureDetector(
    key: key,
    onTap: onPressed,
    child: Container(
      padding: padding,
      constraints: constraints,
      child: Image.asset(
        imagePath,

        width: imageSize,
        height: imageSize,
        color: imageColor,
      ),
    ),
  );
}
