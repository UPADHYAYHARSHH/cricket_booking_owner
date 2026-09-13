import os
import re

filepath = 'lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# We need to compute `isApproved` inside `build` method.
# In `build`, we can define:
# final isApproved = booking['status']?.toString().toLowerCase() == 'approved';
# final accentColor = isApproved ? AppColors.primaryDarkGreen : const Color(0xFFE65100);
# final lightAccentColor = isApproved ? AppColors.primaryDarkGreen.withOpacity(0.4) : const Color(0xFFFFB74D);

# Then replace hardcoded `Color(0xFFE65100)` with `accentColor`
# and `Color(0xFFFFB74D)` with `lightAccentColor`
# and `Color(0xFFFFCC80)` with `lightAccentColor`

build_start = r'Widget build\(BuildContext context\) {\s*final booking = widget.booking;'
build_replace = """Widget build(BuildContext context) {
    final booking = widget.booking;
    final isApproved = booking['status']?.toString().toLowerCase() == 'approved';
    final accentColor = isApproved ? AppColors.primaryDarkGreen : const Color(0xFFE65100);
    final lightAccentColor = isApproved ? AppColors.primaryDarkGreen.withOpacity(0.4) : const Color(0xFFFFB74D);
"""

content = re.sub(build_start, build_replace, content)

# Now replace colors within the build method ONLY!
# Let's just do a naive replace for those specific color strings
content = content.replace("const Color(0xFFE65100)", "accentColor")
content = content.replace("Color(0xFFE65100)", "accentColor")
content = content.replace("const Color(0xFFFFB74D)", "lightAccentColor")
content = content.replace("Color(0xFFFFB74D)", "lightAccentColor")
content = content.replace("const Color(0xFFFFCC80)", "lightAccentColor")
content = content.replace("Color(0xFFFFCC80)", "lightAccentColor")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated PendingApprovalCard colors")
