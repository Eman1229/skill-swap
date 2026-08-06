import os

# 1. swap_request_card.dart
f1 = 'lib/screens/Chat/widgets/swap_request_card.dart'
with open(f1, 'r', encoding='utf-8') as f:
    c1 = f.read()

import re
c1 = re.sub(
    r'<<<<<<< HEAD\s*side: BorderSide\(color: color, width: 1.5\),\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius.circular\(15\)\),\s*=======\s*side: BorderSide\(\s*color: onPressed == null \? Colors.grey : color,\s*width: 1.5,\s*\),\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius.circular\(12\)\),\s*>>>>>>> [^\n]+',
    '''          side: BorderSide(
            color: onPressed == null ? Colors.grey : color,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),''',
    c1
)
with open(f1, 'w', encoding='utf-8') as f:
    f.write(c1)

# 2. swapping Available.dart
f2 = 'lib/screens/Home Screens/swapping Available.dart'
with open(f2, 'r', encoding='utf-8') as f:
    c2 = f.read()

c2 = re.sub(
    r'<<<<<<< HEAD\s*color: Theme\.of\(context\)\.colorScheme\.primary,\s*borderRadius: BorderRadius\.circular\(15\),\s*=======\s*gradient: onTap == null\s*\?\s*null\s*:\s*LinearGradient\([\s\S]*?end: Alignment\.centerRight,\s*\),\s*color: onTap == null \? Colors\.grey\.withOpacity\(0\.3\) : null,\s*borderRadius: BorderRadius\.circular\(20\),\s*>>>>>>> [^\n]+',
    '''        color: onTap == null ? Colors.grey.withOpacity(0.3) : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(15),''',
    c2
)
with open(f2, 'w', encoding='utf-8') as f:
    f.write(c2)

# 3. skill_detail_screen.dart
f3 = 'lib/screens/Swap/skill_detail_screen.dart'
with open(f3, 'r', encoding='utf-8') as f:
    c3 = f.read()

c3 = re.sub(
    r"<<<<<<< HEAD\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius\.circular\(15\)\),\s*title: const Text\('Mark Teaching Complete\?', style: TextStyle\(color: Colors\.white, fontWeight: FontWeight\.bold\)\),\s*=======\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius\.circular\(20\)\),\s*title: Text\('mark_teaching_complete_confirm'\.tr\(\), style: TextStyle\(color: Colors\.white, fontWeight: FontWeight\.bold\)\),\s*>>>>>>> [^\n]+",
    "        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),\n        title: Text('mark_teaching_complete_confirm'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),",
    c3
)

c3 = re.sub(
    r"<<<<<<< HEAD\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius\.circular\(15\)\),\s*title: const Text\('Request More Sessions\?', style: TextStyle\(color: Colors\.white, fontWeight: FontWeight\.bold\)\),\s*=======\s*shape: RoundedRectangleBorder\(borderRadius: BorderRadius\.circular\(20\)\),\s*title: Text\('request_more_sessions_confirm'\.tr\(\), style: TextStyle\(color: Colors\.white, fontWeight: FontWeight\.bold\)\),\s*>>>>>>> [^\n]+",
    "        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),\n        title: Text('request_more_sessions_confirm'.tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),",
    c3
)

with open(f3, 'w', encoding='utf-8') as f:
    f.write(c3)

print("Conflicts resolved.")
