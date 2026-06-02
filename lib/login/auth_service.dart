
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // =====================================================
  // INSTANCES
  // =====================================================

  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // =====================================================
  // CURRENT USER
  // =====================================================

  User? get currentUser => auth.currentUser;

  bool isLoggedIn() {
    return auth.currentUser != null;
  }

  // =====================================================
  // DOCUMENT ID = EMAIL
  // =====================================================

  String getUserDocId(User user) {
    final email =
        user.email?.trim().toLowerCase() ?? "";

    if (email.isEmpty) {
      throw Exception("Email not found");
    }

    return email;
  }

  // =====================================================
  // GOOGLE LOGIN
  // =====================================================

  Future<User?> googleLogin() async {
    try {
      final GoogleSignIn googleSignIn =
          GoogleSignIn();

      final GoogleSignInAccount?
          googleUser =
          await googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication
          googleAuth =
          await googleUser.authentication;

      final credential =
          GoogleAuthProvider.credential(
        accessToken:
            googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await auth.signInWithCredential(
        credential,
      );

      final User? user = result.user;

      if (user != null) {
        await saveUser(user);
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // SAVE USER TO FIRESTORE
  // =====================================================

  Future<void> saveUser(User user) async {
    try {
      final docId = getUserDocId(user);

      final token =
          await FirebaseMessaging.instance
                  .getToken() ??
              "";

      final docRef = firestore
          .collection("users")
          .doc(docId);

      final existing =
          await docRef.get();

      final oldData =
          existing.data() ?? {};

      await docRef.set(
        {
          "docId": docId,

          "uid": user.uid,

          "email": user.email ?? "",

          "name":
              user.displayName ?? "",

          "firstName":
              oldData["firstName"] ?? "",

          "lastName":
              oldData["lastName"] ?? "",

          "phone":
              oldData["phone"] ?? "",

          "address":
              oldData["address"] ?? "",

          "photo":
              user.photoURL ??
                  oldData["photo"] ??
                  "",

          "fcmToken": token,

          "createdAt":
              oldData["createdAt"] ??
                  FieldValue.serverTimestamp(),

          "updatedAt":
              FieldValue.serverTimestamp(),

          "lastLogin":
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // UPDATE FCM TOKEN
  // =====================================================

  Future<void> updateFcmToken() async {
    try {
      final user = currentUser;

      if (user == null) return;

      final token =
          await FirebaseMessaging.instance
                  .getToken() ??
              "";

      await firestore
          .collection("users")
          .doc(getUserDocId(user))
          .set(
        {
          "fcmToken": token,
          "updatedAt":
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  // =====================================================
  // GET CURRENT USER DATA
  // =====================================================

  Future<Map<String, dynamic>?>
      fetchCurrentUserData() async {
    try {
      final user = currentUser;

      if (user == null) return null;

      final doc = await firestore
          .collection("users")
          .doc(getUserDocId(user))
          .get();

      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // =====================================================
  // UPDATE PROFILE
  // =====================================================

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String photo,
  }) async {
    try {
      final user = currentUser;

      if (user == null) return;

      final docId = getUserDocId(user);

      final fullName =
          "$firstName $lastName".trim();

      await user.updateDisplayName(
        fullName,
      );

      await firestore
          .collection("users")
          .doc(docId)
          .set(
        {
          "firstName": firstName,
          "lastName": lastName,
          "name": fullName,
          "email": email,
          "phone": phone,
          "address": address,
          "photo": photo,
          "updatedAt":
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    await auth.signOut();
  }
}

