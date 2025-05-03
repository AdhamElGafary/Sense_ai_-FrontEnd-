enum MessageType {
  text,
  audio,
  image,
  video,
  liveVideo,
  speechToText,
  extra,
  loading,
  pdf,
  downloadAudio,
  summarize,
}

class ChatMessage {
  final String message;
  final MessageType messageType;
  final bool isUser;
  // Optional field for file data (e.g., base64 encoded PDF or audio)
  final String? fileData;
  final double? uploadProgress;
  final bool isProcessing;

  ChatMessage({
    required this.message,
    required this.messageType,
    required this.isUser,
    this.fileData,
    this.uploadProgress,
    this.isProcessing = false,
  });

  ChatMessage copyWith({
    String? message,
    MessageType? messageType,
    bool? isUser,
    String? fileData,
    double? uploadProgress,
    bool? isProcessing,
  }) {
    return ChatMessage(
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      isUser: isUser ?? this.isUser,
      fileData: fileData ?? this.fileData,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
