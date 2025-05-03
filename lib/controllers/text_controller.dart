import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import 'base_controller.dart';

/// Controller for handling text-based interactions like sending messages and summarization
/// Manages all text processing features including sentiment analysis and summarization
/// Communicates with backend APIs through ChatService and updates UI through ChatProvider
class TextController extends BaseController {
  TextController({required super.ref, required super.scrollController});

  /// Sends a text message for sentiment analysis
  /// 1. Adds the user's message to the chat
  /// 2. Shows a loading indicator
  /// 3. Sends the message to the backend for sentiment analysis
  /// 4. Updates the chat with the formatted response
  /// @param text The text message to analyze
  /// @param context The BuildContext for error handling
  Future<void> sendText(String text, BuildContext context) async {
    // Add user message to chat
    ref.read(chatProvider.notifier).sendTextMessage(text, true);
    scrollToEnd();

    // Show loading indicator
    ref.read(chatProvider.notifier).addLoadingMessage();
    scrollToEnd();

    // Send to backend for processing
    final reply = await chatService.sendTextMessage(text);

    // Handle response or error
    if (!context.mounted) return;
    if (reply == null) {
      ref
          .read(chatProvider.notifier)
          .updateLoadingMessage("Error: No response from server");
      scrollToEnd();
      return;
    }

    // Format the sentiment response according to requirements
    final formattedResponse = _formatSentimentResponse(reply);
    ref.read(chatProvider.notifier).updateLoadingMessage(formattedResponse);
    scrollToEnd();
  }

  /// Formats the sentiment analysis response according to the required format
  /// Format: "Sentiment: [sentiment]\nConfidence: [percentage]%"
  /// @param response The SentimentAnalysisResult from the API
  /// @return The formatted response string
  String _formatSentimentResponse(SentimentAnalysisResult response) {
    final confidencePercent = (response.prediction * 100).toStringAsFixed(2);
    return "Sentiment: ${response.sentiment}\nConfidence: $confidencePercent%";
  }

  /// Sends a request to summarize text
  /// 1. Shows a loading indicator
  /// 2. Sends the original text to the backend for summarization
  /// 3. Updates the chat with the formatted summary response
  /// @param text The text to summarize
  /// @param context The BuildContext for error handling
  Future<void> sendSummarizeRequest(String text, BuildContext context) async {
    try {
      // Show loading indicator
      ref.read(chatProvider.notifier).addLoadingMessage();
      scrollToEnd();

      // Send to backend for processing
      final reply = await chatService.sendSummarizeRequest(text);

      // Handle response or error
      if (!context.mounted) return;
      if (reply == null) {
        ref
            .read(chatProvider.notifier)
            .updateLoadingMessage("Error: No response from server");
        scrollToEnd();
        return;
      }

      // Format the summary response according to requirements
      final formattedResponse = _formatSummaryResponse(reply);
      ref
          .read(chatProvider.notifier)
          .updateLoadingMessage(formattedResponse, type: MessageType.summarize);
      scrollToEnd();
    } catch (e) {
      if (context.mounted) {
        // Handle error in the controller layer
        ref
            .read(chatProvider.notifier)
            .updateLoadingMessage("Error summarizing: ${e.toString()}");
        scrollToEnd();
      }
    }
  }

  /// Formats the summary response according to the required format
  /// Format: 'Summary: "[summary]"'
  /// @param response The SummarizeResult from the API
  /// @return The formatted response string
  String _formatSummaryResponse(SummarizeResult response) {
    return 'Summary: "${response.summary}"';
  }

  /// Handles a PDF response from the backend
  /// Adds a PDF message to the chat with a downloadable link
  /// @param pdfData The URL or path to the PDF file
  /// @param context The BuildContext for error handling
  Future<void> handlePdfResponse(String pdfData, BuildContext context) async {
    if (!context.mounted) return;
    // Update the chat with a downloadable PDF message
    ref.read(chatProvider.notifier).sendPdfMessage(pdfData);
    scrollToEnd();
  }
}
