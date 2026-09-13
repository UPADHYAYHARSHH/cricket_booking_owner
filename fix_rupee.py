import os

def fix_rupee(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # replace literal ? with ?
    content = content.replace('"?$amount"', '"\u20b9$amount"')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_rupee('lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart')
fix_rupee('lib/owner_booking/presentation/screens/dashboard/widgets/today_booking_card.dart')
print("Rupee symbol fixed")
