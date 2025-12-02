import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _pinCodeKey = 'pin_code';
  static const String _walletAddressKey = 'wallet_address';
  
  AuthService(this._prefs);
  
  Future<bool> isLoggedIn() async {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  Future<bool> login(String pinCode) async {
    final storedPin = await _secureStorage.read(key: _pinCodeKey);
    
    if (storedPin == null) {
      // First time login - set up PIN
      await _secureStorage.write(key: _pinCodeKey, value: pinCode);
      await _prefs.setBool(_isLoggedInKey, true);
      notifyListeners();
      return true;
    } else if (storedPin == pinCode) {
      await _prefs.setBool(_isLoggedInKey, true);
      notifyListeners();
      return true;
    }
    
    return false;
  }
  
  Future<void> logout() async {
    await _prefs.setBool(_isLoggedInKey, false);
    notifyListeners();
  }
  
  Future<bool> changePin(String oldPin, String newPin) async {
    final storedPin = await _secureStorage.read(key: _pinCodeKey);
    
    if (storedPin == oldPin) {
      await _secureStorage.write(key: _pinCodeKey, value: newPin);
      return true;
    }
    
    return false;
  }
  
  Future<String?> getWalletAddress() async {
    return _prefs.getString(_walletAddressKey);
  }
  
  Future<void> setWalletAddress(String address) async {
    await _prefs.setString(_walletAddressKey, address);
    notifyListeners();
  }
  
  Future<bool> hasPin() async {
    final pin = await _secureStorage.read(key: _pinCodeKey);
    return pin != null;
  }
}