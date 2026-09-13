import os
import re

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# The error says line 396. It's likely `const AppText(`
# We will use regex to find `const AppText(` followed by `text: widget.booking["status"]`
# Actually, just search for `const AppText(` and `text: widget.booking["status"]` and replace `const AppText` with `AppText`

pattern = r'const\s+AppText\(\s*text:\s*widget\.booking\["status"\]'
replacement = r'AppText(\n                                          text: widget.booking["status"]'
content = re.sub(pattern, replacement, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Removed const from AppText")
