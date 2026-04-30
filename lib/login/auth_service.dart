import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 Save / update user
  Future<void> saveUser(User user, String provider) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email ?? "",
        'phone': user.phoneNumber ?? "",
        'name': user.displayName ?? "",
        'photo': user.photoURL ?? "",
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 🔹 Google Sign-In
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    await saveUser(result.user!, "google");

    return result.user;
  }

  /// 🔹 Email Signup
  Future<User?> signUpEmail(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await saveUser(result.user!, "email");
    return result.user;
  }

  /// 🔹 Email Login
  Future<User?> loginEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await saveUser(result.user!, "email");
    return result.user;
  }

  /// 🔹 Current User
  User? get currentUser => _auth.currentUser;
}