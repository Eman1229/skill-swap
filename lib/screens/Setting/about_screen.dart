import 'package:skill_swap/ui_helper/translation_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';

class AboutScreen extends StatelessWidget {
 const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor:  Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'about_skill_swap_title'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            _buildGlowingLogo(context),
            SizedBox(height: 16),
            Text(
              'Skill Swap',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.2),
            ),
            SizedBox(height: 6),
            Text(
              'Version 1.0.0 (Build 12)',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 32),
            _buildAboutCard(context),
            SizedBox(height: 32),
            _buildSectionTitle(context, 'legal_agreements'.tr()),
            _buildLegalTile(
              context: context,
              icon: Icons.article_outlined,
              title: 'terms_of_service'.tr(),
              content: 'terms_of_service_content'.tr(),
            ),
            _buildLegalTile(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: 'privacy_policy'.tr(),
              content: 'privacy_policy_content'.tr(),
            ),
            _buildLegalTile(
              context: context,
              icon: Icons.code_rounded,
              title: 'open_source_licenses'.tr(),
              content: 'open_source_licenses_content'.tr(),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingLogo(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.swap_horizontal_circle_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 56,
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TranslatedText(
            'democratizing_education'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 10),
          TranslatedText(
            'mission_statement'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 4, bottom: 12),
        child: TranslatedText(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLegalTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withAlpha(8)),
      ),
      child: ListTile(
        onTap: () => _showLegalBottomSheet(context, title, content),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        title: TranslatedText(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).colorScheme.outlineVariant, size: 16),
      ),
    );
  }

  void _showLegalBottomSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6), height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Text(
                    content,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
