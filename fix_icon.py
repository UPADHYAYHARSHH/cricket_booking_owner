import os

filepath = 'lib/owner_booking/presentation/screens/bookings/bookings_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_icon = """
                                child: Icon(
                                  sportIcon(sportName),
                                  color: AppColors.primaryDarkGreen,
                                  size: 20,
                                ),
"""

new_icon = """
                                child: HugeIcon(
                                  icon: sportIcon(sportName),
                                  color: AppColors.primaryDarkGreen,
                                  size: 20,
                                ),
"""

content = content.replace(old_icon.strip(), new_icon.strip())

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed Icon in BookingsScreen")
