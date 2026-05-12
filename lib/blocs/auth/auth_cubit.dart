import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

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
      emit(AuthInitial());
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
      } else if (data?['pan_url'] == null || data?['aadhar_url'] == null) {
        emit(AuthDocumentsRequired()); // Step 4: Documents
      } else {
        emit(AuthSuccess());
      }
    } catch (e) {
      emit(AuthProfileIncomplete(1));
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
