import os
import re

for root, dirs, files in os.walk('lib'):
    for file in files:
        if not file.endswith('.dart'): continue
        filepath = os.path.join(root, file)
        
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        changed = False
        
        for i, line in enumerate(lines):
            if 'gradient:' in line and 'LinearGradient' in line:
                # check if there is an ElevatedButton within next 10 lines
                has_button = False
                for j in range(i, min(i+15, len(lines))):
                    if 'ElevatedButton' in lines[j] or 'TextButton' in lines[j] or 'OutlinedButton' in lines[j]:
                        has_button = True
                        break
                
                if has_button:
                    # Replace the entire gradient block with color: Theme.of(context).colorScheme.primary,
                    # We need to find the end of the LinearGradient block
                    # A naive way: count parentheses
                    gradient_start = i
                    code = "".join(lines[gradient_start:min(gradient_start+15, len(lines))])
                    
                    # Regex to match gradient block
                    match = re.search(r'gradient:\s*(?:const\s+)?LinearGradient\([^)]*colors:\s*\[[^\]]*\](?:[^)]*)\),?', code, re.DOTALL)
                    if match:
                        replaced = code.replace(match.group(0), 'color: Theme.of(context).colorScheme.primary,')
                        
                        # also replace borderRadius in the replaced code to 15
                        replaced = re.sub(r'BorderRadius\.circular\(\s*\d+\s*\)', 'BorderRadius.circular(15)', replaced)
                        
                        # Apply to lines
                        lines[gradient_start:min(gradient_start+15, len(lines))] = [replaced]
                        changed = True
                        
            # Also check if it's conditional gradient e.g. `gradient: condition ? LinearGradient(...) : null`
            if 'LinearGradient' in line and '?' in line and ':' in line:
                 has_button = False
                 for j in range(i, min(i+15, len(lines))):
                    if 'ElevatedButton' in lines[j] or 'TextButton' in lines[j]:
                        has_button = True
                        break
                 if has_button:
                     # e.g. gradient: allCompleted ? const LinearGradient(...) : null,
                     # replace with color: allCompleted ? Theme.of(context).colorScheme.primary : null,
                     code = "".join(lines[i:min(i+15, len(lines))])
                     match = re.search(r'gradient:\s*([^?]+)\?\s*(?:const\s+)?LinearGradient\([^)]*colors:\s*\[[^\]]*\][^)]*\)\s*:\s*null,?', code, re.DOTALL)
                     if match:
                         condition = match.group(1).strip()
                         replaced = code.replace(match.group(0), f'color: {condition} ? Theme.of(context).colorScheme.primary : null,')
                         replaced = re.sub(r'BorderRadius\.circular\(\s*\d+\s*\)', 'BorderRadius.circular(15)', replaced)
                         lines[i:min(i+15, len(lines))] = [replaced]
                         changed = True
                         
        if changed:
            # We messed up line counting by replacing slices with single strings containing newlines.
            # It's better to just write the joined string.
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write("".join(lines))
            print(f"Fixed {filepath}")
