abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthOtpRequired extends AuthState {
  final String phone;
  AuthOtpRequired(this.phone);
}

/// Step 1 of onboarding: Personal info incomplete (name, phone, city)
class AuthStep1Required extends AuthState {}

/// Step 2 of onboarding: KYC documents incomplete (PAN, Aadhar, bank details)
class AuthStep2Required extends AuthState {}

/// Step 3 of onboarding: Venue details incomplete (venue name, address)
class AuthStep3Required extends AuthState {}

class AuthLocationRequired extends AuthState {}

class AuthGroundRequired extends AuthState {
  final String locationId;
  AuthGroundRequired(this.locationId);
}

class AuthPendingApproval extends AuthState {
  final bool isUserVerified;
  final String userStatus; // 'pending', 'submitted', 'approved', 'rejected'
  final String? userRejectionReason;

  final bool isLocationVerified;
  final String locationStatus; // 'pending', 'submitted', 'approved', 'rejected'
  final String? locationRejectionReason;
  final String? locationId;
  final String? locationName;
  final String? locationAddress;
  final Map<String, dynamic>? locationData;
  final List<Map<String, dynamic>> allLocations;

  AuthPendingApproval({
    this.isUserVerified = false,
    this.userStatus = 'pending',
    this.userRejectionReason,
    this.isLocationVerified = false,
    this.locationStatus = 'pending',
    this.locationRejectionReason,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.locationData,
    this.allLocations = const [],
  });

  bool get isUserRejected =>
      userStatus == 'rejected' ||
      (userRejectionReason != null && userRejectionReason!.trim().isNotEmpty);

  bool get isLocationRejected =>
      locationStatus == 'rejected' ||
      (locationRejectionReason != null &&
          locationRejectionReason!.trim().isNotEmpty &&
          !isLocationVerified);

  bool get isAnyRejected => isUserRejected || isLocationRejected;
}

class AuthRejected extends AuthPendingApproval {
  final String reason;

  AuthRejected(
    this.reason, {
    super.isUserVerified,
    super.userStatus = 'rejected',
    super.userRejectionReason,
    super.isLocationVerified,
    super.locationStatus,
    super.locationRejectionReason,
    super.locationId,
    super.locationName,
    super.locationAddress,
    super.locationData,
    super.allLocations,
  });
}

class AuthEmailUnverified extends AuthState {
  final String email;
  AuthEmailUnverified(this.email);
}

class AuthPasswordResetSent extends AuthState {}
