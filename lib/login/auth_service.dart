import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  User? get currentUser => auth.currentUser;

  bool isLoggedIn() => auth.currentUser != null;

  // =====================================================
  // DOCUMENT ID = email (lowercase)
  // e.g.  john@gmail.com
  // =====================================================

  String getUserDocId(User user) =>
      (user.email ?? user.uid).toLowerCase().trim();

  String get _currentDocId => getUserDocId(currentUser!);

  DocumentReference get _currentUserDoc =>
      firestore.collection('users').doc(_currentDocId);

  // =====================================================
  // GOOGLE LOGIN
  // =====================================================

  Future<User?> googleLogin() async {
    try {
      // Force account picker every time
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        await saveUser(user);
        listenForTokenRefresh();
      }

      return user;
    } catch (e) {
      print("GOOGLE LOGIN ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // SAVE USER ON FIRST LOGIN / LOGIN
  // Preserves existing editable fields (phone, address,
  // firstName, lastName, photo override) if already set.
  // =====================================================

  Future<void> saveUser(User user) async {
    try {
      String token = '';
      try {
        token = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (_) {}

      final docRef =
          firestore.collection('users').doc(getUserDocId(user));

      final existingSnap = await docRef.get();
      final old =
          existingSnap.exists ? (existingSnap.data() ?? {}) : <String, dynamic>{};

      // Split displayName into first / last if not already stored
      final nameParts = (user.displayName ?? '').trim().split(' ');
      final defaultFirst = nameParts.isNotEmpty ? nameParts.first : '';
      final defaultLast =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await docRef.set({
        // ── Identity (from Google, always refreshed) ──────────────
        'uid': user.uid,
        'email': user.email ?? '',
        'googleName': user.displayName ?? '',
        'googlePhoto': user.photoURL ?? '',

        // ── Editable profile (preserved if already set) ───────────
        'firstName': (old['firstName'] ?? '').toString().isNotEmpty
            ? old['firstName']
            : defaultFirst,
        'lastName': (old['lastName'] ?? '').toString().isNotEmpty
            ? old['lastName']
            : defaultLast,
        'phone': old['phone'] ?? '',
        'address': old['address'] ?? '',

        // photo: user can override; fall back to Google photo
        'photo': (old['photo'] ?? '').toString().isNotEmpty
            ? old['photo']
            : (user.photoURL ?? ''),

        // ── FCM ───────────────────────────────────────────────────
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),

        // ── Timestamps ────────────────────────────────────────────
        'createdAt':
            old['createdAt'] ?? FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('USER SAVED: ${getUserDocId(user)}');
      print('FCM TOKEN: $token');
    } catch (e) {
      print("SAVE USER ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // UPDATE FCM TOKEN  (smart diff — only writes if changed)
  // =====================================================

  Future<void> updateFcmToken() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final docSnap = await _currentUserDoc.get();
      final storedToken =
          docSnap.exists ? (docSnap.data() as Map)['fcmToken'] ?? '' : '';

      if (token == storedToken) {
        print('FCM TOKEN UNCHANGED — skipping write');
        return;
      }

      await _currentUserDoc.set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('FCM TOKEN UPDATED');
    } catch (e) {
      print("TOKEN UPDATE ERROR: $e");
    }
  }

  // =====================================================
  // TOKEN REFRESH LISTENER
  // =====================================================

  void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        final user = currentUser;
        if (user == null) return;

        await firestore
            .collection('users')
            .doc(getUserDocId(user))
            .set({
          'fcmToken': newToken,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print("TOKEN REFRESHED");
      } catch (e) {
        print("TOKEN REFRESH ERROR: $e");
      }
    });
  }

  // =====================================================
  // FETCH CURRENT USER DATA
  // =====================================================

  Future<Map<String, dynamic>?> fetchCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await firestore
          .collection('users')
          .doc(getUserDocId(user))
          .get();

      return doc.data();
    } catch (e) {
      print("FETCH USER ERROR: $e");
      return null;
    }
  }

  // =====================================================
  // UPDATE PROFILE
  // Stores editable fields; photo can be custom URL or
  // kept as Google photo if empty string is passed.
  // =====================================================

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    String photo = '', // pass '' to keep existing / Google photo
  }) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final fullName = '$firstName $lastName'.trim();

      // Update Firebase Auth display name
      await user.updateDisplayName(fullName);

      // Decide which photo to persist
      String resolvedPhoto = photo.trim();
      if (resolvedPhoto.isEmpty) {
        // keep whatever is already stored (or Google photo as fallback)
        final snap = await _currentUserDoc.get();
        final stored = snap.exists
            ? (snap.data() as Map<String, dynamic>)['photo'] ?? ''
            : '';
        resolvedPhoto =
            stored.toString().isNotEmpty ? stored : (user.photoURL ?? '');
      }

      await firestore
          .collection('users')
          .doc(getUserDocId(user))
          .set({
        'firstName': firstName,
        'lastName': lastName,
        'name': fullName,
        'phone': phone,
        'address': address,
        'photo': resolvedPhoto,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('PROFILE UPDATED: ${getUserDocId(user)}');
    } catch (e) {
      print("UPDATE PROFILE ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // LOGOUT  — clears FCM token first, then signs out
  // =====================================================

  Future<void> logout() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Clear the FCM token so this device stops receiving pushes
        await firestore
            .collection('users')
            .doc(getUserDocId(user))
            .set({
          'fcmToken': '',
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM TOKEN CLEARED ON LOGOUT');
      }
    } catch (e) {
      print("LOGOUT TOKEN CLEAR ERROR: $e");
    }

    try {
      await googleSignIn.signOut();
    } catch (_) {}

    await auth.signOut();
    print('USER LOGGED OUT');
  }
}