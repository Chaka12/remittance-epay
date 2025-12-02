import 'dart:io' show Platform;

class ApiConfig {
  // ============================================================
  // API CONFIGURATION
  // ============================================================
  // 
  // This file configures the backend API URL for the Flutter app.
  // The app automatically detects the platform and uses the correct URL.
  // ============================================================
  
  // PRODUCTION: Your Replit API URL (update this after publishing)
  static const String productionUrl = 'https://41e33165-58ac-4e14-9bdc-1e4f3bedb1f4-00-uj0rr5uxkqji.riker.replit.dev';
  
  // DEVELOPMENT URLs
  // Android emulator uses 10.0.2.2 to reach host machine's localhost
  static const String androidEmulatorUrl = 'http://10.0.2.2:5000';
  // iOS simulator and physical devices use localhost
  static const String iosSimulatorUrl = 'http://localhost:5000';
  // Physical device on same network - replace with your computer's IP
  static const String localNetworkUrl = 'http://192.168.1.100:5000';
  
  // ============================================================
  // ENVIRONMENT TOGGLE
  // Set to true when testing locally, false for production
  // ============================================================
  static const bool isDevelopment = false;
  
  // Get the appropriate development URL based on platform
  static String get _developmentUrl {
    try {
      if (Platform.isAndroid) {
        return androidEmulatorUrl;
      } else if (Platform.isIOS) {
        return iosSimulatorUrl;
      }
    } catch (e) {
      // Platform not available (web or test environment)
    }
    return androidEmulatorUrl; // Default fallback
  }
  
  // Get the current API URL based on environment
  static String get baseUrl {
    if (isDevelopment) {
      return _developmentUrl;
    }
    return productionUrl;
  }
  
  // API Endpoints
  static String get healthEndpoint => '$baseUrl/health';
  static String get walletInfoEndpoint => '$baseUrl/wallet-info';
  static String get sendEndpoint => '$baseUrl/send';
  static String get historyEndpoint => '$baseUrl/history';
  static String get networkInfoEndpoint => '$baseUrl/network-info';
  
  // Helper to check if using production
  static bool get isProduction => !isDevelopment;
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
