import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../providers/live_streaming_provider.dart';
import '../utils/frame_processor.dart';
import 'base_controller.dart';
import 'file_controller.dart';

/// Controller for handling video streaming and processing
class VideoController extends BaseController {
  // Live video streaming fields.
  CameraController? _cameraController;
  bool isLiveStreaming = false;
  List<CameraDescription>? _availableCameras;
  int _currentCameraIndex = 0;
  // In production, _sessionId should be obtained from the backend.
  String? _sessionId;

  VideoController({required super.ref, required super.scrollController});

  Future<void> startLiveVideoAnalysis(BuildContext context) async {
    _availableCameras ??= await availableCameras();
    if (_availableCameras!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No cameras available.')));
      }
      return;
    }
    _cameraController = CameraController(
      _availableCameras![_currentCameraIndex],
      ResolutionPreset.medium,
    );
    try {
      await _cameraController!.initialize();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error initializing camera: $e')));
      return;
    }
    _sessionId ??= "test-session";
    ref.read(liveStreamingProvider.notifier).state = true;
    isLiveStreaming = true;
    Dio dio = Dio();
    await _cameraController!.startImageStream((CameraImage image) async {
      if (!ref.read(liveStreamingProvider)) return;
      final encodedFrame = await processCameraImageToJpeg(image);
      if (encodedFrame.isNotEmpty) {
        final bytes = base64.decode(encodedFrame);
        final timestamp = DateTime.now().millisecondsSinceEpoch / 1000;
        FormData formData = FormData.fromMap({
          'session_id': _sessionId,
          'timestamp': timestamp,
          'frame': MultipartFile.fromBytes(bytes, filename: 'frame.jpg'),
        });
        try {
          await dio.post(ApiConstants.realtimeVideo, data: formData);
        } catch (e) {
          debugPrint("Error sending frame: $e");
        }
      }
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live video analysis started.')),
    );
  }

  Future<void> stopLiveVideoAnalysis() async {
    ref.read(liveStreamingProvider.notifier).state = false;
    isLiveStreaming = false;
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
  }

  Future<void> switchCamera(BuildContext context) async {
    _availableCameras ??= await availableCameras();
    if (_availableCameras!.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No alternative camera found.')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
    }
    _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras!.length;
    if (!context.mounted) return;
    await startLiveVideoAnalysis(context);
  }

  Future<void> pickRecordedVideo(BuildContext context) async {
    final fileController = FileController(
      ref: ref,
      scrollController: scrollController,
    );
    await fileController.pickFile(context, "video");
  }

  // Camera helper methods
  String getActiveCameraName() {
    if (_availableCameras != null && _availableCameras!.isNotEmpty) {
      final activeCamera = _availableCameras![_currentCameraIndex];
      switch (activeCamera.lensDirection) {
        case CameraLensDirection.front:
          return "Front Camera";
        case CameraLensDirection.back:
          return "Rear Camera";
        case CameraLensDirection.external:
          return "External Camera";
      }
    }
    return "";
  }

  String getAlternateCameraName() {
    if (_availableCameras != null && _availableCameras!.isNotEmpty) {
      final currentDirection =
          _availableCameras![_currentCameraIndex].lensDirection;
      CameraDescription? alternate;
      for (final camera in _availableCameras!) {
        if (camera.lensDirection != currentDirection) {
          alternate = camera;
          break;
        }
      }
      if (alternate != null) {
        switch (alternate.lensDirection) {
          case CameraLensDirection.front:
            return "Front Camera";
          case CameraLensDirection.back:
            return "Rear Camera";
          case CameraLensDirection.external:
            return "External Camera";
        }
      }
    }
    return "No alternative";
  }
}
