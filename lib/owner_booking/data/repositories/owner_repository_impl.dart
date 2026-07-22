import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/owner_repository.dart';

class OwnerRepositoryImpl implements OwnerRepository {
  final SupabaseClient _supabase;

  OwnerRepositoryImpl(this._supabase);

  @override
  Future<Map<String, dynamic>?> getOwnerDetails(String userId) async {
    return await _supabase
        .from('owner_details')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    final result = await _supabase
        .from('owner_details')
        .select()
        .eq('business_email', email)
        .maybeSingle();
    return result != null;
  }

  @override
  Future<void> createOwnerRecord({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    await _supabase.from('owner_details').upsert({
      'id': userId,
      'owner_name': fullName,
      'business_email': email,
      'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  @override
  Future<void> uploadKycDocuments({
    required String userId,
    required String businessName,
    required String venueName,
    required String city,
    required String address,
    required String panUrl,
    required String aadharUrl,
    required Map<String, dynamic> bankDetails,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'business_name': businessName,
          'venue_name': venueName,
          'city': city,
          'address': address,
          'pan_url': panUrl,
          'aadhar_url': aadharUrl,
          'kyc_config': bankDetails, // Save bank info inside kyc_config
          'status': 'submitted', // Update status
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<int> getOnboardingStep(String userId) async {
    final data = await getOwnerDetails(userId);

    // No DB record at all — fresh user, start registration from the top
    if (data == null) return 1;

    // Completed via new onboarding flow
    final status = data['status'] as String?;
    if (status == 'submitted' || status == 'approved') return 0;

    // Completed via old registration flow (uploadDocuments sets address + pan_url)
    final address = data['address'] as String?;
    final panUrl = data['pan_url'] as String?;
    if ((address != null && address.isNotEmpty) ||
        (panUrl != null && panUrl.isNotEmpty)) {
      return 0;
    }

    // New user mid-onboarding — determine which step they left off at
    if (data['owner_name'] == null || (data['owner_name'] as String).isEmpty)
      return 1;
    if (data['sports_config'] == null ||
        data['sports_config'] is! Map ||
        (data['sports_config'] as Map).isEmpty)
      return 2;
    if (data['venue_name'] == null || (data['venue_name'] as String).isEmpty)
      return 3;
    if (data['ground_config'] == null ||
        data['ground_config'] is! Map ||
        (data['ground_config'] as Map).isEmpty)
      return 4;
    if (data['amenities_config'] == null ||
        data['amenities_config'] is! Map ||
        (data['amenities_config'] as Map).isEmpty)
      return 5;
    if (data['slot_config'] == null ||
        data['slot_config'] is! Map ||
        (data['slot_config'] as Map).isEmpty)
      return 6;
    if (data['pricing_config'] == null ||
        data['pricing_config'] is! Map ||
        (data['pricing_config'] as Map).isEmpty)
      return 7;
    if (data['kyc_config'] == null ||
        data['kyc_config'] is! Map ||
        (data['kyc_config'] as Map).isEmpty)
      return 8;
    if (data['media_config'] == null ||
        data['media_config'] is! Map ||
        (data['media_config'] as Map).isEmpty)
      return 9;
    return 10;
  }

  @override
  Future<void> savePersonalInfo({
    required String userId,
    required String fullName,
    required String email,
    required String city,
    required String state,
    required String phone,
  }) async {
    await _supabase.from('owner_details').upsert({
      'id': userId,
      'owner_name': fullName,
      'business_email': email,
      'city': city,
      'state': state,
      'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  @override
  Future<void> saveVenueType({
    required String userId,
    required Map<String, int> sportsConfig,
    required String category,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'sports_config': sportsConfig,
          'venue_category': category,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> saveVenueDetails({
    required String userId,
    required String venueName,
    required String tagline,
    required String address,
    required String city,
    required String pincode,
    required String mapsLink,
    required String contact,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'venue_name': venueName,
          'venue_tagline': tagline,
          'address': address,
          'city': city,
          'pincode': pincode,
          'google_maps_link': mapsLink,
          'venue_contact': contact,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> saveGroundConfig({
    required String userId,
    required Map<String, dynamic> groundConfig,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'ground_config': groundConfig,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> saveAmenities({
    required String userId,
    required Map<String, dynamic> amenitiesConfig,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'amenities_config': amenitiesConfig,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> saveSlotConfig({
    required String userId,
    required Map<String, dynamic> slotConfig,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'slot_config': slotConfig,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> savePricingConfig({
    required String userId,
    required Map<String, dynamic> pricingConfig,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'pricing_config': pricingConfig,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> saveKycConfig({
    required String userId,
    required Map<String, dynamic> kycConfig,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'kyc_config': kycConfig,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> saveMediaConfig({
    required String userId,
    required Map<String, dynamic> mediaConfig,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'media_config': mediaConfig,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> savePartialDetails({
    required String userId,
    required String businessName,
    required String businessEmail,
    required String ownerName,
  }) async {
    await _supabase.from('owner_details').upsert({
      'id': userId,
      'business_name': businessName,
      'business_email': businessEmail,
      'owner_name': ownerName,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> submitApplication(String userId) async {
    await _supabase
        .from('owner_details')
        .update({
          'status': 'submitted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    await _syncGroundsToTable(userId);
  }

  Future<void> _syncGroundsToTable(String userId) async {
    try {
      final ownerData = await getOwnerDetails(userId);
      if (ownerData == null) return;

      final groundConfig = ownerData['ground_config'] as Map<String, dynamic>?;
      final amenitiesConfig =
          ownerData['amenities_config'] as Map<String, dynamic>? ?? {};
      final slotConfig =
          ownerData['slot_config'] as Map<String, dynamic>? ?? {};

      if (groundConfig == null) return;

      await _supabase.from('grounds').delete().eq('owner_id', userId);
      await _supabase.from('locations').delete().eq('owner_id', userId);

      final locationResponse = await _supabase
          .from('locations')
          .insert({
            'owner_id': userId,
            'address': ownerData['address'] ?? '',
            'city': ownerData['city'] ?? '',
            'latitude': ownerData['latitude'] ?? 23.05,
            'longitude': ownerData['longitude'] ?? 72.55,
          })
          .select()
          .single();
      final locationId = locationResponse['id'] as String;

      final List<Map<String, dynamic>> groundsToInsert = [];

      groundConfig.forEach((sportKey, sportDetails) {
        if (sportDetails is Map<String, dynamic>) {
          final numCourtsRaw = sportDetails['num_courts'];
          int numCourts = 1;
          if (numCourtsRaw is int) numCourts = numCourtsRaw;
          if (numCourtsRaw is String)
            numCourts = int.tryParse(numCourtsRaw) ?? 1;

          final courtNames =
              sportDetails['court_names'] as List<dynamic>? ?? [];

          for (int i = 0; i < numCourts; i++) {
            final courtName = (courtNames.length > i)
                ? courtNames[i]
                : '$sportKey Court ${i + 1}';

            int price = 800;
            try {
              final pricing =
                  ownerData['pricing_config']?[sportKey]?['weekday']?['off_peak'];
              if (pricing != null)
                price = int.tryParse(pricing.toString()) ?? 800;
            } catch (_) {}

            groundsToInsert.add({
              'owner_id': userId,
              'location_id': locationId,
              'name': courtName,
              'description': ownerData['venue_tagline'] ?? '',
              'state': ownerData['state'] ?? '',
              'opening_time': _formatTime(slotConfig['opening_time']),
              'closing_time': _formatTime(slotConfig['closing_time']),
              'ground_type': sportKey,
              'category': sportKey,
              'turf_type':
                  sportDetails['surface_type'] ??
                  sportDetails['pitch_type'] ??
                  '',
              'players_allowed':
                  int.tryParse(
                    sportDetails['players_per_side']?.toString() ?? '12',
                  ) ??
                  12,
              'is_indoor': ownerData['venue_category'] == 'Indoor',
              'has_parking': amenitiesConfig['parking'] == true,
              'has_washroom': amenitiesConfig['washrooms'] == true,
              'has_floodlights':
                  sportDetails['floodlights']
                      ?.toString()
                      .toLowerCase()
                      .contains('yes') ??
                  false,
              'has_drinking_water': amenitiesConfig['drinking_water'] == true,
              'is_available': true,
              'price_per_hour': price,
              'rating': 4.5,
              'total_reviews': 0,
              'slot_duration': 60,
            });
          }
        }
      });

      if (groundsToInsert.isNotEmpty) {
        await _supabase.from('grounds').insert(groundsToInsert);
      }
    } catch (e) {
      // Sync failure should not fail the submit
    }
  }

  String _formatTime(String? t) {
    if (t == null) return '06:00:00';
    try {
      final tClean = t.replaceAll(RegExp(r'[^0-9:AMPMapm]'), '');
      final isPM = tClean.toLowerCase().contains('pm');
      final timeStr = tClean.replaceAll(RegExp(r'[AMPMapm]'), '').trim();
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final min = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:00';
    } catch (_) {
      return '06:00:00';
    }
  }

  @override
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
  }) async {
    await _supabase.from('owner_details').upsert({
      'id': userId,
      'business_name': businessName,
      'business_email': businessEmail,
      'owner_name': ownerName,
      'phone': ?phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'pan_url': panUrl,
      'aadhar_url': aadharUrl,
      'business_reg_url': ?businessRegUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ── 3-Step Onboarding ──

  @override
  Future<void> saveStep1({
    required String userId,
    required String fullName,
    required String phone,
    required String city,
  }) async {
    await _supabase.from('owner_details').upsert({
      'id': userId,
      'owner_name': fullName,
      'phone': phone,
      'city': city,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }

  @override
  Future<void> saveStep2({
    required String userId,
    required String businessName,
    required String panUrl,
    required String aadharUrl,
    required Map<String, dynamic> bankDetails,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'business_name': businessName,
          'pan_url': panUrl,
          'aadhar_url': aadharUrl,
          'kyc_config': bankDetails,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> saveStep3({
    required String userId,
    required String venueName,
    required String address,
    required String city,
    required String googleMapsLink,
    required double latitude,
    required double longitude,
  }) async {
    await _supabase
        .from('owner_details')
        .update({
          'venue_name': venueName,
          'address': address,
          'city': city,
          'google_maps_link': googleMapsLink,
          'latitude': latitude,
          'longitude': longitude,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    await submitApplication(userId);
  }
}
