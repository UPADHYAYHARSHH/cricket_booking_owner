abstract class BookingRepository {
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Stream<List<Map<String, dynamic>>> watchBookingsForGrounds(List<Object> groundIds);

  Future<List<Map<String, dynamic>>> fetchUsers(List<String> userIds);

  Future<List<Map<String, dynamic>>> fetchUserPastBookings(List<String> userIds);
}
