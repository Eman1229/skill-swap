import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

class LanguageSettingsScreen extends StatefulWidget {
  LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'native': 'English (US)', 'flag': '🇺🇸', 'code': 'en'},
    {'name': 'Spanish', 'native': 'Español', 'flag': '🇪🇸', 'code': 'es'},
    {'name': 'French', 'native': 'Français', 'flag': '🇫🇷', 'code': 'fr'},
    {'name': 'German', 'native': 'Deutsch', 'flag': '🇩🇪', 'code': 'de'},
    {'name': 'Chinese', 'native': '中文', 'flag': '🇨🇳', 'code': 'zh'},
    {'name': 'Japanese', 'native': '日本語', 'flag': '🇯🇵', 'code': 'ja'},
    {'name': 'Arabic', 'native': 'العربية', 'flag': '🇸🇦', 'code': 'ar'},
    {'name': 'Russian', 'native': 'Русский', 'flag': '🇷🇺', 'code': 'ru'},
    {'name': 'Portuguese', 'native': 'Português', 'flag': '🇵🇹', 'code': 'pt'},
    {'name': 'Italian', 'native': 'Italiano', 'flag': '🇮🇹', 'code': 'it'},
    {'name': 'Urdu', 'native': 'اردو', 'flag': '🇵🇰', 'code': 'ur'},
    {'name': 'Hindi', 'native': 'हिंदी', 'flag': '🇮🇳', 'code': 'hi'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredLanguages {
    if (_searchQuery.isEmpty) return _languages;
    final q = _searchQuery.toLowerCase();
    return _languages.where((lang) {
      return lang['name']!.toLowerCase().contains(q) ||
          lang['native']!.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>(); // Triggers rebuild on language change
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'language'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: _buildSearchBar(),
          ),
          Expanded(
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) {
                final list = _filteredLanguages;
                if (list.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final lang = list[index];
                    final isSelected = languageProvider.languageCode == lang['code'];
                    return _buildLanguageTile(lang, isSelected);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'search_language'.tr(),
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(Map<String, String> lang, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () async {
        await context
            .read<LanguageProvider>()
            .setLocale(Locale(lang['code']!));

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'language'.tr()}: ${lang['name']}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : (isDark ? Colors.transparent : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
            width: 1.5,
          ),
          boxShadow: isDark ? null : [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          leading: Text(
            lang['flag']!,
            style: const TextStyle(fontSize: 22),
          ),
          title: Text(
            lang['native']!,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            lang['name']!,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 11),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 22)
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, color: Theme.of(context).colorScheme.primary.withOpacity(0.5), size: 64),
          SizedBox(height: 16),
          Text(
            'no_language_found'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'search_another_language'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
