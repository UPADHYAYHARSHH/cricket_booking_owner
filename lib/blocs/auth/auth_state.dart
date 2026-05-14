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

class AuthDocumentsRequired extends AuthState {}

class AuthProfileIncomplete extends AuthState {
  final int step;
  AuthProfileIncomplete(this.step);
}
