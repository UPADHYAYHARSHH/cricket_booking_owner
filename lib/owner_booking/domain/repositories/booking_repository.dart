abstract class BookingRepository {
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Stream<List<Map<String, dynamic>>> watchBookingsForGrounds(List<Object> groundIds);

  Future<List<Map<String, dynamic>>> fetchUsers(List<String> userIds);

  Future<List<Map<String, dynamic>>> fetchUserPastBookings(List<String> userIds);

  /// Fetches a single booking (joined with its ground) for ticket scan-in.
  Future<Map<String, dynamic>?> getBookingForCheckIn(String bookingId);

  /// Marks a booking as checked-in/approved at the venue.
  Future<void> checkInBooking(String bookingId);
}
