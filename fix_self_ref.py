import os

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix self references
content = content.replace("final accentColor = isApproved ? AppColors.primaryDarkGreen : accentColor;", "final accentColor = isApproved ? AppColors.primaryDarkGreen : const Color(0xFFE65100);")
content = content.replace("final lightAccentColor = isApproved ? AppColors.primaryDarkGreen.withOpacity(0.4) : lightAccentColor;", "final lightAccentColor = isApproved ? AppColors.primaryDarkGreen.withOpacity(0.4) : const Color(0xFFFFB74D);")

# Fix `const Icon` with dynamic colors
content = content.replace("const Icon(Icons.timer_outlined, size: 15, color: accentColor)", "Icon(Icons.timer_outlined, size: 15, color: accentColor)")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed variables and const Icon in pending_approval_card.dart")
