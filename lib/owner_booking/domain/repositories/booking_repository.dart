abstract class BookingRepository {
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Stream<List<Map<String, dynamic>>> watchBookingsForGrounds(List<Object> groundIds);

  Future<List<Map<String, dynamic>>> fetchUsers(List<String> userIds);

  Future<List<Map<String, dynamic>>> fetchUserPastBookings(List<String> userIds);

  /// Fetches a single booking (joined with its ground) for ticket scan-in.
  Future<Map<String, dynamic>?> getBookingForCheckIn(String bookingId);

  /// Marks a booking as checked-in/approved at the venue.
  Future<void> checkInBooking(String bookingId);

  /// Fetches all of an owner's bookings, each joined with its ground's
  /// name, sport category and location id — used to build the revenue report.
  Future<List<Map<String, dynamic>>> getOwnerBookingsWithDetails(String ownerId);
}
