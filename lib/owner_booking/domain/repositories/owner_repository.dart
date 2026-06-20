abstract class OwnerRepository {
  Future<Map<String, dynamic>?> getOwnerDetails(String userId);

  Future<bool> isEmailRegistered(String email);

  Future<void> createOwnerRecord({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
  });

  Future<int> getOnboardingStep(String userId);

  Future<void> savePersonalInfo({
    required String userId,
    required String fullName,
    required String email,
    required String city,
    required String state,
    required String phone,
  });

  Future<void> saveVenueType({
    required String userId,
    required Map<String, int> sportsConfig,
    required String category,
  });

  Future<void> saveVenueDetails({
    required String userId,
    required String venueName,
    required String tagline,
    required String address,
    required String city,
    required String pincode,
    required String mapsLink,
    required String contact,
  });

  Future<void> saveGroundConfig({
    required String userId,
    required Map<String, dynamic> groundConfig,
  });

  Future<void> saveAmenities({
    required String userId,
    required Map<String, dynamic> amenitiesConfig,
  });

  Future<void> saveSlotConfig({
    required String userId,
    required Map<String, dynamic> slotConfig,
  });

  Future<void> savePricingConfig({
    required String userId,
    required Map<String, dynamic> pricingConfig,
  });

  Future<void> saveKycConfig({
    required String userId,
    required Map<String, dynamic> kycConfig,
  });

  Future<void> saveMediaConfig({
    required String userId,
    required Map<String, dynamic> mediaConfig,
  });

  Future<void> savePartialDetails({
    required String userId,
    required String businessName,
    required String businessEmail,
    required String ownerName,
  });

  Future<void> submitApplication(String userId);

  Future<void> uploadDocuments({
    required String userId,
    required String businessName,
    required String businessEmail,
    required String ownerName,
    required String address,
    required String panUrl,
    required String aadharUrl,
    required double latitude,
    required double longitude,
    String? phone,
    String? businessRegUrl,
  });
}
