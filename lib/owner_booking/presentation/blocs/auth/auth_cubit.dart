import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/auth_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/owner_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/location_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/ground_repository.dart';
import 'package:turfpro_owner/common/services/notification_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final OwnerRepository _ownerRepository;
  final LocationRepository _locationRepository;
  final GroundRepository _groundRepository;

  AuthCubit(
    this._authRepository,
    this._ownerRepository,
    this._locationRepository,
    this._groundRepository,
  ) : super(AuthInitial());

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
        emit(
          AuthError('This email is already registered. Please login instead.'),
        );
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
              emit(
                AuthError(
                  'This email is already registered. Please login instead.',
                ),
              );
            }
          } catch (_) {
            emit(
              AuthError(
                'An account with this email already exists. Enter your correct password to activate your Owner profile, or use a different email.',
              ),
            );
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

  Future<void> submitKycDocuments({
    required String businessName,
    required String venueName,
    required String city,
    required String address,
    required String panUrl,
    required String aadharUrl,
    required Map<String, dynamic> bankDetails,
  }) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(AuthError('User not authenticated'));
      return;
    }

    try {
      await _ownerRepository.uploadKycDocuments(
        userId: user.uid,
        businessName: businessName,
        venueName: venueName,
        city: city,
        address: address,
        panUrl: panUrl,
        aadharUrl: aadharUrl,
        bankDetails: bankDetails,
      );
      // Re-evaluate onboarding step
      await _emitOnboardingStep(user.uid);
    } catch (e) {
      emit(AuthError('Failed to submit KYC documents: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    await NotificationService.clearFcmToken();
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  void emitLoading() => emit(AuthLoading());
  void emitError(String message) => emit(AuthError(message));

  // ── 3-Step Onboarding Saves ──

  Future<void> saveStep1({
    required String fullName,
    required String phone,
    required String city,
  }) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(AuthError('Not authenticated'));
      return;
    }
    try {
      await _ownerRepository.saveStep1(
        userId: user.uid,
        fullName: fullName,
        phone: phone,
        city: city,
      );
      await _emitOnboardingStep(user.uid);
      // Save appeared to succeed but step gate still thinks personal info is incomplete
      if (!isClosed && state is AuthStep1Required) {
        emit(
          AuthError(
            'Could not save personal details. Please select a city from the list and try again.',
          ),
        );
      }
    } catch (e) {
      emit(AuthError('Failed to save: ${e.toString()}'));
    }
  }

  Future<void> saveStep2({
    required String businessName,
    required String panUrl,
    required String aadharUrl,
    required Map<String, dynamic> bankDetails,
  }) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(AuthError('Not authenticated'));
      return;
    }
    try {
      await _ownerRepository.saveStep2(
        userId: user.uid,
        businessName: businessName,
        panUrl: panUrl,
        aadharUrl: aadharUrl,
        bankDetails: bankDetails,
      );
      await _emitOnboardingStep(user.uid);
    } catch (e) {
      emit(AuthError('Failed to save: ${e.toString()}'));
    }
  }

  Future<void> saveStep3({
    required String venueName,
    required String address,
    required String city,
    required String description,
    required String googleMapsLink,
    required double latitude,
    required double longitude,
    required List<String> amenities,
  }) async {
    emit(AuthLoading());
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(AuthError('Not authenticated'));
      return;
    }
    try {
      // Create the first venue location (same fields as Add Location)
      await _locationRepository.registerLocation(
        ownerId: user.uid,
        address: address,
        city: city,
        description: description,
        privacyPolicy: '',
        googleMapsLink: googleMapsLink,
        latitude: latitude,
        longitude: longitude,
        amenities: amenities,
      );

      await _ownerRepository.saveStep3(
        userId: user.uid,
        venueName: venueName,
        address: address,
        city: city,
        googleMapsLink: googleMapsLink,
        latitude: latitude,
        longitude: longitude,
      );
      emit(AuthPendingApproval());
    } catch (e) {
      emit(AuthError('Failed to save: ${e.toString()}'));
    }
  }

  Future<void> _emitOnboardingStep(String userId) async {
    try {
      final d = await _ownerRepository.getOwnerDetails(userId);

      // Already approved — go to dashboard
      if (d?['status'] == 'approved') {
        final locations = await _locationRepository.getOwnerLocations(userId);
        if (locations.isEmpty) {
          emit(AuthLocationRequired());
          return;
        }
        
        final grounds = await _groundRepository.getOwnerGrounds(userId);
        if (grounds.isEmpty) {
          emit(AuthGroundRequired(locations.first['id'].toString()));
          return;
        }

        await NotificationService.initialize();
        emit(AuthSuccess());
        return;
      }

      // Already submitted — waiting for admin
      if (d?['status'] == 'submitted') {
        emit(AuthPendingApproval());
        return;
      }

      // Rejected by admin
      if (d?['status'] == 'rejected') {
        emit(AuthRejected(d?['rejection_reason'] as String? ?? ''));
        return;
      }

      // Step 1: personal info — need name, phone, and city
      final name = _asTrimmedString(d?['owner_name']);
      final phone = _asTrimmedString(d?['phone']);
      final city = _asTrimmedString(d?['city']);
      if (name.isEmpty || phone.isEmpty || city.isEmpty) {
        emit(AuthStep1Required());
        return;
      }

      // Step 2: KYC documents — need PAN, Aadhar, bank details
      final panUrl = _asTrimmedString(d?['pan_url']);
      final aadharUrl = _asTrimmedString(d?['aadhar_url']);
      final kycConfig = d?['kyc_config'];
      final hasBank =
          kycConfig is Map &&
          (_asTrimmedString(kycConfig['account_number']).isNotEmpty ||
              _asTrimmedString(kycConfig['acc_number']).isNotEmpty);
      if (panUrl.isEmpty || aadharUrl.isEmpty || !hasBank) {
        emit(AuthStep2Required());
        return;
      }

      // Step 3: venue details — need venue name, address, and a locations row
      final venueName = _asTrimmedString(d?['venue_name']);
      final address = _asTrimmedString(d?['address']);
      final locations = await _locationRepository.getOwnerLocations(userId);
      if (venueName.isEmpty || address.isEmpty || locations.isEmpty) {
        emit(AuthStep3Required());
        return;
      }

      // All steps done but status not yet submitted — auto-submit
      await _ownerRepository.submitApplication(userId);
      emit(AuthPendingApproval());
    } catch (e) {
      emit(AuthError('Failed to verify status: ${e.toString()}'));
    }
  }

  /// Coerce DB scalars (String/num) to a trimmed string for onboarding gates.
  static String _asTrimmedString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }
}
