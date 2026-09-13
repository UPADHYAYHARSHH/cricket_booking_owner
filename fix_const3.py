import os
import re

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r'const\s+AppText\([^)]*color:\s*accentColor[^)]*\)', lambda m: m.group(0).replace('const ', ''), content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Removed const from AppText")
