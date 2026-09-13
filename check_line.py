import os

with open('lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
    
for i, line in enumerate(lines):
    if '$amount' in line:
        print(f"Line {i}: {repr(line)}")
