import os

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("const AppText(\n                                      text: \"Max 45m\",\n                                      size: 11,\n                                      weight: FontWeight.w600,\n                                      color: accentColor,\n                                    )", "AppText(\n                                      text: \"Max 45m\",\n                                      size: 11,\n                                      weight: FontWeight.w600,\n                                      color: accentColor,\n                                    )")

content = content.replace("const AppText(\n                                          text: widget.booking[\"status\"] == \"approved\" ? \"Awaiting Payment\" : \"Requested\",", "AppText(\n                                          text: widget.booking[\"status\"] == \"approved\" ? \"Awaiting Payment\" : \"Requested\",")

content = content.replace("const Icon(Icons.hourglass_top_rounded", "Icon(Icons.hourglass_top_rounded")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Removed const from AppText and Icon where accentColor is used")
