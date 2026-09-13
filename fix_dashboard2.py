import os
import re

filepath = 'lib/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r"if\s*\(\s*status\s*==\s*'pending'\s*\|\|\s*status\s*==\s*'requested'\s*\)\s*\{", "if (status == 'pending' || status == 'requested' || status == 'approved') {", content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated DashboardCubit correctly")
