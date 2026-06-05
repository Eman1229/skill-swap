import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_swap/screens/Setting/app_settings.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider._();

  static final LanguageProvider instance = LanguageProvider._();
  static const String _storageKey = 'selected_locale_code';

  static const Locale english = Locale('en');
  static const Locale spanish = Locale('es');
  static const Locale french = Locale('fr');
  static const Locale german = Locale('de');
  static const Locale chinese = Locale('zh');
  static const Locale japanese = Locale('ja');
  static const Locale arabic = Locale('ar');
  static const Locale russian = Locale('ru');
  static const Locale portuguese = Locale('pt');
  static const Locale italian = Locale('it');
  static const Locale urdu = Locale('ur');
  static const Locale hindi = Locale('hi');

  static const List<Locale> supportedLocales = [
    english,
    spanish,
    french,
    german,
    chinese,
    japanese,
    arabic,
    russian,
    portuguese,
    italian,
    urdu,
    hindi,
  ];

  Locale _locale = english;

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  String get languageName => languageNameForLocale(_locale);
  
  TextDirection get textDirection =>
      (_locale.languageCode == 'ur' || _locale.languageCode == 'ar') 
          ? TextDirection.rtl 
          : TextDirection.ltr;

  static String languageNameForLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'es': return 'Spanish';
      case 'fr': return 'French';
      case 'de': return 'German';
      case 'zh': return 'Chinese';
      case 'ja': return 'Japanese';
      case 'ar': return 'Arabic';
      case 'ru': return 'Russian';
      case 'pt': return 'Portuguese';
      case 'it': return 'Italian';
      case 'ur': return 'Urdu';
      case 'hi': return 'Hindi';
      case 'en':
      default: return 'English';
    }
  }

  static Locale localeForLanguageName(String languageName) {
    switch (languageName.toLowerCase()) {
      case 'spanish': return spanish;
      case 'french': return french;
      case 'german': return german;
      case 'chinese': return chinese;
      case 'japanese': return japanese;
      case 'arabic': return arabic;
      case 'russian': return russian;
      case 'portuguese': return portuguese;
      case 'italian': return italian;
      case 'urdu': return urdu;
      case 'hindi': return hindi;
      case 'english':
      default: return english;
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
