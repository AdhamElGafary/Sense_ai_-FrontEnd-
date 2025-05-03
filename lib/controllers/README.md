# Chat Screen Controllers

This directory contains controllers for the chat screen functionality, split into smaller files for better maintainability.

## Application Overview

The Analyzer app provides a comprehensive platform for analyzing various types of media:

- **Text Analysis**: Analyze sentiment of text input
- **Image Analysis**: Detect emotions from images
- **Audio Analysis**: Process speech from recorded or uploaded audio files
- **Video Analysis**: Extract emotional data from videos and provide detailed reports

## Controller Structure

The controllers follow a delegation pattern where the main `ChatScreenController` delegates specific functionality to specialized controllers:

- `BaseController`: Common base functionality used by all controllers
- `TextController`: Handling text messages, sentiment analysis, and summarization
- `FileController`: File uploads and processing for images, videos, and documents
- `AudioController`: Audio recording, playback, and speech-to-text processing
- `VideoController`: Video streaming, camera management, and emotion analysis
- `ImageController`: Image capture and emotion detection processing

## How To Use

In your screen or widget, you only need to instantiate the main `ChatScreenController` and use its methods:

```dart
final chatController = ChatScreenController(
  ref: ref,
  scrollController: scrollController
);

// Send a text message
await chatController.sendText("Hello, world!", context);

// Pick a file
await chatController.pickFile(context, "image");

// Start live video analysis
await chatController.startLiveVideoAnalysis(context);
```

The main controller will delegate these calls to the appropriate specialized controllers internally.

## Integration with App Architecture

The controllers integrate with other components of the app's clean architecture:

- **Models**: Controllers use data models for API responses and chat messages
- **Providers**: Controllers use Riverpod providers for state management
- **Services**: Controllers communicate with API services for backend integration
- **Views**: UI components rely on controllers for business logic

## Extending Functionality

To add new functionality:

1. First determine which specialized controller it belongs to
2. Add the implementation to that controller
3. Expose the method through the main `ChatScreenController`

For larger new features, consider creating a new specialized controller and adding it to the main controller.

## Architecture Benefits

This modular approach offers several benefits:

1. **Maintainability**: Each controller has a single responsibility
2. **Testability**: Specialized controllers can be tested in isolation
3. **Readability**: Code is organized by functionality making it easier to navigate
4. **Scalability**: New features can be added without bloating the main controller
