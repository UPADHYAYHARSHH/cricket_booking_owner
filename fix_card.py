import os

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('Request Approved! dYZ%', 'Request Approved! \u2705')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed pending_approval_card.dart")
