import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  User? get currentUser;

  /// Emits the current user (or null) once Firebase has restored its persisted
  /// session, then continues to emit on every subsequent auth-state change.
  Stream<User?> get authStateChanges;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> reloadUser();

  Future<void> sendVerificationEmail();

  Future<void> logout();
}
