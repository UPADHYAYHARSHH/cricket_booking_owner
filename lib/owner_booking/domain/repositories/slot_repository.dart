abstract class SlotRepository {
  Future<Map<String, dynamic>?> getOwnerDetails(String userId);

  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Stream<List<Map<String, dynamic>>> watchBookingsForGround(String groundId);
}
