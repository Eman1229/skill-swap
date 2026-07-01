import 'package:flutter/material.dart';
import 'package:skill_swap/Ui_helper/translation_helper.dart';

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
  SkillOption(name: 'AI', icon: Icons.auto_awesome, color: Color(0xFFFF5A5F)),
  SkillOption(name: 'Coding', icon: Icons.code, color: Color(0xFF9B51E0)),
  SkillOption(name: 'Drawing', icon: Icons.palette, color: Color(0xFFFFC107)),
  SkillOption(name: 'Data Analysis', icon: Icons.dns, color: Color(0xFF00BFA5)),
  SkillOption(name: 'Digital Marketing', icon: Icons.code, color: Color(0xFFFFC107)),
  SkillOption(name: 'Design', icon: Icons.edit, color: Color(0xFF00BFA5)),
  SkillOption(name: 'Music', icon: Icons.music_note, color: Color(0xFFFF5A5F)),
  SkillOption(name: 'Photos', icon: Icons.camera_alt, color: Color(0xFF9B51E0)),
  SkillOption(name: 'Others', icon: Icons.more_horiz, color: Color(0xFF00BFA5)),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 25, 18, 28),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: skillSelectionOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.04,
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
                height: 50,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    disabledBackgroundColor: Colors.grey[600],
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
    final colorScheme = Theme.of(context).colorScheme;

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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skill.color,
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFF9B51E0),
                          width: 3,
                        )
                      : null,
                ),
                child: Icon(
                  skill.icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            skill.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              height: 1.2,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 42, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: controller,
                style: TextStyle(
                  color: colorScheme.onSurface,
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
                  prefixIcon: Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.onSurface.withOpacity(0.75),
                    size: 15,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 20,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF526071), width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
