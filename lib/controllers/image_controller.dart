import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'base_controller.dart';
import 'file_controller.dart';

/// Controller for handling image capture and processing
class ImageController extends BaseController {
  // Image picker instance.
  final ImagePicker _imagePicker = ImagePicker();

  ImageController({required super.ref, required super.scrollController});

  Future<void> sendImageFromCamera(BuildContext context) async {
    final XFile? imageFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (!context.mounted) return;
    if (imageFile != null) {
      final file = File(imageFile.path);
      final fileController = FileController(
        ref: ref,
        scrollController: scrollController,
      );
      await fileController.sendFile(file, "image", context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image captured.')));
      }
    }
  }

  Future<void> sendImageFromGallery(BuildContext context) async {
    final XFile? imageFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (!context.mounted) return;
    if (imageFile != null) {
      final file = File(imageFile.path);
      final fileController = FileController(
        ref: ref,
        scrollController: scrollController,
      );
      await fileController.sendFile(file, "image", context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected.')));
      }
    }
  }
}
