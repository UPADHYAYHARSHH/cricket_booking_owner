import os

filepath = 'lib/owner_booking/presentation/blocs/bookings/bookings_cubit.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

new_method = """
  Future<void> notifyUserToPay(String bookingId) async {
    try {
      await _bookingRepository.notifyUserToPay(bookingId);
    } catch (e) {
      print("Error notifying user: $e");
      rethrow;
    }
  }

  Future<void> declineBooking(
"""

content = content.replace("Future<void> declineBooking(", new_method)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated BookingsCubit")
