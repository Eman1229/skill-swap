import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';
import 'package:provider/provider.dart';
import 'package:skill_swap/providers/language_provider.dart';

class SkillOption {
  const SkillOption({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

const List<SkillOption> skillSelectionOptions = [
  SkillOption(name: 'AI', icon: Icons.auto_awesome, color: Color(0xFFFF6A6B)),
  SkillOption(name: 'Coding', icon: Icons.code, color: Color(0xFF9D4EDD)),
  SkillOption(name: 'Drawing', icon: Icons.palette, color: Color(0xFFF5CB1A)),
  SkillOption(name: 'Data Analysis', icon: Icons.storage, color: Color(0xFF5FD5C7)),
  SkillOption(name: 'Digital Marketing', icon: Icons.code, color: Color(0xFFF5CB1A)),
  SkillOption(name: 'Design', icon: Icons.architecture, color: Color(0xFF6EE7E0)),
  SkillOption(name: 'Music', icon: Icons.music_note, color: Color(0xFFFF6A6B)),
  SkillOption(name: 'Photos', icon: Icons.camera_alt, color: Color(0xFF9D4EDD)),
  SkillOption(name: 'Others', icon: Icons.more_horiz, color: Color(0xFF6EE7E0)),
];

class SkillSelectionScaffold extends StatelessWidget {
  const SkillSelectionScaffold({
    super.key,
    required this.title,
    required this.selectedSkills,
    required this.onSkillTap,
    required this.onNext,
  });

  final String title;
  final Set<String> selectedSkills;
  final ValueChanged<String> onSkillTap;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 45, 20, 30),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  color: Color(0xFF00C2FF),
                  fontSize: 28,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 45),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: skillSelectionOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.76,
                  ),
                  itemBuilder: (context, index) {
                    final skill = skillSelectionOptions[index];
                    final isSelected = selectedSkills.contains(skill.name);

                    return _SkillTile(
                      skill: skill,
                      isSelected: isSelected,
                      onTap: () => onSkillTap(skill.name),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C2FF),
                    disabledBackgroundColor: Colors.grey[800],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'next'.tr(),
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({
    required this.skill,
    required this.isSelected,
    required this.onTap,
  });

  final SkillOption skill;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final displayName = skill.name == 'Others' ? 'others' : skill.name;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skill.color,
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF9D4EDD),
                          width: 3.5,
                        )
                      : null,
                ),
                child: Icon(
                  skill.icon,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF9D4EDD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class OtherSkillScaffold extends StatelessWidget {
  const OtherSkillScaffold({
    super.key,
    required this.title,
    required this.controller,
    required this.onNext,
  });

  final String title;
  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 45, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  color: Color(0xFF00C2FF),
                  fontSize: 28,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 45),
              TextField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 7),
                  hintText: 'skill_name'.tr(),
                  hintStyle: const TextStyle(
                    color: Color(0xFFB8C0D4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.grey,
                    size: 16,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 20,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF526071), width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00C2FF), width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C2FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'next'.tr(),
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
