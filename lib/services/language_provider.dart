// lib/services/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('uz'); // Default tilni 'uz' ga o'zgartirdik

  Locale get locale => _locale;

  LanguageProvider() {
    _loadPreferredLanguage();
  }

  Future<void> _loadPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('languageCode');
    if (langCode != null) {
      _locale = Locale(langCode);
    }
    notifyListeners();
  }

  Future<void> changeLanguage(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
    notifyListeners();
  }
}
