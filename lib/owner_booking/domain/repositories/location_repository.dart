abstract class LocationRepository {
  Future<List<Map<String, dynamic>>> getOwnerLocations(String ownerId);

  Future<String> registerLocation({
    required String ownerId,
    required String address,
    required String city,
    required String description,
    required String privacyPolicy,
    required String googleMapsLink,
    required double latitude,
    required double longitude,
    required List<String> amenities,
  });

  Future<void> updateLocation({
    required String locationId,
    required Map<String, dynamic> data,
  });

  /// Soft-deletes a location: it stops showing in the owner's list and its
  /// grounds disappear from the client app, but the row (and its booking
  /// history) is kept for records.
  Future<void> softDeleteLocation(String locationId);

  Future<String> uploadLocationDocument({
    required String ownerId,
    required String locationId,
    required String filePath,
  });

  Future<void> syncLocationImages({
    required String ownerId,
    required String locationId,
    required List<String> allImages,
    required List<String> newImagesToUpload,
  });
}
