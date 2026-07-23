<h1 align="center">Tokenomics 🪙 - AI Usage Tracker (Android)</h1>

<p align="center">
  <strong>The ultimate companion app for tracking your AI token usage across multiple providers in real-time.</strong>
</p>

Tokenomics is a sleek, modern Android application that helps you monitor your AI API limits and token usage across Anthropic (Claude), OpenAI, Google AI Studio, and more. It pairs directly with the Tokenomics Chrome Extension, allowing you to track your multi-account usage directly from your phone.

---

## ✨ Features

- 📊 **Multi-Provider Support:** Track usage limits for Anthropic Claude (Session Tokens & API Keys), OpenAI, Google Gemini, Cursor, ElevenLabs, RunwayML, and Stability AI.
- ⚡ **Real-Time Firebase Sync:** Usage data syncs instantly from your Tokenomics Chrome Extension to your mobile device.
- 🔔 **Smart Notifications:** Native Android background alarms alert you when you are nearing your hourly or weekly token caps without draining your battery.
- 🔒 **Privacy First:** Your API keys are encrypted and stored locally in your device's native Android Keystore. **No keys are sent to any external servers.**
- 🚀 **Over-The-Air (OTA) Updates:** The app automatically checks GitHub for new versions on startup and seamlessly installs updates directly on your device.
- 🎨 **Beautiful UI:** A dark-mode optimized, glassmorphic interface built using Flutter and Riverpod.

---

## 📱 How to Install (For Regular Users)

If you just want to use the app to track your tokens, you don't need to write any code! Just install the APK:

1. Go to the [Releases Page](https://github.com/User69-og/Tokenomics-Android/releases) of this repository.
2. Click on the latest release and download the **`app-release.apk`** file to your Android phone.
3. Open the downloaded file to install it. *(Note: You may need to allow "Install from unknown sources" in your Android Settings).*
4. Once installed, future updates will automatically notify you inside the app and install with a single tap!

---

## 🛠️ Setup & Configuration (Step-by-Step)

Once you open the app, you need to connect your accounts to start tracking usage.

### 1. Linking your Chrome Extension via Firebase
To get real-time syncing between your browser and your phone:
1. Open the **Tokenomics Chrome Extension** on your desktop.
2. Go to the Extension Settings and copy your unique **Firebase Realtime Database URL**.
3. Open the **Tokenomics Android App**, tap the Settings icon (⚙️) in the top right.
4. Paste your Firebase URL into the input field and save. 

### 2. Adding AI Accounts
Tap the **"+"** button on the Home Screen to add your AI accounts. Depending on the provider, you will need a specific key:

* **Anthropic Claude (Live Usage %):** 
  To see your live 5-hour messaging limits on Claude.ai:
  1. Open claude.ai in your desktop browser with the Tokenomics Chrome Extension active.
  2. Look at the usage bars at the bottom of the chat interface.
  3. Click the **"ID: ... (Copy)"** button next to the bars.
  4. Paste this ID into the app.
  
* **OpenAI (ChatGPT):**
  1. Go to `platform.openai.com`.
  2. Profile → API keys → Create new secret key.
  
* **Google AI Studio (Gemini):**
  1. Go to `aistudio.google.com`.
  2. Click "Get API key" → Create new key.

*Keys for Cursor, ElevenLabs, RunwayML, and Stability AI can also be found in their respective account settings pages.*

---

## 💻 Building from Source (For Developers)

Want to modify the app or contribute? Here is how to get it running locally.

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- Android Studio & Android SDK
- Git

### Installation Steps

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/User69-og/Tokenomics-Android.git
   cd Tokenomics-Android
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App:**
   Make sure you have an Android Emulator running or a physical device connected via USB debugging.
   ```bash
   flutter run
   ```

4. **Build a Release APK:**
   ```bash
   flutter build apk --release
   ```
   The compiled APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

### Publishing Updates (OTA System)
If you fork this project and want to use the OTA update system for your own users:
1. Open `lib/services/update_service.dart`.
2. Change the `_updateJsonUrl` to point to your repository's `update.json` file.
3. When releasing a new version, update `pubspec.yaml`, build the APK, and upload it to GitHub Releases.
4. Update the `update.json` file in the root of the repository with the new version number and APK URL.

---

## 🛡️ Security & Privacy Architecture

- **Local Storage:** `flutter_secure_storage` is used to encrypt all session tokens and API keys using AES encryption backed by the Android Keystore.
- **Firebase:** The Realtime Database is only used as a transient middleman to pass usage statistics (numbers and percentages) between the extension and the phone. **Credentials are never uploaded to Firebase.**
- **Network Requests:** All API requests to fetch token limits are made locally directly from your device to the respective provider's official API endpoints.

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
