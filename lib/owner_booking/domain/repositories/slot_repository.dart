abstract class SlotRepository {
  Future<Map<String, dynamic>?> getOwnerDetails(String userId);

  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Stream<List<Map<String, dynamic>>> watchBookingsForGround(String groundId);

  Future<Map<String, dynamic>> insertOwnerBooking({
    required String groundId,
    required String slotTime,
    required int price,
    required String sportName,
    required String period,
    String? note,
  });

  Future<void> deleteOwnerBooking(String bookingId);
}
