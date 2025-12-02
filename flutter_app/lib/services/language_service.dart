import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _languageKey = 'selected_language';
  
  Locale _locale = const Locale('en');
  
  LanguageService(this._prefs) {
    _loadLanguage();
  }
  
  Locale get locale => _locale;
  
  void _loadLanguage() {
    final languageCode = _prefs.getString(_languageKey) ?? 'en';
    _locale = Locale(languageCode);
  }
  
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != _locale.languageCode) {
      _locale = Locale(languageCode);
      await _prefs.setString(_languageKey, languageCode);
      notifyListeners();
    }
  }
  
  String getCurrentLanguageName() {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'st':
        return 'Sesotho';
      default:
        return 'English';
    }
  }
}