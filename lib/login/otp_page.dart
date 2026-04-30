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
  int timer = 30;
  Timer? t;

  @override
  void initState() {
    super.initState();
    sendOtp();
    startTimer();
  }

  void startTimer() {
    timer = 30;
    t?.cancel();

    t = Timer.periodic(const Duration(seconds: 1), (x) {
      if (timer == 0) {
        x.cancel();
      } else {
        setState(() => timer--);
      }
    });
  }

  Future<void> sendOtp() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phone,

      verificationCompleted: (cred) async {
        final userCred = await _auth.signInWithCredential(cred);
        await saveUser(userCred.user!);
        goHome();
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

  Future<void> verifyOtp() async {
    try {
      setState(() => loading = true);

      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      final userCred = await _auth.signInWithCredential(cred);

      await saveUser(userCred.user!);

      goHome();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }

    setState(() => loading = false);
  }

  Future<void> saveUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'phone': user.phoneNumber ?? widget.phone,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => BottomNavPage(
          userPhone: widget.phone,
          userEmail: "",
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

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
              onPressed: timer == 0 ? sendOtp : null,
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