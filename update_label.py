import os

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('text: "Requested",', 'text: widget.booking["status"] == "approved" ? "Awaiting Payment" : "Requested",')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated card label")
