import os
import re

def fix_rupee(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # replace text: "?$amount" with text: "?$amount"
    content = re.sub(r'text:\s*"\?\$amount"', 'text: "\u20b9$amount"', content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_rupee('lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart')
fix_rupee('lib/owner_booking/presentation/screens/dashboard/widgets/today_booking_card.dart')
print("Rupee symbol fixed")
