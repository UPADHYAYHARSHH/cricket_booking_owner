abstract class BookingRepository {
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Stream<List<Map<String, dynamic>>> watchBookingsForGrounds(List<Object> groundIds);

  Future<List<Map<String, dynamic>>> fetchUsers(List<String> userIds);

  Future<List<Map<String, dynamic>>> fetchUserPastBookings(List<String> userIds);

  /// Fetches a single booking (joined with its ground) for ticket scan-in.
  Future<Map<String, dynamic>?> getBookingForCheckIn(String bookingId);

  /// Marks a booking as checked-in/approved at the venue.
  Future<void> checkInBooking(String bookingId);

  /// Sends a check-in notification to the user after successful scan.
  Future<void> sendCheckInNotification({
    required String userId,
    required String bookingId,
    required String groundName,
    required String checkInTime,
    required String checkInDate,
  });

  /// Fetches all of an owner's bookings, each joined with its ground's
  /// name, sport category and location id — used to build the revenue report.
  Future<List<Map<String, dynamic>>> getOwnerBookingsWithDetails(String ownerId);

  /// Approves a requested booking and notifies the user to pay within 45 minutes.
  Future<void> approveBooking(String bookingId);

  /// Deletes or expires a booking (e.g. timeout or declined) and frees slots.
  Future<void> notifyUserToPay(String bookingId);
  Future<void> deleteOrExpireBooking(String bookingId, {String reason = 'declined_by_owner'});

  /// Fetches all cancelled / declined bookings for the owner's venues.
  Future<List<Map<String, dynamic>>> getOwnerCancellations(String ownerId);

  /// Cancels a confirmed or paid booking by the owner.
  /// Issues 100% refund in Playora Coins to the user's wallet,
  /// records in cancellation_history, sends notification, and frees slot if requested.
  Future<Map<String, dynamic>> cancelBookingByOwner({
    required String bookingId,
    required String reason,
    bool reopenSlot = true,
  });
}
