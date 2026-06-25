import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  User? get currentUser => auth.currentUser;

  bool isLoggedIn() => auth.currentUser != null;

  // Doc ID = user email (readable format: john@gmail.com)
  String _docId(User user) => user.email!.toLowerCase().trim();

  String get _currentDocId => currentUser!.email!.toLowerCase().trim();

  DocumentReference get _currentUserDoc =>
      firestore.collection('users').doc(_currentDocId);

  // =====================================================
  // GOOGLE LOGIN
  // =====================================================

  Future<User?> googleLogin() async {
    try {
      await googleSignIn.signOut(); // Force account picker every time

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
        await user.getIdToken(true);
        await saveUser(user);
      }

      return user;
    } catch (e) {
      print("GOOGLE LOGIN ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // SAVE USER
  // Doc ID = email (e.g. john@gmail.com)
  // =====================================================

  Future<void> saveUser(User user) async {
    try {
      // Readable doc ID = email
      final docRef = firestore.collection('users').doc(_docId(user));

      final existingSnap = await docRef.get();
      final old = existingSnap.exists
          ? (existingSnap.data() ?? {})
          : <String, dynamic>{};

      final nameParts = (user.displayName ?? '').trim().split(' ');
      final defaultFirst = nameParts.isNotEmpty ? nameParts.first : '';
      final defaultLast =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await docRef.set({
        // Identity
        'uid': user.uid,
        'email': user.email ?? '',
        'googleName': user.displayName ?? '',
        'googlePhoto': user.photoURL ?? '',

        // Editable profile (preserved if already set)
        'firstName': (old['firstName'] ?? '').toString().isNotEmpty
            ? old['firstName']
            : defaultFirst,
        'lastName': (old['lastName'] ?? '').toString().isNotEmpty
            ? old['lastName']
            : defaultLast,
        'phone': old['phone'] ?? '',
        'address': old['address'] ?? '',

        // Photo: user override or Google fallback
        'photo': (old['photo'] ?? '').toString().isNotEmpty
            ? old['photo']
            : (user.photoURL ?? ''),

        // Timestamps
        'createdAt': old['createdAt'] ?? FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('USER SAVED: docId=${_docId(user)}  uid=${user.uid}');
    } catch (e) {
      print("SAVE USER ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // FETCH CURRENT USER DATA
  // =====================================================

  Future<Object?> fetchCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _currentUserDoc.get();
      return doc.data();
    } catch (e) {
      print("FETCH USER ERROR: $e");
      return null;
    }
  }

  // =====================================================
  // UPDATE PROFILE
  // =====================================================

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    String photo = '',
  }) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final fullName = '$firstName $lastName'.trim();
      await user.updateDisplayName(fullName);

      String resolvedPhoto = photo.trim();
      if (resolvedPhoto.isEmpty) {
        final snap = await _currentUserDoc.get();
        final stored = snap.exists
            ? (snap.data() as Map<String, dynamic>)['photo'] ?? ''
            : '';
        resolvedPhoto =
            stored.toString().isNotEmpty ? stored : (user.photoURL ?? '');
      }

      await _currentUserDoc.set({
        'firstName': firstName,
        'lastName': lastName,
        'name': fullName,
        'phone': phone,
        'address': address,
        'photo': resolvedPhoto,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('PROFILE UPDATED: docId=$_currentDocId');
    } catch (e) {
      print("UPDATE PROFILE ERROR: $e");
      rethrow;
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    try {
      await googleSignIn.signOut();
    } catch (_) {}

    await auth.signOut();
    print('USER LOGGED OUT');
  }
}