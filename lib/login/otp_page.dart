import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_selection_page.dart';

class OtpPage extends StatefulWidget {
  final String phone; // +91XXXXXXXXXX
  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String verificationId = "";
  bool isLoading = false;

  int resendTimer = 30;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    sendOtp();
    startTimer();
  }

  /// 🔥 COMMON FUNCTION (Same as Signup Page)
  Future<void> handleUserAfterLogin(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    final doc = await userRef.get();

    bool isProvider = false;
    bool isAdmin = false;

    if (!doc.exists) {
      /// ✅ NEW USER
      await userRef.set({
        'uid': user.uid,
        'phone': widget.phone,
        'isProvider': false,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      /// ✅ EXISTING USER
      final data = doc.data()!;
      isProvider = data['isProvider'] ?? false;
      isAdmin = data['isAdmin'] ?? false;
    }

    if (!mounted) return;

    /// 🚀 GO TO ROLE SELECTION
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RoleSelectionPage(
          isProvider: isProvider,
          isAdmin: isAdmin,
        ),
      ),
    );
  }

  /// 🔹 SEND OTP
  Future<void> sendOtp() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: widget.phone,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCredential =
            await _auth.signInWithCredential(credential);

        final user = userCredential.user;
        if (user != null) {
          await handleUserAfterLogin(user); // ✅ FIXED
        }
      },

      verificationFailed: (FirebaseAuthException e) {
        showMessage(e.message ?? "OTP verification failed");
      },

      codeSent: (String vid, int? resendToken) {
        setState(() => verificationId = vid);
      },

      codeAutoRetrievalTimeout: (String vid) {
        verificationId = vid;
      },
    );
  }

  /// 🔹 VERIFY OTP
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      showMessage("Enter valid 6-digit OTP");
      return;
    }

    try {
      setState(() => isLoading = true);

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        await handleUserAfterLogin(user); // ✅ FIXED
      }

    } catch (e) {
      showMessage("Invalid OTP");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 TIMER
  void startTimer() {
    resendTimer = 30;
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendTimer == 0) {
        t.cancel();
      } else {
        setState(() => resendTimer--);
      }
    });
  }

  /// 🔹 SNACKBAR
  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    otpController.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Verify Phone",
                style:
                    TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                "OTP sent to ${widget.phone}",
                style:
                    const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              /// OTP INPUT
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Enter 6-digit OTP",
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          "Verify & Continue",
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              /// RESEND OTP
              Center(
                child: TextButton(
                  onPressed: resendTimer == 0
                      ? () {
                          sendOtp();
                          startTimer();
                        }
                      : null,
                  child: Text(
                    resendTimer == 0
                        ? "Resend OTP"
                        : "Resend OTP in $resendTimer sec",
                    style:
                        const TextStyle(color: Colors.indigo),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}