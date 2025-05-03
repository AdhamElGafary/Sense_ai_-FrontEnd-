import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;

Future<String> processCameraImageToJpeg(CameraImage image) async {
  try {
    final int width = image.width;
    final int height = image.height;
    final imglib.Image convertedImage = imglib.Image(
      width: width,
      height: height,
    );

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    final int uvRowStride = planeU.bytesPerRow;
    final int uvPixelStride = planeU.bytesPerRow ~/ ((width + 1) >> 1);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * planeY.bytesPerRow + x;
        final int Y = planeY.bytes[yIndex];

        final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        final int U = planeU.bytes[uvIndex];
        final int V = planeV.bytes[uvIndex];

        int r = (Y + (1.370705 * (V - 128))).round();
        int g = (Y - (0.337633 * (U - 128)) - (0.698001 * (V - 128))).round();
        int b = (Y + (1.732446 * (U - 128))).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        convertedImage.setPixelRgb(x, y, r, g, b);
      }
    }

    final jpeg = imglib.encodeJpg(convertedImage, quality: 75);
    return base64Encode(jpeg);
  } catch (e) {
    return "";
  }
}
