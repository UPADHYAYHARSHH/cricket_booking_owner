import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # 2. Fix dashboard_cubit.dart
    if 'dashboard_cubit' in filepath:
        # Just use a very broad regex to replace whatever is between todayRevenue: ' and '
        content = re.sub(r"todayRevenue:\s*'.*?0'", "todayRevenue: '\u20b90'", content)
        content = re.sub(r"todayRevenue:\s*'.*?\$\{todayRevenue\.toInt\(\)\}'", "todayRevenue: '\u20b9${todayRevenue.toInt()}'", content)
        content = re.sub(r"revenueChangeLabel:\s*'.*?'", "revenueChangeLabel: '\u2014'", content, count=1) # only the first one

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_file('lib/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart')
print("Fixed issues with broad regex")
