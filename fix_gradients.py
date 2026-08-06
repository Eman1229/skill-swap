import os
import re

files_to_check = [
    'lib/screens/Swap/confirm_swap_completion_screen.dart',
    'lib/screens/Swap/confirm_swap_screen.dart',
    'lib/screens/Swap/create_assignment_screen.dart',
    'lib/screens/Swap/create_session_screen.dart',
    'lib/screens/Swap/edit_session_screen.dart',
    'lib/screens/Swap/my_swaps_screen.dart',
    'lib/screens/Swap/rate_feedback_screen.dart',
    'lib/screens/Swap/session_detail_screen.dart',
    'lib/screens/Swap/skill_detail_screen.dart',
    'lib/screens/widgets/report_user_dialog.dart'
]

for filepath in files_to_check:
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    orig = content
    
    # We want to replace `gradient: LinearGradient(...)` with `color: Theme.of(context).colorScheme.primary,`
    # and `gradient: const LinearGradient(...)` with `color: Theme.of(context).colorScheme.primary,`
    # But ONLY for button containers, not the main background.
    # Button containers are usually followed by `borderRadius: BorderRadius.circular(...)`
    
    # So we replace the gradient blocks that look like CTA gradients.
    content = re.sub(
        r'gradient:\s*LinearGradient\(\s*colors:\s*\[\s*(?:Theme\.of\(context\)\.colorScheme\.primary|colorScheme\.primary)[^\]]+\](?:,\s*begin:[^,]+,\s*end:[^)]+)?\s*\),?',
        r'color: Theme.of(context).colorScheme.primary,',
        content,
        flags=re.DOTALL
    )
    
    content = re.sub(
        r'gradient:\s*const\s*LinearGradient\(\s*colors:\s*\[[^\]]+\]\s*\),?',
        r'color: Theme.of(context).colorScheme.primary,',
        content,
        flags=re.DOTALL
    )
    
    # Replace borderRadius: BorderRadius.circular(20|28|30) if it's near the color or child: ElevatedButton
    content = re.sub(
        r'borderRadius:\s*BorderRadius\.circular\(\s*(?:20|28|30)\s*\)',
        r'borderRadius: BorderRadius.circular(15)',
        content
    )

    if orig != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed gradients/radius in {filepath}")
