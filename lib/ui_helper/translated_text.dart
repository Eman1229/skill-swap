import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/ui_helper/translation_helper.dart';

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextAlign? textAlign;
  final bool softWrap;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.overflow,
    this.maxLines,
    this.textAlign,
    this.softWrap = true,
  });

  bool _isEnglishOrAscii(String str) {
    if (str.trim().isEmpty) return false;
    // Check if string contains basic Latin letters and no CJK / Arabic / Cyrillic / Devanagari script
    final nonLatinScript = RegExp(
      r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\u0600-\u06ff\u0750-\u077f\u0900-\u097f\u0400-\u04ff]',
    );
    return !nonLatinScript.hasMatch(str);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final langCode = langProvider.languageCode;
    final isRtl = langProvider.textDirection == TextDirection.rtl;
    final defaultTextAlign = isRtl ? TextAlign.right : TextAlign.left;

    if (langCode == 'en' || text.trim().isEmpty) {
      return Text(
        text,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
        textAlign: textAlign ?? defaultTextAlign,
        textDirection: langProvider.textDirection,
        softWrap: softWrap,
      );
    }

    // 1. Check static translation dictionary
    final staticTrans = AppTranslations.translate(text, langCode);

    // If static translation gave a valid non-English translated string for non-English locale, use it directly
    final isStaticValid = staticTrans != text && !_isEnglishOrAscii(staticTrans);
    if (isStaticValid) {
      return Text(
        staticTrans,
        style: style,
        overflow: overflow,
        maxLines: maxLines,
        textAlign: textAlign ?? defaultTextAlign,
        textDirection: langProvider.textDirection,
        softWrap: softWrap,
      );
    }

    // 2. Fetch dynamic translation asynchronously (translates English strings or fallbacks into target language)
    final sourceToTranslate = (staticTrans != text && _isEnglishOrAscii(staticTrans))
        ? staticTrans
        : text;

    return FutureBuilder<String>(
      future: DynamicTranslationService.instance.translate(sourceToTranslate, targetLang: langCode),
      initialData: sourceToTranslate,
      builder: (context, snapshot) {
        final displayText = snapshot.data ?? sourceToTranslate;
        return Text(
          displayText,
          style: style,
          overflow: overflow,
          maxLines: maxLines,
          textAlign: textAlign ?? defaultTextAlign,
          textDirection: langProvider.textDirection,
          softWrap: softWrap,
        );
      },
    );
  }
}
