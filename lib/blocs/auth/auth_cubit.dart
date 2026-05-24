import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> init() async {
    // Small delay to ensure UI is ready and Firebase/Supabase are fully initialized
    await Future.delayed(const Duration(milliseconds: 500));
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(AuthUnauthenticated());
    } else {
      if (!user.emailVerified) {
        emit(AuthEmailUnverified(user.email ?? ""));
      } else {
        await checkDocumentStatus();
      }
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    emit(AuthLoading());
    print("DEBUG SIGNUP: Starting signup flow for email: $email, phone: $phone");
    try {
      // 1. Check if email is already registered as an Owner in Supabase
      print("DEBUG SIGNUP: Querying Supabase 'owner_details' for business_email: $email");
      final existingOwner = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('business_email', email)
          .maybeSingle();

      if (existingOwner != null) {
        print("DEBUG SIGNUP: Found existing owner in Supabase 'owner_details'! Record details: $existingOwner");
        emit(AuthError("This email is already registered. Please login instead."));
        return;
      }
      print("DEBUG SIGNUP: No owner found in 'owner_details' for email: $email. Checking if email exists in public 'users' table (User App)...");

      // Check users table to print details if they exist in User App
      try {
        final existingUser = await Supabase.instance.client
            .from('users')
            .select()
            .eq('email', email)
            .maybeSingle();
        if (existingUser != null) {
          print("DEBUG SIGNUP: User exists in public 'users' table (User App)! Details: $existingUser");
        } else {
          print("DEBUG SIGNUP: No user found in public 'users' table.");
        }
      } catch (dbErr) {
        print("DEBUG SIGNUP: Optional query to 'users' table failed: $dbErr");
      }

      // 2. Since they are not in owner_details, we consider them a fresh owner.
      // Attempt Firebase signup
      try {
        print("DEBUG SIGNUP: Calling Firebase createUserWithEmailAndPassword...");
        final credential = await f_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        
        final user = credential.user;
        if (user != null) {
          print("DEBUG SIGNUP: Firebase signup succeeded! User ID: ${user.uid}. Sending email verification...");
          await user.sendEmailVerification();
          
          print("DEBUG SIGNUP: Preemptively upserting 'owner_details' in Supabase for ID: ${user.uid}...");
          await Supabase.instance.client.from('owner_details').upsert({
            'id': user.uid,
            'owner_name': fullName,
            'business_email': email,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          });

          emit(AuthEmailUnverified(email));
        } else {
          print("DEBUG SIGNUP: Firebase createUser returned null user.");
          emit(AuthError("Signup failed"));
        }
      } on f_auth.FirebaseAuthException catch (firebaseErr) {
        print("DEBUG SIGNUP: Firebase AuthException caught! Code: ${firebaseErr.code}, Message: ${firebaseErr.message}");
        if (firebaseErr.code == 'email-already-in-use') {
          print("DEBUG SIGNUP: Email is already in use in Firebase Auth. Attempting silent sign-in with typed password...");
          try {
            final credential = await f_auth.FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password);
            final user = credential.user;
            if (user != null) {
              print("DEBUG SIGNUP: Silent sign-in succeeded! User ID: ${user.uid}. Upserting 'owner_details' in Supabase...");
              await Supabase.instance.client.from('owner_details').upsert({
                'id': user.uid,
                'owner_name': fullName,
                'business_email': email,
                'phone': phone,
                'updated_at': DateTime.now().toIso8601String(),
              });

              if (!user.emailVerified) {
                print("DEBUG SIGNUP: User email is not verified yet. Sending verification email...");
                try {
                  await user.sendEmailVerification();
                } catch (_) {}
                emit(AuthEmailUnverified(email));
              } else {
                print("DEBUG SIGNUP: User email is already verified. Navigating to onboarding...");
                await checkDocumentStatus();
              }
            } else {
              print("DEBUG SIGNUP: Silent sign-in credential returned null user.");
              emit(AuthError("This email is already registered. Please login instead."));
            }
          } catch (signInErr) {
            print("DEBUG SIGNUP: Silent sign-in failed (likely password mismatch). Error details: $signInErr");
            emit(AuthError("An account with this email already exists (Customer). Please enter your correct password to activate your Turf Owner profile, or use a different email."));
          }
        } else {
          emit(AuthError(firebaseErr.message ?? "An error occurred during signup"));
        }
      }
    } catch (e) {
      print("DEBUG SIGNUP: Unexpected outer exception caught: $e");
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    emit(AuthLoading());
    try {
      final credential = await f_auth.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user != null) {
        if (!user.emailVerified) {
          try {
            await user.sendEmailVerification();
          } catch (e) {
            print("Failed to send verification email: $e");
          }
          emit(AuthEmailUnverified(email));
        } else {
          await checkDocumentStatus();
        }
      } else {
        emit(AuthError("Login failed"));
      }
    } on f_auth.FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? "Invalid email or password"));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkEmailVerification() async {
    emit(AuthLoading());
    try {
      final user = f_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = f_auth.FirebaseAuth.instance.currentUser;
        if (refreshedUser != null && refreshedUser.emailVerified) {
          await checkDocumentStatus();
        } else {
          emit(AuthEmailUnverified(user.email ?? ""));
          emit(AuthError("Email not verified yet. Please check your inbox."));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = f_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      emit(AuthError("Failed to resend email: ${e.toString()}"));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(AuthLoading());
    try {
      await f_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      emit(AuthPasswordResetSent());
    } on f_auth.FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? "Failed to send reset link"));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkDocumentStatus({int? forceStep}) async {
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(AuthUnauthenticated());
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', user.uid)
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
    required String phone,
  }) async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').upsert({
        'id': user.uid,
        'owner_name': fullName,
        'business_email': email,
        'city': city,
        'state': state,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await checkDocumentStatus(forceStep: 2);
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
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'sports_config': sportsConfig,
        'venue_category': category,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
      await checkDocumentStatus(forceStep: 3);
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
  }) async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
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
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
      await checkDocumentStatus(forceStep: 4);
    } catch (e) {
      emit(AuthError("Failed to save venue identity: ${e.toString()}"));
    }
  }

  Future<void> saveGroundConfig({
    required Map<String, dynamic> groundConfig,
  }) async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'ground_config': groundConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
      await checkDocumentStatus(forceStep: 5);
    } catch (e) {
      emit(AuthError("Failed to save ground configurations: ${e.toString()}"));
    }
  }

  Future<void> saveAmenities({
    required Map<String, dynamic> amenitiesConfig,
  }) async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'amenities_config': amenitiesConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
      await checkDocumentStatus(forceStep: 6);
    } catch (e) {
      emit(AuthError("Failed to save amenities: ${e.toString()}"));
    }
  }

  Future<void> saveSlotConfig({
    required Map<String, dynamic> slotConfig,
  }) async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'slot_config': slotConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
      await checkDocumentStatus(forceStep: 7);
    } catch (e) {
      emit(AuthError("Failed to save slot configurations: ${e.toString()}"));
    }
  }

  Future<void> savePricingConfig({
    required Map<String, dynamic> pricingConfig,
  }) async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'pricing_config': pricingConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
      await checkDocumentStatus(forceStep: 8);
    } catch (e) {
      emit(AuthError("Failed to save pricing configurations: ${e.toString()}"));
    }
  }

  Future<void> saveKycConfig({
    required Map<String, dynamic> kycConfig,
  }) async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'kyc_config': kycConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
      await checkDocumentStatus(forceStep: 9);
    } catch (e) {
      emit(AuthError("Failed to save KYC details: ${e.toString()}"));
    }
  }

  Future<void> saveMediaConfig({
    required Map<String, dynamic> mediaConfig,
  }) async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'media_config': mediaConfig,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
      await checkDocumentStatus(forceStep: 10);
    } catch (e) {
      emit(AuthError("Failed to save media: ${e.toString()}"));
    }
  }

  Future<void> submitApplication() async {
    emit(AuthLoading());
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').update({
        'status': 'submitted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.uid);
      
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
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').upsert({
        'id': user.uid,
        'business_name': businessName,
        'business_email': businessEmail,
        'owner_name': ownerName,
        if (phone != null) 'phone': phone,
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
    final user = f_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('owner_details').upsert({
        'id': user.uid,
        'business_name': businessName,
        'business_email': businessEmail,
        'owner_name': ownerName,
        if (phone != null) 'phone': phone,
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

  @deprecated
  Future<void> signInWithPhone(String phone) async {
    // Deprecated in favor of Firebase Email/Password Auth
  }

  @deprecated
  Future<void> verifyOtp(String phone, String token) async {
    // Deprecated in favor of Firebase Email/Password Auth
  }

  Future<void> logout() async {
    await f_auth.FirebaseAuth.instance.signOut();
    emit(AuthUnauthenticated());
  }
}
