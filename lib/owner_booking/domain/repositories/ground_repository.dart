abstract class GroundRepository {
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Future<List<Map<String, dynamic>>> getGroundsForLocation(String locationId);

  Future<String> registerGround({
    required String ownerId,
    required String locationId,
    required String name,
    required String category,
    required String description,
    required String openingTime,
    required String closingTime,
    required List<String> imageUrls,
    Map<String, int>? pricingOverrides,
  });

  Future<void> updateGround({
    required String groundId,
    required Map<String, dynamic> data,
  });

  Future<void> insertGroundImages(String groundId, List<String> imageUrls);

  /// Replaces all of a ground's images with [imageUrls] (delete-then-insert,
  /// safe to call repeatedly e.g. from an edit flow).
  Future<void> replaceGroundImages(String groundId, List<String> imageUrls);

  Future<void> generateSlots(
    String groundId,
    String openingTime,
    String closingTime,
    Map<String, int> pricing,
  );

  /// Deletes future *available* slots and regenerates them.
  /// Booked/pending slots are left untouched.
  Future<void> regenerateFutureSlots(
    String groundId,
    String openingTime,
    String closingTime,
    Map<String, int> pricing,
  );
}
