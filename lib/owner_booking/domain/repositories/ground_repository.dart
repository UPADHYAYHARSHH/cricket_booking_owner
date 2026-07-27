abstract class GroundRepository {
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId);

  Future<List<Map<String, dynamic>>> getGroundsForLocation(String locationId);

  Future<String> registerGround({
    required String ownerId,
    required String locationId,
    required String category,
    required String openingTime,
    required String closingTime,
    required List<String> operatingDays,
    required String slotDuration,
    Map<String, int>? pricingOverrides,
  });

  Future<void> updateGround({
    required String groundId,
    required Map<String, dynamic> data,
  });

  Future<void> toggleGroundAvailability({
    required String groundId,
    required bool isAvailable,
  });
}
