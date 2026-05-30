import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  /// =========================================================
  /// FIREBASE
  /// =========================================================

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  /// =========================================================
  /// CURRENT USER
  /// =========================================================

  User? get currentUser =>
      auth.currentUser;

  /// =========================================================
  /// USER DOC ID
  /// =========================================================

  /// USERS & PROVIDERS:
  /// PHONE NUMBER ONLY

  String getUserDocId(
    User user,
  ) {
    final phone =
        user.phoneNumber
            ?.trim() ??
        "";

    if (phone.isEmpty) {
      throw Exception(
        "Phone number not found",
      );
    }

    return phone;
  }

  /// =========================================================
  /// ADMIN DOC ID
  /// =========================================================

  String getAdminDocId(
    User user,
  ) {
    final email =
        user.email
            ?.trim()
            .toLowerCase() ??
        "";

    if (email.isEmpty) {
      throw Exception(
        "Email not found",
      );
    }

    return email;
  }

  /// =========================================================
  /// CHECK USER EXISTS
  /// =========================================================

  Future<DocumentSnapshot?> findUserByPhone(
    String phone,
  ) async {
    try {
      final doc =
          await firestore
              .collection(
                "users",
              )
              .doc(phone)
              .get();

      if (doc.exists) {
        return doc;
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// =========================================================
  /// SAVE USER
  /// =========================================================

  Future<void> savePhoneUser(
    User user,
  ) async {
    try {
      final docId =
          getUserDocId(user);

      final existing =
          await firestore
              .collection(
                "users",
              )
              .doc(docId)
              .get();

      Map<String, dynamic>
          oldData = {};

      if (existing.exists) {
        oldData =
            existing.data() ?? {};
      }

      /// =====================================================
      /// ROLES
      /// =====================================================

      List roles = List.from(
        oldData["roles"] ?? [
          "user",
        ],
      );

      if (!roles.contains(
        "user",
      )) {
        roles.add("user");
      }

      /// =====================================================
      /// SAVE
      /// =====================================================

      await firestore
          .collection("users")
          .doc(docId)
          .set(
        {
          /// IDS

          "docId": docId,

          "phone": docId,

          "firebaseUid":
              user.uid,

          /// USER INFO

          "name":
              oldData["name"] ??
                  user.displayName ??
                  "",

          "email":
              oldData["email"] ??
                  user.email ??
                  "",

          "photo":
              oldData["photo"] ??
                  user.photoURL ??
                  "",

          /// ROLES

          "roles": roles,

          "providerApproved":
              oldData[
                      "providerApproved"] ??
                  false,

          /// STATUS

          "status":
              oldData["status"] ??
                  "active",

          /// TIMESTAMP

          "updatedAt":
              FieldValue
                  .serverTimestamp(),

          "lastLogin":
              FieldValue
                  .serverTimestamp(),

          "createdAt":
              oldData[
                      "createdAt"] ??
                  FieldValue
                      .serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// =========================================================
  /// SAVE ADMIN
  /// =========================================================

  Future<void> saveAdmin(
    User user,
  ) async {
    try {
      final docId =
          getAdminDocId(user);

      final existing =
          await firestore
              .collection(
                "admins",
              )
              .doc(docId)
              .get();

      Map<String, dynamic>
          oldData = {};

      if (existing.exists) {
        oldData =
            existing.data() ?? {};
      }

      await firestore
          .collection("admins")
          .doc(docId)
          .set(
        {
          /// IDS

          "docId": docId,

          "email": docId,

          "firebaseUid":
              user.uid,

          /// INFO

          "name":
              oldData["name"] ??
                  user.displayName ??
                  "",

          "photo":
              oldData["photo"] ??
                  user.photoURL ??
                  "",

          /// ROLE

          "role": "admin",

          "status":
              oldData["status"] ??
                  "active",

          /// TIME

          "updatedAt":
              FieldValue
                  .serverTimestamp(),

          "lastLogin":
              FieldValue
                  .serverTimestamp(),

          "createdAt":
              oldData[
                      "createdAt"] ??
                  FieldValue
                      .serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// =========================================================
  /// CHECK PROVIDER
  /// =========================================================

  Future<bool> isProvider(
    String phone,
  ) async {
    try {
      final doc =
          await firestore
              .collection(
                "users",
              )
              .doc(phone)
              .get();

      if (!doc.exists) {
        return false;
      }

      final data =
          doc.data() ?? {};

      List roles = List.from(
        data["roles"] ?? [],
      );

      return roles.contains(
        "provider",
      );
    } catch (e) {
      return false;
    }
  }

  /// =========================================================
  /// BECOME PROVIDER
  /// =========================================================

  Future<void> becomeProvider(
    String phone,
  ) async {
    try {
      final docRef =
          firestore
              .collection(
                "users",
              )
              .doc(phone);

      final doc =
          await docRef.get();

      if (!doc.exists) {
        throw Exception(
          "User not found",
        );
      }

      final data =
          doc.data() ?? {};

      List roles = List.from(
        data["roles"] ?? [],
      );

      if (!roles.contains(
        "provider",
      )) {
        roles.add(
          "provider",
        );
      }

      await docRef.update(
        {
          "roles": roles,
          "updatedAt":
              FieldValue
                  .serverTimestamp(),
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// =========================================================
  /// ADMIN EMAIL LOGIN
  /// =========================================================

  Future<User?> adminLogin(
    String email,
    String password,
  ) async {
    try {
      final result = await auth
          .signInWithEmailAndPassword(
        email:
            email.trim(),
        password:
            password.trim(),
      );

      final user =
          result.user;

      if (user != null) {
        await saveAdmin(
          user,
        );
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// =========================================================
  /// ADMIN GOOGLE LOGIN
  /// =========================================================

  Future<User?> adminGoogleLogin() async {
    try {
      final GoogleSignIn
          googleSignIn =
          GoogleSignIn();

      final GoogleSignInAccount?
          googleUser =
          await googleSignIn
              .signIn();

      if (googleUser == null) {
        return null;
      }

      final googleAuth =
          await googleUser
              .authentication;

      final credential =
          GoogleAuthProvider
              .credential(
        accessToken:
            googleAuth
                .accessToken,
        idToken:
            googleAuth.idToken,
      );

      final result =
          await auth
              .signInWithCredential(
        credential,
      );

      final user =
          result.user;

      if (user != null) {
        await saveAdmin(
          user,
        );
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// =========================================================
  /// AUTO LOGIN
  /// =========================================================

  bool isLoggedIn() {
    return auth.currentUser !=
        null;
  }

  /// =========================================================
  /// LOGOUT
  /// =========================================================

  Future<void> logout() async {
    try {
      try {
        await GoogleSignIn()
            .signOut();
      } catch (_) {}

      await auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}