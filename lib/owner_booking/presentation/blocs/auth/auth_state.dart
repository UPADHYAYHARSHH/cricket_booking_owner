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

class AuthPendingApproval extends AuthState {}

class AuthRejected extends AuthState {
  final String reason;
  AuthRejected(this.reason);
}

class AuthEmailUnverified extends AuthState {
  final String email;
  AuthEmailUnverified(this.email);
}

class AuthPasswordResetSent extends AuthState {}
