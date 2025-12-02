# Flutter App Setup Guide

This guide will help you set up the IOTA Remittance Flutter app for local development.

## Prerequisites

Before you begin, make sure you have the following installed on your computer:

### 1. Flutter SDK (version 3.0 or higher)

**Windows:**
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your PATH environment variable

**macOS:**
```bash
# Using Homebrew
brew install flutter

# Or download manually from https://flutter.dev/docs/get-started/install/macos
```

**Linux:**
```bash
# Using snap
sudo snap install flutter --classic

# Or download manually from https://flutter.dev/docs/get-started/install/linux
```

### 2. Android Studio (for Android development)
1. Download from https://developer.android.com/studio
2. Install Android SDK (API level 33 or higher recommended)
3. Set up an Android emulator or connect a physical device

### 3. Xcode (for iOS development - macOS only)
1. Install from Mac App Store
2. Run: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
3. Run: `sudo xcodebuild -runFirstLaunch`

## Verify Installation

Run this command to check if everything is set up correctly:

```bash
flutter doctor
```

Fix any issues that appear before proceeding.

## Clone and Setup

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd iota-remittance-mvp/flutter_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API URL

Open `lib/config/api_config.dart` and update the settings:

```dart
class ApiConfig {
  // For production (your published Replit URL)
  static const String productionUrl = 'https://your-replit-app.replit.app';
  
  // For local development with Android emulator
  static const String developmentUrl = 'http://10.0.2.2:5000';
  
  // Set to true for local development, false for production
  static const bool isDevelopment = false;  // Change as needed
}
```

**Important Notes:**
- `10.0.2.2` is a special IP that Android emulators use to reach the host machine's localhost
- For iOS simulator, use `localhost` instead
- For production, use your published Replit URL

## Running the App

### Option 1: Android Emulator

1. Start Android Studio
2. Open AVD Manager (Tools > AVD Manager)
3. Create or start an emulator
4. Run the app:

```bash
flutter run
```

### Option 2: Physical Android Device

1. Enable Developer Options on your phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging in Developer Options
3. Connect your phone via USB
4. Trust the computer when prompted
5. Run:

```bash
flutter run
```

### Option 3: iOS Simulator (macOS only)

1. Open Xcode
2. Open Simulator (Xcode > Open Developer Tool > Simulator)
3. Run:

```bash
flutter run
```

### Option 4: iOS Physical Device (macOS only)

1. Connect your iPhone via USB
2. Trust the computer on your phone
3. Run:

```bash
flutter run
```

## Development vs Production Mode

### For Local Development (testing with local backend):

1. Make sure your backend is running locally on port 5000
2. Open `lib/config/api_config.dart` and set:
   ```dart
   static const bool isDevelopment = true;
   ```
3. The app will automatically use the correct URL:
   - **Android Emulator**: Uses `http://10.0.2.2:5000` (special IP for host machine)
   - **iOS Simulator**: Uses `http://localhost:5000`
4. Run the app

### For Production (using Replit backend):

1. Publish your Replit app (click the "Publish" button in Replit)
2. Copy your published URL (e.g., `https://your-app-name.replit.app`)
3. Open `lib/config/api_config.dart` and update:
   ```dart
   static const bool isDevelopment = false;
   static const String productionUrl = 'https://your-published-url.replit.app';
   ```
4. Run the app

### For Physical Device Testing (on same WiFi network):

1. Find your computer's local IP address:
   - **Windows**: Run `ipconfig` in Command Prompt
   - **macOS/Linux**: Run `ifconfig` or `ip addr`
2. Update `lib/config/api_config.dart`:
   ```dart
   static const String localNetworkUrl = 'http://YOUR_IP:5000';
   ```
3. Modify the `_developmentUrl` getter to return `localNetworkUrl`
4. Make sure your firewall allows connections on port 5000

## Building Release APK

To create a release version for distribution:

```bash
# Build APK
flutter build apk --release

# The APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### "Connection refused" errors
- Make sure the backend server is running
- Check that `ApiConfig.isDevelopment` matches your setup
- For emulator, ensure you're using `10.0.2.2` not `localhost`

### "flutter: command not found"
- Make sure Flutter is in your PATH
- Restart your terminal after installation

### Android SDK issues
- Run `flutter doctor --android-licenses` to accept licenses
- Ensure Android SDK is installed via Android Studio

### iOS build fails
- Run `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- Open ios/Runner.xcworkspace in Xcode and fix signing issues

### Dependencies not found
- Run `flutter clean` then `flutter pub get`

## App Features

Once running, the app provides:

1. **Login Screen** - Set up a PIN for security
2. **Home Dashboard** - View your wallet balance
3. **Send Money** - Transfer funds to other addresses
4. **Transaction History** - View past transactions
5. **Settings** - Change language (English/Sesotho), security settings

## Need Help?

- Flutter Documentation: https://flutter.dev/docs
- IOTA Documentation: https://docs.iota.org
- Shimmer Network: https://shimmer.network
