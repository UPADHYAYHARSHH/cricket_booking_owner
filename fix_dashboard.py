import os

filepath = 'lib/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("if (status == 'requested' || status == 'pending') {", "if (status == 'requested' || status == 'pending' || status == 'approved') {")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated DashboardCubit")
