import 'package:flutter/material.dart';

class UiHelper {
  static CustomTextButton({
    required BuildContext context,
    required String text,
    required VoidCallback callBack,
  }) {
    return TextButton(
      onPressed: callBack,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  static CustomImage({required String imgurl}) {
    return Image.asset('assets/Images/$imgurl');
  }

  static Widget CustomTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String text,
    required bool tohide,
    required TextInputType textinputtype,
    required IconData prefixIcon,
    Widget? suffixIcon,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    AutovalidateMode? autovalidateMode,
    double? width,
  }) {
    return SizedBox(
      width: width ?? 343,
      child: TextFormField(
        controller: controller,
        obscureText: tohide,
        keyboardType: textinputtype,
        onChanged: onChanged,
        validator: validator,
        autovalidateMode:
        autovalidateMode ?? AutovalidateMode.onUserInteraction,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: SizedBox(
            width: 68,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  prefixIcon,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 12),
                Container(
                  height: 20,
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                SizedBox(width: 12),
              ],
            ),
          ),
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          errorStyle: TextStyle(color: Color(0xFFFF3B3B), fontSize: 12),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF3B3B), width: 1.0),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
          ),
        ),
      ),
    );
  }

  /// Small badge showing a 2-letter country code (e.g. "PK"), used instead
  /// of emoji flags since emoji flags often fail to render on Windows
  /// desktop builds (missing color-emoji font).
  static Widget _CountryBadge({
    required BuildContext context,
    required String iso,
  }) {
    return Container(
      width: 26,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        iso,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  static Widget CustomPhoneField({
    required BuildContext context,
    required TextEditingController controller,
    required String text,
    required String selectedCode,
    required List<Map<String, dynamic>> countries,
    required ValueChanged<String> onCodeChanged,
    String? Function(String?)? validator,
  }) {
    // Guard against a selectedCode that doesn't match any entry in
    // `countries` (this is what throws "type 'Null' is not a subtype").
    final Map<String, dynamic> safeSelected = countries.firstWhere(
          (c) => (c['code'] as String?) == selectedCode,
      orElse: () => countries.isNotEmpty
          ? countries.first
          : {'code': selectedCode, 'name': '', 'iso': ''},
    );

    return SizedBox(
      width: 343,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: text,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_android_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 10),
                // PopupMenuButton instead of DropdownButton: its menu sizes
                // itself to the content (full country name + code), not to
                // the small closed-anchor width, so nothing gets clipped.
                PopupMenuButton<Map<String, dynamic>>(
                  padding: EdgeInsets.zero,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  offset: const Offset(0, 36),
                  itemBuilder: (ctx) {
                    return countries.map((country) {
                      final iso = (country['iso'] as String?) ?? '';
                      final name = (country['name'] as String?) ?? '';
                      final code = (country['code'] as String?) ?? '';
                      return PopupMenuItem<Map<String, dynamic>>(
                        value: country,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (iso.isNotEmpty) ...[
                              _CountryBadge(context: context, iso: iso),
                              SizedBox(width: 10),
                            ],
                            Flexible(
                              child: Text(
                                "$name ($code)",
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  onSelected: (country) {
                    final code = country['code'] as String?;
                    if (code != null) onCodeChanged(code);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if ((safeSelected['iso'] as String?)?.isNotEmpty == true) ...[
                        _CountryBadge(
                          context: context,
                          iso: safeSelected['iso'] as String,
                        ),
                        SizedBox(width: 6),
                      ],
                      Text(
                        (safeSelected['code'] as String?) ?? selectedCode,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  height: 20,
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                SizedBox(width: 12),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          errorStyle: TextStyle(color: Color(0xFFFF3B3B), fontSize: 12),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF3B3B), width: 1.0),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF3B3B), width: 1.5),
          ),
        ),
      ),
    );
  }
}