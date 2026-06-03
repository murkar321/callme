import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthSession {
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    // Check USERS
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists) {
      return {
        "id": userDoc.id,
        "role": "user",
        "customId": userDoc['userId'] ?? uid,
      };
    }

    // Check PROVIDERS
    final providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .get();

    if (providerDoc.exists) {
      return {
        "id": providerDoc.id,
        "role": "provider",
        "customId": providerDoc['providerId'] ?? uid,
      };
    }

    // Check ADMIN
    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(uid)
        .get();

    if (adminDoc.exists) {
      return {
        "id": adminDoc.id,
        "role": "admin",
        "customId": adminDoc['adminId'] ?? uid,
      };
    }

    return null;
  }
}