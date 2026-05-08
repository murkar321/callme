import 'dart:async';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpPage extends StatefulWidget {
  final String phone;

  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String verificationId = "";
  final otpController = TextEditingController();

  bool loading = false;
  int timer = 120;
  Timer? t;

  @override
  void initState() {
    super.initState();
    sendOtp();
    startTimer();
  }

  void startTimer() {
    timer = 120;
    t?.cancel();

    t = Timer.periodic(const Duration(seconds: 1), (x) {
      if (timer == 0) {
        x.cancel();
      } else {
        setState(() => timer--);
      }
    });
  }

  /// ================= LINK OR SIGNIN =================
  Future<User> linkOrSignIn(PhoneAuthCredential credential) async {
    try {
      if (_auth.currentUser != null) {
        return (await _auth.currentUser!
                .linkWithCredential(credential))
            .user!;
      }
      return (await _auth.signInWithCredential(credential)).user!;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return (await _auth.signInWithCredential(credential)).user!;
      } else {
        rethrow;
      }
    }
  }

  /// ================= 🔥 SAFE MERGE =================
  Future<void> mergeOldUserIfExists(User user) async {
    final usersRef = _firestore.collection('users');

    Map<String, dynamic> mergedData = {};

    /// ---------- PHONE MATCH ----------
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      final phoneMatch = await usersRef
          .where('phone', isEqualTo: user.phoneNumber)
          .get();

      for (var doc in phoneMatch.docs) {
        if (doc.id != user.uid) {
          final data = Map<String, dynamic>.from(doc.data());

          /// 🔥 FIX UNMODIFIABLE LISTS
          if (data['providers'] != null) {
            data['providers'] = List.from(data['providers']);
          }

          mergedData.addAll(data);
          await usersRef.doc(doc.id).delete();
        }
      }
    }

    /// ---------- EMAIL MATCH ----------
    if (user.email != null && user.email!.isNotEmpty) {
      final emailMatch = await usersRef
          .where('email', isEqualTo: user.email)
          .get();

      for (var doc in emailMatch.docs) {
        if (doc.id != user.uid) {
          final data = Map<String, dynamic>.from(doc.data());

          /// 🔥 FIX AGAIN
          if (data['providers'] != null) {
            data['providers'] = List.from(data['providers']);
          }

          mergedData.addAll(data);
          await usersRef.doc(doc.id).delete();
        }
      }
    }

    /// ---------- APPLY MERGE ----------
    if (mergedData.isNotEmpty) {
      await usersRef.doc(user.uid).set(
        mergedData,
        SetOptions(merge: true),
      );
    }
  }

  /// ================= SAVE USER =================
  Future<void> saveUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'phone': user.phoneNumber ?? widget.phone,
      'email': user.email ?? "",
      'providers': user.providerData.map((e) => e.providerId).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ================= SEND OTP =================
  Future<void> sendOtp() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phone,

      verificationCompleted: (cred) async {
        final user = await linkOrSignIn(cred);

        await mergeOldUserIfExists(user);
        await saveUser(user);

        goHome(user);
      },

      verificationFailed: (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message ?? "")));
      },

      codeSent: (vid, _) {
        setState(() => verificationId = vid);
      },

      codeAutoRetrievalTimeout: (vid) {
        verificationId = vid;
      },
    );
  }

  /// ================= VERIFY OTP =================
  Future<void> verifyOtp() async {
    try {
      setState(() => loading = true);

      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      final user = await linkOrSignIn(cred);

      await mergeOldUserIfExists(user);
      await saveUser(user);

      goHome(user);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }

    setState(() => loading = false);
  }

  /// ================= NAVIGATION =================
  void goHome(User user) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BottomNavPage(
          userPhone: user.phoneNumber ?? widget.phone,
          userEmail: user.email ?? "",
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    t?.cancel();
    otpController.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text("OTP sent to ${widget.phone}"),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : verifyOtp,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Verify OTP"),
            ),
            TextButton(
              onPressed: timer == 0
                  ? () {
                      sendOtp();
                      startTimer();
                    }
                  : null,
              child: Text(timer == 0
                  ? "Resend OTP"
                  : "Resend in $timer sec"),
            ),
          ],
        ),
      ),
    );
  }
}