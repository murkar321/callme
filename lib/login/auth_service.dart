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
  /// GENERATE USER ID
  /// =========================================================

  String generateUserId(String value) {

    final clean = value

        .trim()

        .toLowerCase()

        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );

    final unique =
        DateTime.now()
            .millisecondsSinceEpoch
            .toString()
            .substring(7);

    return "${clean}_$unique";
  }

  /// =========================================================
  /// FIND EXISTING USER
  /// =========================================================

  Future<DocumentSnapshot?> findExistingUser({

    String? authUid,

    String? email,

    String? phone,
  }) async {

    try {

      /// AUTH UID

      if (authUid != null &&
          authUid.isNotEmpty) {

        final result =
            await firestore

                .collection("users")

                .where(
                  "authUid",
                  isEqualTo: authUid,
                )

                .limit(1)

                .get();

        if (result.docs.isNotEmpty) {

          return result.docs.first;
        }
      }

      /// EMAIL

      if (email != null &&
          email.isNotEmpty) {

        final result =
            await firestore

                .collection("users")

                .where(
                  "email",
                  isEqualTo: email,
                )

                .limit(1)

                .get();

        if (result.docs.isNotEmpty) {

          return result.docs.first;
        }
      }

      /// PHONE

      if (phone != null &&
          phone.isNotEmpty) {

        final result =
            await firestore

                .collection("users")

                .where(
                  "phone",
                  isEqualTo: phone,
                )

                .limit(1)

                .get();

        if (result.docs.isNotEmpty) {

          return result.docs.first;
        }
      }

      return null;

    } catch (e) {

      rethrow;
    }
  }

  /// =========================================================
  /// SAVE USER
  /// =========================================================

  Future<void> saveUser(

      User user,

      String provider,
      ) async {

    try {

      /// FIND EXISTING USER

      final existing =
          await findExistingUser(

        authUid: user.uid,

        email: user.email,

        phone: user.phoneNumber,
      );

      String userDocId;

      Map<String, dynamic> oldData = {};

      /// EXISTING USER

      if (existing != null) {

        userDocId =
            existing.id;

        oldData =
            existing.data()
            as Map<String, dynamic>;

      } else {

        /// NEW USER

        userDocId =
            generateUserId(

              user.displayName ??

                  user.email ??

                  user.phoneNumber ??

                  "user",
            );
      }

      /// =====================================================
      /// PROVIDERS
      /// =====================================================

      List providers =
      List.from(
        oldData['providers'] ?? [],
      );

      if (!providers.contains(provider)) {

        providers.add(provider);
      }

      /// =====================================================
      /// SAFE DATA
      /// PREVENTS PROFILE RESET
      /// =====================================================

      final data = {

        /// IDS

        'userId':
        userDocId,

        'authUid':
        user.uid,

        'uid':
        user.uid,

        /// PROFILE DATA

        'email':

        user.email != null &&
            user.email!.trim().isNotEmpty

            ? user.email

            : oldData['email'] ?? "",

        'phone':

        user.phoneNumber != null &&
            user.phoneNumber!
                .trim()
                .isNotEmpty

            ? user.phoneNumber

            : oldData['phone'] ?? "",

        'name':

        user.displayName != null &&
            user.displayName!
                .trim()
                .isNotEmpty

            ? user.displayName

            : oldData['name'] ?? "",

        'photo':

        user.photoURL != null &&
            user.photoURL!
                .trim()
                .isNotEmpty

            ? user.photoURL

            : oldData['photo'] ?? "",

        /// IMPORTANT
        /// PRESERVE CUSTOM PROFILE DATA

        'firstName':
        oldData['firstName'] ?? "",

        'lastName':
        oldData['lastName'] ?? "",

        'address':
        oldData['address'] ?? "",

        /// LOGIN PROVIDERS

        'provider':
        provider,

        'providers':
        providers,

        /// STATUS

        'role':
        oldData['role'] ?? "user",

        'status':
        oldData['status'] ?? "active",

        /// TIMESTAMPS

        'updatedAt':
        FieldValue.serverTimestamp(),

        'lastLogin':
        FieldValue.serverTimestamp(),

        'createdAt':

        oldData['createdAt'] ??

            FieldValue.serverTimestamp(),
      };

      /// =====================================================
      /// SAVE
      /// =====================================================

      await firestore

          .collection("users")

          .doc(userDocId)

          .set(

        data,

        SetOptions(
          merge: true,
        ),
      );

    } catch (e) {

      rethrow;
    }
  }

  /// =========================================================
  /// GOOGLE LOGIN
  /// =========================================================

  Future<User?> signInWithGoogle() async {

    try {

      final GoogleSignIn googleSignIn =
      GoogleSignIn();

      /// FORCE ACCOUNT PICKER

      await googleSignIn.signOut();

      final GoogleSignInAccount?
      googleUser =

      await googleSignIn.signIn();

      if (googleUser == null) {

        return null;
      }

      final googleAuth =
      await googleUser.authentication;

      final credential =
      GoogleAuthProvider.credential(

        accessToken:
        googleAuth.accessToken,

        idToken:
        googleAuth.idToken,
      );

      final result =
      await auth.signInWithCredential(
        credential,
      );

      /// REFRESH USER

      await result.user?.reload();

      final updatedUser =
          auth.currentUser;

      if (updatedUser != null) {

        await saveUser(
          updatedUser,
          "google",
        );
      }

      return updatedUser;

    } catch (e) {

      rethrow;
    }
  }

  /// =========================================================
  /// EMAIL SIGNUP
  /// =========================================================

  Future<User?> signUpEmail(

      String email,

      String password,

      String name,
      ) async {

    try {

      final result =

      await auth

          .createUserWithEmailAndPassword(

        email:
        email.trim(),

        password:
        password.trim(),
      );

      /// UPDATE NAME

      await result.user
          ?.updateDisplayName(
        name.trim(),
      );

      /// REFRESH USER

      await result.user?.reload();

      final updatedUser =
          auth.currentUser;

      if (updatedUser != null) {

        await saveUser(
          updatedUser,
          "email",
        );
      }

      return updatedUser;

    } catch (e) {

      rethrow;
    }
  }

  /// =========================================================
  /// EMAIL LOGIN
  /// =========================================================

  Future<User?> loginEmail(

      String email,

      String password,
      ) async {

    try {

      final result =

      await auth

          .signInWithEmailAndPassword(

        email:
        email.trim(),

        password:
        password.trim(),
      );

      /// REFRESH USER

      await result.user?.reload();

      final updatedUser =
          auth.currentUser;

      if (updatedUser != null) {

        await saveUser(
          updatedUser,
          "email",
        );
      }

      return updatedUser;

    } catch (e) {

      rethrow;
    }
  }

  /// =========================================================
  /// PHONE LOGIN
  /// =========================================================

  Future<void> savePhoneUser(
      User user,
      ) async {

    try {

      await user.reload();

      final updatedUser =
          auth.currentUser;

      if (updatedUser != null) {

        await saveUser(
          updatedUser,
          "phone",
        );
      }

    } catch (e) {

      rethrow;
    }
  }

  /// =========================================================
  /// LOGOUT
  /// =========================================================

  Future<void> logout() async {

    try {

      /// GOOGLE

      try {

        await GoogleSignIn()
            .signOut();

      } catch (_) {}

      /// FIREBASE AUTH

      await auth.signOut();

    } catch (e) {

      rethrow;
    }
  }
}