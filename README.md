# Analyzer

A Flutter application for analyzing emotions, sentiments, and speech through audio, video, and text inputs.

## Overview

The Analyzer app provides a comprehensive platform for analyzing various types of media:

- **Text Analysis**: Analyze the sentiment of text input
- **Image Analysis**: Detect emotions from images
- **Audio Analysis**: Process speech from recorded or uploaded audio files
- **Video Analysis**: Extract emotional data from videos and provide detailed reports

## Latest Updates

### API Response Handling

The application now properly formats responses from different API endpoints:

1. **Sentiment Analysis (Text)**

   ```
   Sentiment: Positive
   Confidence: 96.63%
   ```

2. **Summarization**

   ```
   Summary: "I keep moving, I keep breathing, but something feels lost inside. It's just one of those days."
   ```

3. **Image Emotion Analysis**

   ```
   Emotion: Sad
   Confidence: 34.58%
   Mood: Negative
   ```

4. **Video Emotion Analysis**

   - Main analysis message:
     ```
     Dominant Emotion: Sad
     Emotion Durations: Angry - 5.5s, Sad - 8.9s
     Emotion Percentages: Angry - 37.5%, Sad - 62.5%
     ```
   - PDF report and audio file responses are also displayed in the chat

5. **Speech Analysis (Audio)**
   ```
   Transcription: "I keep moving, I keep breathing, but inside something feels lost."
   Summary: "Maybe it's time, maybe it's just one of those days."
   Sentiment: Negative
   Prediction Value: 0.15
   ```

### Enhanced Audio Handling

- Improved audio recording with debounce mechanisms to prevent multiple recordings
- Better UI feedback during recording process
- Unified response handling between recorded audio and uploaded audio files
- Automatic scrolling after messages to maintain visibility
- Cleaner display of speech-to-text results with comprehensive formatted data

### Improved Code Structure

- Comprehensive comments added throughout the codebase for better developer understanding
- Consistent formatting of API responses across all controllers
- Enhanced error handling and user feedback

## Architecture

The application follows a clean architecture approach with:

- **Models**: Data structures for API responses and chat messages
- **Controllers**: Business logic for handling different media types
- **Providers**: State management using Riverpod
- **Views**: UI components for displaying data and collecting user input
- **Services**: API communication and backend integration

### Key Components

- **ChatController**: Manages the chat interface and message flow
- **TextController**: Handles text processing, sentiment analysis, and summarization
- **FileController**: Manages file uploads and processing for images, videos, and documents
- **AudioController**: Controls audio recording, playback, and speech-to-text processing
- **VideoController**: Handles video uploads and live video streaming analysis

## Getting Started

1. Ensure you have Flutter installed on your machine
2. Clone the repository
3. Install dependencies: `flutter pub get`
4. Run the app: `flutter run`

## API Endpoints

The app communicates with the following API endpoints:

- Sentiment Analysis: `sentiment/analysis/`
- Summarization: `summarize/summaries/`
- Image Emotion Analysis: `emotion/analyses/`
- Video Emotion Analysis: `emotion-video/analyses/`
- Speech Analysis: `speech/analyses/`
- Live Video Analysis: `realtime-video/streams/`

## Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request
