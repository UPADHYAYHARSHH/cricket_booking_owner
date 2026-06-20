import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  User? get currentUser;

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
