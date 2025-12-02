#!/bin/bash

echo "🚀 Building IOTA Remittance Flutter App..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Generate localization files
echo "🌍 Generating localization files..."
flutter pub run intl_utils:generate

# Build APK for low-end devices
echo "🔨 Building APK (optimized for low-end devices)..."
flutter build apk \
  --release \
  --target-platform android-arm \
  --split-debug-info=build/app/outputs/symbols \
  --obfuscate \
  --no-shrink

echo "✅ Build completed!"
echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
echo "📊 Build size optimized for 1GB RAM devices"