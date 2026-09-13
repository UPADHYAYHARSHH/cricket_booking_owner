import os

filepath = 'lib/owner_booking/domain/repositories/booking_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("Future<void> deleteOrExpireBooking(", "Future<void> notifyUserToPay(String bookingId);\n  Future<void> deleteOrExpireBooking(")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated BookingRepository interface")
