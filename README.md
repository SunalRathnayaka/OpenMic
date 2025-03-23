# OpenMic

OpenMic is a cross-platform mobile application that transforms your smartphone into a wireless microphone for your computer. By streaming audio over Wi-Fi with low latency and high quality, OpenMic is perfect for gaming, online meetings, and recordings. It supports both Android and iOS on the mobile side and is compatible with Linux and Windows on the computer side.

## Features

- **Real-Time Audio Streaming**: Broadcasts audio from your smartphone to your computer with minimal latency using WebSockets at a 44.1kHz sample rate.
- **Cross-Platform Support**: Works on Android and iOS devices, with computer compatibility for Linux and Windows.
- **User-Friendly Interface**: Displays server IP, port, and connected clients, with intuitive start/stop controls and error notifications.
- **Background Operation**: Runs seamlessly in the background with foreground service integration, ensuring uninterrupted streaming.
- **Client Management**: Tracks and manages multiple connected devices, providing real-time connection status.

## Technologies

- **Flutter & Dart**: Powers the mobile app’s cross-platform frontend and core logic.
- **WebSockets**: Enables real-time audio streaming via a `ServerSocket` on port 8125.
- **Flutter Sound**: Handles audio recording with PCM16 codec for high-quality output.
- **Foreground Services**: Ensures persistent operation using `flutter_foreground_task`.
- **Permissions Handling**: Manages microphone access and battery optimization with `permission_handler`.

## Prerequisites

- **Flutter SDK**: Version 3.0.0 or higher.
- **Dart**: Included with Flutter.
- **Computer Receiver**: A compatible receiver application on Linux or Windows (not included in this repo; see [Usage](#usage) for details).
- **Wi-Fi Network**: Both the smartphone and computer must be on the same Wi-Fi network.

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/SunalRathnayaka/OpenMic.git
   cd OpenMic
