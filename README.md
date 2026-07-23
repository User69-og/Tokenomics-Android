# Tokenomics - AI Usage Tracker

Tokenomics is a sleek, modern Android application built with Flutter that helps you track your AI API and token usage across multiple providers (Anthropic Claude, OpenAI, Google AI Studio, etc.) in real-time.

It acts as a companion app to the Tokenomics Chrome Extension, allowing you to monitor your multi-account usage directly from your phone.

## Features

- **Multi-Provider Support:** Track usage for Anthropic (Claude), OpenAI, Google AI Studio, Cursor, ElevenLabs, RunwayML, and Stability AI.
- **Real-Time Data:** Syncs instantly with your Tokenomics Chrome Extension data via Firebase.
- **Secure by Design:** API keys are encrypted and stored locally on your device's Android Keystore.
- **Background Notifications:** Get alerted when you are nearing your token limits or usage caps without needing to keep the app open.
- **Beautiful UI:** A modern, dark-mode focused, glassmorphic interface built with Riverpod.
- **OTA Updates:** Built-in over-the-air (OTA) updater downloads and installs new releases directly from GitHub.

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / Android SDK

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/User69-og/Tokenomics-Android.git
   cd Tokenomics-Android
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## Releases & Updates

This app features a built-in OTA (Over-The-Air) updater. 
To install the latest version directly to your Android device, go to the [Releases page](../../releases) and download the `app-release.apk`.

Future updates will prompt you automatically inside the app.

## Security

Tokenomics takes your privacy and API keys seriously. 
- **No keys are sent to our servers.** 
- Keys are securely stored in `flutter_secure_storage`, which uses the native Android Keystore system.
- Firebase is used exclusively for syncing usage statistics from the Chrome extension, not for storing credentials.

## License

This project is licensed under the MIT License.
