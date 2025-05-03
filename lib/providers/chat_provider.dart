import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import 'package:flutter/foundation.dart';

/// ChatNotifier: Core state management for all chat messages
///
/// This StateNotifier manages the complete chat history and provides methods
/// for adding, updating, and manipulating chat messages. It serves as the
/// central data store for the chat interface.
///
/// The class is designed using the Riverpod state management pattern,
/// providing a reactive state container that automatically rebuilds UI
/// when messages are added or updated.
///
/// Key features:
/// - Adding different types of messages (text, audio, files)
/// - Managing loading states and updating messages
/// - Supporting various media types (images, audio, video, PDF)
/// - Maintaining message order and history
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  /// Initialize with an empty chat message list
  ChatNotifier() : super([]);

  /// Adds a new text message to the chat
  ///
  /// Creates a basic text message and adds it to the chat history.
  /// Used for regular text exchanges between user and system.
  ///
  /// @param text The message text content to display
  /// @param isUser Whether the message is from the user (true) or system (false)
  void sendTextMessage(String text, bool isUser) {
    state = [
      ...state,
      ChatMessage(message: text, messageType: MessageType.text, isUser: isUser),
    ];
    debugPrint('ChatProvider: Added text message, count: ${state.length}');
  }

  /// Creates and adds a file message to the chat
  ///
  /// Determines the appropriate MessageType based on the file type
  /// and adds the message to the chat history.
  ///
  /// @param file The file object to be sent
  /// @param fileType The type of file ("image", "video", "audio", etc.)
  Future<void> sendFileMessage(dynamic file, String fileType) async {
    // Determine appropriate message type based on file type
    MessageType type;
    if (fileType == "image") {
      type = MessageType.image;
    } else if (fileType == "video") {
      type = MessageType.video;
    } else if (fileType == "audio") {
      type = MessageType.audio;
    } else {
      type = MessageType.summarize;
    }

    // Add the message to the chat
    state = [
      ...state,
      ChatMessage(
        message: "Sent a $fileType file.",
        messageType: type,
        isUser: true,
        isProcessing: type == MessageType.video || type == MessageType.image,
      ),
    ];
  }

  /// Adds a user audio message with the file path or data
  ///
  /// Specifically used for displaying recorded or uploaded audio from the user.
  /// Includes an option to skip API processing to prevent duplicate requests.
  ///
  /// @param audioFilePath The path to the audio file or base64 encoded data
  /// @param skipApiProcessing If true, only adds UI element without triggering API calls
  void sendUserAudioMessage(
    String audioFilePath, {
    bool skipApiProcessing = false,
  }) {
    // Log audio message creation for debugging
    debugPrint(
      'ChatProvider: Adding user audio message with path: $audioFilePath, skipProcessing: $skipApiProcessing',
    );

    // Add the message to the UI immediately
    state = [
      ...state,
      ChatMessage(
        message: "Audio recording",
        messageType: MessageType.audio,
        isUser: true,
        fileData: audioFilePath,
      ),
    ];

    // Schedule any additional processing after UI has updated
    Future.microtask(() {
      debugPrint('ChatProvider: User audio message added successfully');

      // If we're supposed to skip API processing, don't trigger any further actions
      if (skipApiProcessing) {
        debugPrint(
          'ChatProvider: Skipping API processing for this audio message',
        );
      }
      // Any API processing logic would normally go here
    });
  }

  /// Adds a bot (system) audio message to the chat
  ///
  /// Used for displaying audio responses from the AI assistant.
  /// Supports different types of audio playback UI elements.
  ///
  /// @param audioData The path, URL, or base64 encoded audio data
  /// @param message Optional descriptive message to display with the audio
  /// @param messageType The type of audio message UI to use
  void sendBotAudioMessage(
    String audioData, {
    String message = "Audio from assistant",
    MessageType messageType = MessageType.downloadAudio,
  }) {
    // Log audio message creation for debugging
    debugPrint('ChatProvider: Adding bot audio message');

    // Add the message to the UI immediately
    state = [
      ...state,
      ChatMessage(
        message: message,
        messageType: messageType,
        isUser: false,
        fileData: audioData,
      ),
    ];

    // Schedule additional processing after the UI has updated
    Future.microtask(() {
      debugPrint('ChatProvider: Bot audio message added successfully');
    });
  }

  /// Adds a loading indicator message to the chat
  ///
  /// Creates a message with a loading animation to indicate
  /// that the system is processing something. The actual UI
  /// is rendered by the view layer based on MessageType.loading.
  void addLoadingMessage() {
    state = [
      ...state,
      ChatMessage(
        message:
            "loading", // This text won't be shown; the UI will render a loading animation
        messageType: MessageType.loading,
        isUser: false,
        isProcessing: true,
      ),
    ];
  }

  /// Updates the most recent loading message with actual content
  ///
  /// Finds the last loading message and replaces it with the provided content.
  /// Used to transition from a loading state to showing actual results.
  ///
  /// @param newText The text content to replace the loading message with
  /// @param fileData Optional file data (URL, path) to include with the message
  /// @param type The final message type after loading completes
  void updateLoadingMessage(
    String newText, {
    String? fileData,
    MessageType type = MessageType.text,
  }) {
    // Find the last loading message in the chat
    int index = state.lastIndexWhere(
      (msg) => msg.messageType == MessageType.loading,
    );

    // If a loading message was found, update it
    if (index != -1) {
      List<ChatMessage> updated = List.from(state);
      updated[index] = ChatMessage(
        message: newText,
        messageType: type,
        isUser: false,
        fileData: fileData,
        isProcessing: false,
      );
      state = updated;
    }
  }

  /// Adds a PDF message with a downloadable link
  ///
  /// Creates a specialized message for PDF reports that can be
  /// opened or downloaded by the user.
  ///
  /// @param pdfLink The URL or path to the PDF file
  void sendPdfMessage(String pdfLink) {
    state = [
      ...state,
      ChatMessage(
        message: "PDF Report Available",
        messageType: MessageType.pdf,
        isUser: false,
        fileData: pdfLink, // Store the link for later download/view
      ),
    ];
  }

  /// Convenience method for adding a bot audio message
  ///
  /// Simplified alias for sendBotAudioMessage with default parameters
  /// to improve code readability.
  ///
  /// @param audioData The audio data to include
  void sendAudioFileMessage(String audioData) {
    // Use the modern audio player for better user experience
    sendBotAudioMessage(audioData, message: "Audio response");
  }

  /// Clears all messages from the chat
  ///
  /// Resets the chat history to an empty state.
  /// Used for starting a new conversation or clearing history.
  void clearMessages() {
    state = [];
  }
}

/// Provider that makes the ChatNotifier available throughout the app
///
/// This Riverpod provider is the access point for the chat state.
/// UI components can watch this provider to react to changes in the chat.
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier();
});
