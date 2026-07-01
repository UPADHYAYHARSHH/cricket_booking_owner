import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/auth_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/owner_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final OwnerRepository _ownerRepository;

  AuthCubit(this._authRepository, this._ownerRepository) : super(AuthInitial());

  Future<void> init() async {
    // Wait for Firebase to restore its persisted session from disk.
    // currentUser is unreliable on cold start; authStateChanges().first
    // only resolves once Firebase has confirmed the actual auth state.
    final user = await _authRepository.authStateChanges.first;
    if (user == null) {
      emit(AuthUnauthenticated());
    } else if (!user.emailVerified) {
      emit(AuthEmailUnverified(user.email ?? ''));
    } else {
      await _emitOnboardingStep(user.uid);
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    emit(AuthLoading());
    try {
      final isRegistered = await _ownerRepository.isEmailRegistered(email);
      if (isRegistered) {
        emit(AuthError('This email is already registered. Please login instead.'));
        return;
      }

      try {
        await _authRepository.signUp(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
        );
        final uid = _authRepository.currentUser?.uid;
        if (uid != null) {
          await _ownerRepository.createOwnerRecord(
            userId: uid,
            fullName: fullName,
            email: email,
            phone: phone,
          );
        }
        emit(AuthEmailUnverified(email));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Attempt silent sign-in with the same credentials
          try {
            await _authRepository.signIn(email: email, password: password);
            final user = _authRepository.currentUser;
            if (user != null) {
              await _ownerRepository.createOwnerRecord(
                userId: user.uid,
                fullName: fullName,
                email: email,
                phone: phone,
              );
              if (!user.emailVerified) {
                await _authRepository.sendVerificationEmail();
                emit(AuthEmailUnverified(email));
              } else {
                await _emitOnboardingStep(user.uid);
              }
            } else {
              emit(AuthError('This email is already registered. Please login instead.'));
            }
          } catch (_) {
            emit(AuthError(
              'An account with this email already exists. Enter your correct password to activate your Owner profile, or use a different email.',
            ));
          }
        } else {
          emit(AuthError(e.message ?? 'An error occurred during signup'));
        }
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authRepository.signIn(email: email, password: password);
      final user = _authRepository.currentUser;
      if (user != null) {
        if (!user.emailVerified) {
          try {
            await _authRepository.sendVerificationEmail();
          } catch (_) {}
          emit(AuthEmailUnverified(email));
        } else {
          // Ensure an owner_details row exists for users who were created
          // outside the signup flow (e.g. imported accounts, old system users).
          final existing = await _ownerRepository.getOwnerDetails(user.uid);
          if (existing == null) {
            await _ownerRepository.createOwnerRecord(
              userId: user.uid,
              fullName: user.displayName ?? '',
              email: email,
              phone: user.phoneNumber ?? '',
            );
          }
          await _emitOnboardingStep(user.uid);
        }
      } else {
        emit(AuthError('Login failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Invalid email or password'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkEmailVerification() async {
    emit(AuthLoading());
    try {
      await _authRepository.reloadUser();
      final user = _authRepository.currentUser;
      if (user != null && user.emailVerified) {
        await _emitOnboardingStep(user.uid);
      } else {
        emit(AuthEmailUnverified(user?.email ?? ''));
        emit(AuthError('Email not verified yet. Please check your inbox.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authRepository.sendVerificationEmail();
    } catch (e) {
      emit(AuthError('Failed to resend email: ${e.toString()}'));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordReset(email);
      emit(AuthPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? 'Failed to send reset link'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkDocumentStatus({int? forceStep}) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      final step = forceStep ?? await _ownerRepository.getOnboardingStep(user.uid);
      _emitStepState(step);
    } catch (e) {
      emit(AuthError('Sync Error: ${e.toString()}'));
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
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      // Guarantee the row exists before updating individual fields.
      // Users who log in (vs sign up) may not have an owner_details row yet.
      await _ownerRepository.createOwnerRecord(
        userId: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
      );
      await _ownerRepository.savePersonalInfo(
        userId: user.uid,
        fullName: fullName,
        email: email,
        city: city,
        state: state,
        phone: phone,
      );
      _emitStepState(2);
    } catch (e) {
      emit(AuthError('Failed to save personal info: ${e.toString()}'));
    }
  }

  Future<void> saveVenueType({
    required Map<String, int> sportsConfig,
    required String category,
  }) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.saveVenueType(
        userId: user.uid,
        sportsConfig: sportsConfig,
        category: category,
      );
      _emitStepState(3);
    } catch (e) {
      emit(AuthError('Failed to save venue details: ${e.toString()}'));
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
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.saveVenueDetails(
        userId: user.uid,
        venueName: venueName,
        tagline: tagline,
        address: address,
        city: city,
        pincode: pincode,
        mapsLink: mapsLink,
        contact: contact,
      );
      _emitStepState(4);
    } catch (e) {
      emit(AuthError('Failed to save venue identity: ${e.toString()}'));
    }
  }

  Future<void> saveGroundConfig({required Map<String, dynamic> groundConfig}) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.saveGroundConfig(
        userId: user.uid,
        groundConfig: groundConfig,
      );
      _emitStepState(5);
    } catch (e) {
      emit(AuthError('Failed to save ground configurations: ${e.toString()}'));
    }
  }

  Future<void> saveAmenities({required Map<String, dynamic> amenitiesConfig}) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.saveAmenities(
        userId: user.uid,
        amenitiesConfig: amenitiesConfig,
      );
      _emitStepState(6);
    } catch (e) {
      emit(AuthError('Failed to save amenities: ${e.toString()}'));
    }
  }

  Future<void> saveSlotConfig({required Map<String, dynamic> slotConfig}) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.saveSlotConfig(
        userId: user.uid,
        slotConfig: slotConfig,
      );
      _emitStepState(7);
    } catch (e) {
      emit(AuthError('Failed to save slot configurations: ${e.toString()}'));
    }
  }

  Future<void> savePricingConfig({required Map<String, dynamic> pricingConfig}) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.savePricingConfig(
        userId: user.uid,
        pricingConfig: pricingConfig,
      );
      _emitStepState(8);
    } catch (e) {
      emit(AuthError('Failed to save pricing configurations: ${e.toString()}'));
    }
  }

  Future<void> saveKycConfig({required Map<String, dynamic> kycConfig}) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.saveKycConfig(
        userId: user.uid,
        kycConfig: kycConfig,
      );
      _emitStepState(9);
    } catch (e) {
      emit(AuthError('Failed to save KYC details: ${e.toString()}'));
    }
  }

  Future<void> saveMediaConfig({required Map<String, dynamic> mediaConfig}) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.saveMediaConfig(
        userId: user.uid,
        mediaConfig: mediaConfig,
      );
      _emitStepState(10);
    } catch (e) {
      emit(AuthError('Failed to save media: ${e.toString()}'));
    }
  }

  Future<void> submitApplication() async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.submitApplication(user.uid);
      await _emitOnboardingStep(user.uid);
    } catch (e) {
      emit(AuthError('Failed to submit application: ${e.toString()}'));
    }
  }

  Future<void> savePartialDetails({
    required String businessName,
    required String businessEmail,
    required String ownerName,
  }) async {
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.savePartialDetails(
        userId: user.uid,
        businessName: businessName,
        businessEmail: businessEmail,
        ownerName: ownerName,
      );
    } catch (e) {
      emit(AuthError('Failed to save details: ${e.toString()}'));
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
    final user = _authRepository.currentUser;
    if (user == null) return;
    try {
      await _ownerRepository.uploadDocuments(
        userId: user.uid,
        businessName: businessName,
        businessEmail: businessEmail,
        ownerName: ownerName,
        address: address,
        panUrl: panUrl,
        aadharUrl: aadharUrl,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        businessRegUrl: businessRegUrl,
      );
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthError('Failed to upload documents: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  void emitLoading() => emit(AuthLoading());
  void emitError(String message) => emit(AuthError(message));

  Future<void> _emitOnboardingStep(String userId) async {
    final step = await _ownerRepository.getOnboardingStep(userId);
    _emitStepState(step);
  }

  void _emitStepState(int step) {
    if (step == 0) {
      emit(AuthSuccess());
    } else {
      emit(AuthProfileIncomplete(step));
    }
  }
}
