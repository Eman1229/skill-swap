import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # Find all styleFrom blocks roughly by looking for "styleFrom("
    # Since regex for nested parentheses is hard, we can use a simpler approach:
    # Just replace shapes specifically around buttons.
    
    # Regex to match styleFrom block (non-greedy, but we might stop too early if there are nested parens).
    # Since we know the typical format is:
    # style: ElevatedButton.styleFrom(
    #   ...
    #   shape: RoundedRectangleBorder(...),
    #   ...
    # )
    
    # Let's replace any shape: ... that is followed by a closing paren or comma.
    # Actually, a more robust way: Find all occurrences of `shape: ` and check if the preceding code has `styleFrom`.
    
    # Let's just do it with regex for the shape definitions that are typically in buttons.
    # We will replace them with the new shape.
    
    new_shape = "shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))"
    
    # We will replace StadiumBorder
    content = re.sub(r'shape:\s*(?:const\s+)?StadiumBorder\(\s*\)', new_shape, content)
    
    # We will replace RoundedRectangleBorder with ANY radius to 15, BUT ONLY IF it's likely a button.
    # To be safe, we'll replace it everywhere because 15 is a standard corner radius in this app now.
    # But wait, cards might have 8 or 10. Let's ONLY replace it if it's inside `styleFrom` or `style:` or `Button`.
    
    # Let's read line by line. We track if we are inside a button style.
    lines = content.split('\n')
    inside_style_from = False
    paren_depth = 0
    
    for i, line in enumerate(lines):
        if 'styleFrom(' in line:
            inside_style_from = True
            paren_depth += line.count('(') - line.count(')')
            
        elif inside_style_from:
            paren_depth += line.count('(') - line.count(')')
            
            # Check for shape:
            if 'shape:' in line:
                # Replace the line if it has StadiumBorder or RoundedRectangleBorder
                if 'StadiumBorder' in line or 'RoundedRectangleBorder' in line:
                    # We might need to handle multi-line shapes.
                    pass
            
            if paren_depth <= 0:
                inside_style_from = False

    # Given Dart's formatting, multi-line shape declarations are common.
    # Let's just write a regex that matches `ElevatedButton.styleFrom(` up to its closing `)`
    # Since Python regex doesn't support recursive matching easily, we'll write a small parser.
    pass

def process_file_parser(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    orig = content
    # Find indices of 'styleFrom('
    idx = 0
    while True:
        idx = content.find('styleFrom(', idx)
        if idx == -1:
            break
            
        # Find the matching closing parenthesis
        depth = 0
        end_idx = -1
        for i in range(idx + 9, len(content)):
            if content[i] == '(':
                depth += 1
            elif content[i] == ')':
                depth -= 1
                if depth == 0:
                    end_idx = i
                    break
                    
        if end_idx != -1:
            # We have the block: content[idx:end_idx]
            block = content[idx:end_idx]
            
            # Replace shape inside the block
            new_shape = "shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))"
            
            # 1. StadiumBorder
            block = re.sub(r'shape:\s*(?:const\s+)?StadiumBorder\(\s*\)', new_shape, block)
            # 2. RoundedRectangleBorder (single line)
            block = re.sub(r'shape:\s*(?:const\s+)?RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.circular\(\s*\d+\s*\)\s*\)', new_shape, block)
            
            # 3. What if it's multi-line?
            block = re.sub(r'shape:\s*(?:const\s+)?RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.circular\(\s*\d+\s*\),\s*\)', new_shape, block, flags=re.DOTALL)
            
            content = content[:idx] + block + content[end_idx:]
            
        idx += 10

    if orig != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file_parser(os.path.join(root, file))
