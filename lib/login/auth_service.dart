import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  /// =========================================================
  /// GENERATE READABLE USER ID
  /// =========================================================

  String generateUserId(String value) {
    final clean = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

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

    /// AUTH UID
    if (authUid != null &&
        authUid.isNotEmpty) {

      final result = await firestore
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

      final result = await firestore
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

      final result = await firestore
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
  }

  /// =========================================================
  /// SAVE USER
  /// =========================================================

  Future<void> saveUser(
    User user,
    String provider,
  ) async {

    /// FIND EXISTING USER
    final existing =
        await findExistingUser(
      authUid: user.uid,
      email: user.email,
      phone: user.phoneNumber,
    );

    String userDocId;

    /// EXISTING USER
    if (existing != null) {

      userDocId = existing.id;

    } else {

      /// NEW USER
      userDocId = generateUserId(
        user.displayName ??
            user.email ??
            user.phoneNumber ??
            "user",
      );
    }

    /// GET EXISTING PROVIDERS
    List providers = [];

    if (existing != null) {
      final data =
          existing.data()
              as Map<String, dynamic>;

      providers =
          List.from(
            data['providers'] ?? [],
          );
    }

    /// ADD CURRENT PROVIDER
    if (!providers.contains(provider)) {
      providers.add(provider);
    }

    await firestore
        .collection('users')
        .doc(userDocId)
        .set({

      /// IDS
      'userId': userDocId,
      'authUid': user.uid,
      'uid': user.uid,

      /// USER DATA
      'email': user.email ?? "",
      'phone': user.phoneNumber ?? "",
      'name': user.displayName ?? "",
      'photo': user.photoURL ?? "",

      /// LOGIN PROVIDERS
      'provider': provider,
      'providers': providers,

      /// STATUS
      'role': 'user',
      'status': 'active',

      /// TIMESTAMPS
      'updatedAt':
          FieldValue.serverTimestamp(),

      'lastLogin':
          FieldValue.serverTimestamp(),

      'createdAt':
          existing == null
              ? FieldValue.serverTimestamp()
              : existing['createdAt'],
    }, SetOptions(merge: true));
  }

  /// =========================================================
  /// GOOGLE SIGN IN
  /// =========================================================

  Future<User?> signInWithGoogle() async {

    try {

      final googleSignIn =
          GoogleSignIn();

      await googleSignIn.signOut();

      final googleUser =
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

      await saveUser(
        result.user!,
        "google",
      );

      return result.user;

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

        email: email.trim(),
        password: password.trim(),
      );

      await result.user!
          .updateDisplayName(name);

      await result.user!.reload();

      final updatedUser =
          auth.currentUser!;

      await saveUser(
        updatedUser,
        "email",
      );

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

        email: email.trim(),
        password: password.trim(),
      );

      await saveUser(
        result.user!,
        "email",
      );

      return result.user;

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

    await saveUser(
      user,
      "phone",
    );
  }

  /// =========================================================
  /// CURRENT USER
  /// =========================================================

  User? get currentUser =>
      auth.currentUser;

  /// =========================================================
  /// LOGOUT
  /// =========================================================

  Future<void> logout() async {

    try {

      await GoogleSignIn().signOut();

    } catch (_) {}

    await auth.signOut();
  }
}