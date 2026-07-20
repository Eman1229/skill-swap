import os
import re

for root, dirs, files in os.walk('lib'):
    for file in files:
        if not file.endswith('.dart'): continue
        filepath = os.path.join(root, file)
        
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        orig = content
        
        # Fix category chips
        content = re.sub(
            r'gradient:\s*selected\s*\?\s*LinearGradient\([^)]*colors:\s*\[[^\]]*\](?:[^)]*)\)\s*:\s*null,',
            r'',
            content,
            flags=re.DOTALL
        )
        content = re.sub(
            r'color:\s*selected\s*\?\s*null\s*:\s*(Theme\.of\(context\)\.colorScheme\.surface),',
            r'color: selected ? Theme.of(context).colorScheme.primary : \1,',
            content
        )
        content = re.sub(
            r'(color:\s*selected\s*\?\s*Theme\.of\(context\)\.colorScheme\.primary\s*:\s*Theme\.of\(context\)\.colorScheme\.surface,\s*)borderRadius:\s*BorderRadius\.circular\(\s*20\s*\)',
            r'\1borderRadius: BorderRadius.circular(15)',
            content
        )
        
        # Fix FAB shape and gradient
        # Replace gradient and shape in the Container
        content = re.sub(
            r'gradient:\s*LinearGradient\(\s*colors:\s*\[\s*Theme\.of\(context\)\.colorScheme\.primary,\s*Color\(0xFF6B8AFF\)\s*\],\s*begin:[^,]+,\s*end:[^)]+\s*\),?\s*shape:\s*BoxShape\.circle,?',
            r'color: Theme.of(context).colorScheme.primary,\n            borderRadius: BorderRadius.circular(15),',
            content,
            flags=re.DOTALL
        )
        
        # The inner FloatingActionButton might have shape: BoxShape.circle or StadiumBorder, we must remove it or set it to 15
        # floatingActionButton shape
        content = re.sub(
            r'shape:\s*const\s*CircleBorder\(\),',
            r'shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),',
            content
        )
        content = re.sub(
            r'shape:\s*CircleBorder\(\),',
            r'shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),',
            content
        )

        if orig != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed chips and FAB in {filepath}")
