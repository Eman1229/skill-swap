import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_swap/providers/language_provider.dart';

class DynamicTranslationService {
  DynamicTranslationService._();
  static final DynamicTranslationService instance = DynamicTranslationService._();

  final Map<String, String> _cache = {};
  bool _cacheLoaded = false;
  static const String _prefPrefix = 'dyn_trans_cache_v1_';

  Future<void> _initCache() async {
    if (_cacheLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_prefPrefix)) {
          final cacheKey = key.substring(_prefPrefix.length);
          final val = prefs.getString(key);
          if (val != null) {
            _cache[cacheKey] = val;
          }
        }
      }
      _cacheLoaded = true;
    } catch (e) {
      debugPrint('Error loading dynamic translation cache: $e');
    }
  }

  /// Translates [text] to [targetLang] (defaults to current active locale).
  /// If language is English ('en') or text is empty, returns original [text].
  /// On error or timeout, returns original [text].
  Future<String> translate(String text, {String? targetLang}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return text;

    final lang = targetLang ?? LanguageProvider.instance.languageCode;
    if (lang == 'en') return text;

    // Skip non-translatable texts (pure numbers, URLs, emails)
    if (_isNonTranslatable(cleanText)) {
      return text;
    }

    final cacheKey = '${lang}_$cleanText';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    await _initCache();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$lang&dt=t&q=${Uri.encodeComponent(cleanText)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        if (decoded.isNotEmpty && decoded[0] is List) {
          final StringBuffer sb = StringBuffer();
          for (var item in decoded[0]) {
            if (item is List && item.isNotEmpty && item[0] != null) {
              sb.write(item[0]);
            }
          }
          final translated = sb.toString();
          if (translated.isNotEmpty) {
            _cache[cacheKey] = translated;
            _saveToPrefs(cacheKey, translated);
            return translated;
          }
        }
      }
    } catch (e) {
      debugPrint('DynamicTranslationService error for "$text": $e');
    }

    // Fallback to original text if translation fails or status != 200
    return text;
  }

  bool _isNonTranslatable(String text) {
    if (RegExp(r'^\d+$').hasMatch(text)) return true;
    if (RegExp(r'^https?://').hasMatch(text)) return true;
    if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) return true;
    return false;
  }

  void _saveToPrefs(String cacheKey, String translated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$cacheKey', translated);
    } catch (e) {
      debugPrint('Error saving dynamic translation to prefs: $e');
    }
  }

  Future<List<String>> translateList(List<String> list, {String? targetLang}) async {
    return Future.wait(list.map((item) => translate(item, targetLang: targetLang)));
  }
}
