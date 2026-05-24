import 'package:firebase_auth/firebase_auth.dart' as f_auth;

String? get currentUserId => f_auth.FirebaseAuth.instance.currentUser?.uid;
String? get currentUserEmail => f_auth.FirebaseAuth.instance.currentUser?.email;
String? get currentUserPhone => f_auth.FirebaseAuth.instance.currentUser?.phoneNumber;
bool get isUserLoggedIn => f_auth.FirebaseAuth.instance.currentUser != null;
