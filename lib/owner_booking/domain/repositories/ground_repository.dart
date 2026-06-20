abstract class GroundRepository {
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Future<String> registerGround({
    required String ownerId,
    required String name,
    required String category,
    required String description,
    required String openingTime,
    required String closingTime,
    required List<String> imageUrls,
    required List<String> amenities,
    required String address,
    required double latitude,
    required double longitude,
    Map<String, int>? pricingOverrides,
    List<String>? allCategories,
    Map<String, int>? sportsConfig,
  });

  Future<void> updateGround({
    required String groundId,
    required Map<String, dynamic> data,
  });

  Future<void> insertGroundImages(String groundId, List<String> imageUrls);

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
