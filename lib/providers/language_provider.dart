import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_swap/screens/Setting/app_settings.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider._();

  static final LanguageProvider instance = LanguageProvider._();
  static const String _storageKey = 'selected_locale_code';
  static const Locale english = Locale('en');
  static const Locale urdu = Locale('ur');
  static const List<Locale> supportedLocales = [english, urdu];

  Locale _locale = english;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  String get languageName => languageNameForLocale(_locale);
  TextDirection get textDirection =>
      _locale.languageCode == 'ur' ? TextDirection.rtl : TextDirection.ltr;

  static String languageNameForLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ur':
        return 'Urdu';
      case 'en':
      default:
        return 'English';
    }
  }

  static Locale localeForLanguageName(String languageName) {
    switch (languageName.toLowerCase()) {
      case 'urdu':
        return urdu;
      case 'english':
      default:
        return english;
    }
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey) ?? english.languageCode;
    _locale = _localeFromCode(code);
    AppSettings().currentLanguage.value = languageName;
  }

  Future<void> setLocale(Locale locale) async {
    if (!isSupported(locale) || _locale == locale) return;

    _locale = Locale(locale.languageCode);
    AppSettings().currentLanguage.value = languageName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _locale.languageCode);

    notifyListeners();
  }

  Future<void> setLanguageName(String languageName) {
    return setLocale(localeForLanguageName(languageName));
  }

  bool isSupported(Locale locale) {
    return supportedLocales.any((item) => item.languageCode == locale.languageCode);
  }

  Locale _localeFromCode(String code) {
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => english,
    );
  }
}
