import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'audio_helper.dart';

/// Saves a base64-encoded PDF string to a file and opens it.
Future<void> saveAndOpenPdf(
  String base64Pdf, {
  String fileName = "report.pdf",
}) async {
  try {
    final pdfBytes = base64Decode(base64Pdf);
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    final result = await OpenFile.open(filePath);
    debugPrint("Open PDF result: $result");
  } catch (e) {
    debugPrint("Error saving/opening PDF: $e");
  }
}

/// Translates URLs for use in emulators, fixing common connectivity issues
String translateEmulatorUrl(String url) {
  // For Android emulator: 10.0.2.2 is the special IP that routes to the host's localhost
  if (url.contains('10.0.2.2')) {
    return url.replaceAll('10.0.2.2', 'localhost');
  }

  // For iOS simulator: 127.0.0.1 should be used
  if (url.contains('localhost') && Platform.isIOS) {
    return url.replaceAll('localhost', '127.0.0.1');
  }

  // Handle backend URLs that might be using 127.0.0.1 but need to be 10.0.2.2 for Android emulator
  if ((url.contains('127.0.0.1') || url.contains('localhost')) &&
      Platform.isAndroid) {
    return url
        .replaceAll('127.0.0.1', '10.0.2.2')
        .replaceAll('localhost', '10.0.2.2');
  }

  return url;
}

/// Downloads and opens a PDF file.
Future<void> openPdfLink(String pdfUrl, BuildContext context) async {
  try {
    // Apply URL translation for emulators
    final translatedUrl = translateEmulatorUrl(pdfUrl);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing to download PDF...'),
        duration: Duration(seconds: 2),
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await downloadAndOpenPdfWithDio(translatedUrl, filePath, context);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening PDF: $e')));
    }
  }
}

/// Downloads and opens a PDF file using Dio.
Future<void> downloadAndOpenPdfWithDio(
  String url,
  String savePath,
  BuildContext context,
) async {
  CancelToken cancelToken = CancelToken();

  try {
    final dio = Dio();

    // Create a dismissible SnackBar with cancel button
    Widget progressWidget = Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(child: Text('Downloading PDF...')),
        ElevatedButton(
          onPressed: () {
            cancelToken.cancel("User cancelled the download");
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(60, 30),
            padding: EdgeInsets.zero,
          ),
          child: const Text('Cancel'),
        ),
      ],
    );

    if (!context.mounted) return;

    // Clear any existing SnackBars first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the progress SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: progressWidget,
        duration: const Duration(days: 1), // Very long, we'll dismiss manually
        behavior: SnackBarBehavior.fixed,
      ),
    );

    await dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).toStringAsFixed(0);
          debugPrint('Download progress: $progress%');
        }
      },
    );

    // Dismiss the progress SnackBar
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening PDF report...'),
        duration: Duration(seconds: 2),
      ),
    );
    await OpenFile.open(savePath);
  } catch (e) {
    debugPrint('Error downloading or opening PDF: $e');
    if (cancelToken.isCancelled) {
      debugPrint('Download was cancelled by user');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to open PDF: ${e.toString().substring(0, Math.min(e.toString().length, 100))}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

/// Downloads and opens an audio file from a URL.
Future<void> openAudioLink(String audioUrl, BuildContext context) async {
  try {
    // Apply URL translation for emulators
    final translatedUrl = translateEmulatorUrl(audioUrl);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing to download audio...'),
        duration: Duration(seconds: 2),
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

    // Use the audio player helper instead of Dio for better playback
    await downloadAndPlayAudioWithDialog(translatedUrl, filePath, context);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening audio: $e')));
    }
  }
}

/// Downloads audio and plays it in a custom dialog
Future<void> downloadAndPlayAudioWithDialog(
  String url,
  String savePath,
  BuildContext context,
) async {
  CancelToken cancelToken = CancelToken();

  try {
    final dio = Dio();

    // Create a dismissible SnackBar with cancel button
    Widget progressWidget = Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(child: Text('Downloading audio...')),
        ElevatedButton(
          onPressed: () {
            cancelToken.cancel("User cancelled the download");
            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size(60, 30),
            padding: EdgeInsets.zero,
          ),
          child: const Text('Cancel'),
        ),
      ],
    );

    if (!context.mounted) return;
    // Clear any existing SnackBars first
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the progress SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: progressWidget,
        duration: const Duration(days: 1), // Very long, we'll dismiss manually
        behavior: SnackBarBehavior.fixed,
      ),
    );

    await dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).toStringAsFixed(0);
          debugPrint('Download progress: $progress%');
        }
      },
    );

    // Dismiss the progress SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show our custom audio player dialog instead of using the system player
      final audioHelper = AudioPlayerHelper();
      await audioHelper.showAudioPlayerDialog(
        context,
        savePath,
        title: 'Audio Player',
      );
    }
  } catch (e) {
    debugPrint('Error downloading or playing audio: $e');
    if (cancelToken.isCancelled) {
      debugPrint('Download was cancelled by user');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to play audio: ${e.toString().substring(0, Math.min(e.toString().length, 100))}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

/// Saves a base64-encoded audio string to a file and opens it.
Future<void> saveAndOpenAudio(
  String audioData, {
  String fileName = "audio.wav",
  BuildContext? context,
}) async {
  try {
    // Check if the audioData is a URL or base64 data
    if (audioData.startsWith('http://') || audioData.startsWith('https://')) {
      // It's a URL, so download and open it
      if (context != null) {
        await openAudioLink(audioData, context);
      } else {
        // Fallback to direct download without UI feedback if no context
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/$fileName';

        final dio = Dio();
        await dio.download(translateEmulatorUrl(audioData), filePath);
        await OpenFile.open(filePath);
      }
    } else {
      // Assume it's base64 encoded data
      final audioBytes = base64Decode(audioData);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);

      if (context != null && context.mounted) {
        // Use our custom audio player
        final audioHelper = AudioPlayerHelper();
        await audioHelper.showAudioPlayerDialog(
          context,
          filePath,
          title: 'Audio Player',
        );
      } else {
        // Fallback to system player if no context
        final result = await OpenFile.open(filePath);
        debugPrint("Open Audio result: $result");
      }
    }
  } catch (e) {
    debugPrint("Error saving/opening audio: $e");
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening audio file: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// For math min function
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
