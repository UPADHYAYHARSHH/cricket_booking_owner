import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> init() async {
    // Small delay to ensure UI is ready and Supabase is fully initialized on web
    await Future.delayed(const Duration(milliseconds: 500));
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      emit(AuthUnauthenticated());
    } else {
      await checkDocumentStatus();
    }
  }

  Future<void> signInWithPhone(String phone) async {
    emit(AuthLoading());
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
      );
      emit(AuthOtpRequired(phone));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyOtp(String phone, String token) async {
    emit(AuthLoading());
    try {
      print("DEBUG: VERIFYING OTP: $phone with $token");
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      print("DEBUG: OTP RESPONSE: ${response.user != null ? 'User found' : 'No user'}");
      
      if (response.user != null) {
        await checkDocumentStatus();
      } else {
        print("DEBUG: verifyOtp failed - no user returned");
        emit(AuthError("Verification failed"));
      }
    } on AuthException catch (e) {
      print("DEBUG: verifyOtp AuthException: ${e.message}");
      emit(AuthError(e.message));
    } catch (e) {
      print("DEBUG: verifyOtp generic exception: $e");
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkDocumentStatus({int? forceStep}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      emit(AuthUnauthenticated());
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (forceStep == 1 || (forceStep == null && (data == null || data?['owner_name'] == null || data?['owner_name'].isEmpty))) {
        emit(AuthProfileIncomplete(1)); // Step 1: Personal Info
      } else if (forceStep == 2 || (forceStep == null && (data?['sports_config'] == null || data?['sports_config'] is! Map || (data?['sports_config'] as Map).isEmpty))) {
        emit(AuthProfileIncomplete(2)); // Step 2: Venue Type
      } else if (forceStep == 3 || (forceStep == null && (data?['venue_name'] == null || data?['venue_name'].isEmpty))) {
        emit(AuthProfileIncomplete(3)); // Step 3: Venue Details
      } else if (forceStep == 4 || (forceStep == null && (data?['ground_config'] == null || data?['ground_config'] is! Map || (data?['ground_config'] as Map).isEmpty))) {
        emit(AuthProfileIncomplete(4)); // Step 4: Ground / Court Info
      } else if (forceStep == 5 || (forceStep == null && (data?['amenities_config'] == null || data?['amenities_config'] is! Map || (data?['amenities_config'] as Map).isEmpty))) {
        emit(AuthProfileIncomplete(5)); // Step 5: Amenities
      } else if (forceStep == 6 || (forceStep == null && (data?['slot_config'] == null || data?['slot_config'] is! Map || (data?['slot_config'] as Map).isEmpty))) {
        emit(AuthProfileIncomplete(6)); // Step 6: Slot Configuration
      } else if (forceStep == 7 || (forceStep == null && (data?['pricing_config'] == null || data?['pricing_config'] is! Map || (data?['pricing_config'] as Map).isEmpty))) {
        emit(AuthProfileIncomplete(7)); // Step 7: Pricing Setup
      } else if (forceStep == 8 || (forceStep == null && (data?['kyc_config'] == null || data?['kyc_config'] is! Map || (data?['kyc_config'] as Map).isEmpty))) {
        emit(AuthProfileIncomplete(8)); // Step 8: Documentation & KYC
      } else if (forceStep == 9 || (forceStep == null && (data?['media_config'] == null || data?['media_config'] is! Map || (data?['media_config'] as Map).isEmpty))) {
        emit(AuthProfileIncomplete(9)); // Step 9: Photos & Media
      } else if (forceStep == 10 || (forceStep == null && data?['status'] != 'submitted')) {
        emit(AuthProfileIncomplete(10)); // Step 10: Review & Submit
      } else {
        emit(AuthSuccess());
      }
    } catch (e) {
      print("DEBUG: checkDocumentStatus error: $e");
      emit(AuthError("Sync Error: ${e.toString()}"));
    }
  }

  Future<void> savePersonalInfo({
    required String fullName,
    required String email,
    required String city,
    required String state,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').upsert({
        'id': user.id,
        'owner_name': fullName,
        'business_email': email,
        'city': city,
        'state': state,
        'phone': user.phone,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await checkDocumentStatus();
    } catch (e) {
      print("DEBUG: savePersonalInfo error: $e");
      emit(AuthError("Failed to save personal info: ${e.toString()}"));
    }
  }

  Future<void> saveVenueType({
    required Map<String, int> sportsConfig,
    required String category,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'sports_config': sportsConfig,
        'venue_category': category,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to save venue details: ${e.toString()}"));
    }
  }

  Future<void> saveVenueDetails({
    required String venueName,
    required String tagline,
    required String address,
    required String city,
    required String pincode,
    required String mapsLink,
    required String contact,
    required String yearEstablished,
    required String totalArea,
    required String landmark,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'venue_name': venueName,
        'venue_tagline': tagline,
        'address': address,
        'city': city,
        'pincode': pincode,
        'google_maps_link': mapsLink,
        'venue_contact': contact,
        'year_established': yearEstablished,
        'total_area': totalArea,
        'nearby_landmark': landmark,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to save venue identity: ${e.toString()}"));
    }
  }

  Future<void> saveGroundConfig({
    required Map<String, dynamic> groundConfig,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'ground_config': groundConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to save ground configurations: ${e.toString()}"));
    }
  }

  Future<void> saveAmenities({
    required Map<String, dynamic> amenitiesConfig,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'amenities_config': amenitiesConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to save amenities: ${e.toString()}"));
    }
  }

  Future<void> saveSlotConfig({
    required Map<String, dynamic> slotConfig,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'slot_config': slotConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to save slot configurations: ${e.toString()}"));
    }
  }

  Future<void> savePricingConfig({
    required Map<String, dynamic> pricingConfig,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'pricing_config': pricingConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to save pricing configurations: ${e.toString()}"));
    }
  }

  Future<void> saveKycConfig({
    required Map<String, dynamic> kycConfig,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'kyc_config': kycConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to save KYC details: ${e.toString()}"));
    }
  }

  Future<void> saveMediaConfig({
    required Map<String, dynamic> mediaConfig,
  }) async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'media_config': mediaConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to save media: ${e.toString()}"));
    }
  }

  Future<void> submitApplication() async {
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'status': 'submitted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      await checkDocumentStatus();
    } catch (e) {
      emit(AuthError("Failed to submit application: ${e.toString()}"));
    }
  }

  Future<void> uploadDocuments({
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
    emit(AuthLoading());
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').upsert({
        'id': user.id,
        'business_name': businessName,
        'business_email': businessEmail,
        'owner_name': ownerName,
        'phone': phone ?? user.phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'pan_url': panUrl,
        'aadhar_url': aadharUrl,
        'business_reg_url': businessRegUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthError("Failed to upload documents: ${e.toString()}"));
    }
  }

  Future<void> savePartialDetails({
    required String businessName,
    required String businessEmail,
    required String ownerName,
    String? phone,
    String? panUrl,
    String? aadharUrl,
    String? businessRegUrl,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').upsert({
        'id': user.id,
        'business_name': businessName,
        'business_email': businessEmail,
        'owner_name': ownerName,
        'phone': phone ?? user.phone,
        if (panUrl != null) 'pan_url': panUrl,
        if (aadharUrl != null) 'aadhar_url': aadharUrl,
        if (businessRegUrl != null) 'business_reg_url': businessRegUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Partial save error: $e");
    }
  }

  void emitLoading() => emit(AuthLoading());
  void emitError(String message) => emit(AuthError(message));

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    emit(AuthInitial());
  }
}
