import 'dart:async';

import 'package:callme/screens/bottom_nav_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OtpPage extends StatefulWidget {
  final String phone;

  const OtpPage({
    super.key,
    required this.phone, required bool isLogin,
  });

  @override
  State<OtpPage> createState() =>
      _OtpPageState();
}

class _OtpPageState
    extends State<OtpPage> {
  /// =====================================================
  /// FIREBASE
  /// =====================================================

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  /// =====================================================
  /// CONTROLLERS
  /// =====================================================

  final TextEditingController
      otpController =
      TextEditingController();

  /// =====================================================
  /// VARIABLES
  /// =====================================================

  String verificationId = "";

  bool loading = false;

  bool otpSent = false;

  int resendSeconds = 30;

  Timer? timer;

  int? resendToken;

  /// =====================================================
  /// INIT
  /// =====================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      sendOtp();
    });
  }

  /// =====================================================
  /// TIMER
  /// =====================================================

  void startTimer() {
    resendSeconds = 30;

    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (resendSeconds <= 0) {
          timer.cancel();
        } else {
          if (mounted) {
            setState(() {
              resendSeconds--;
            });
          }
        }
      },
    );
  }

  /// =====================================================
  /// SAVE USER
  /// =====================================================

  Future<void> saveUser(
    User user,
  ) async {
    try {
      final String docId =
          widget.phone;

      final userRef = firestore
          .collection("users")
          .doc(docId);

      final userDoc =
          await userRef.get();

      if (userDoc.exists) {
        await userRef.update({
          "firebaseUid": user.uid,
          "phone":
              user.phoneNumber ??
                  widget.phone,
          "lastLogin":
              FieldValue.serverTimestamp(),
          "updatedAt":
              FieldValue.serverTimestamp(),
        });

        return;
      }

      await userRef.set({
        "firebaseUid": user.uid,
        "phone":
            user.phoneNumber ??
                widget.phone,
        "email":
            user.email ?? "",
        "name":
            user.displayName ?? "",
        "photo":
            user.photoURL ?? "",
        "role": "user",
        "status": "active",
        "createdAt":
            FieldValue.serverTimestamp(),
        "updatedAt":
            FieldValue.serverTimestamp(),
        "lastLogin":
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint(
        "SAVE USER ERROR: $e",
      );
    }
  }

  /// =====================================================
  /// SEND OTP
  /// =====================================================

  Future<void> sendOtp() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      await auth.verifyPhoneNumber(
        phoneNumber: widget.phone,

        timeout:
            const Duration(seconds: 60),

        forceResendingToken:
            resendToken,

        /// =================================================
        /// AUTO VERIFY
        /// =================================================

        verificationCompleted:
            (
              PhoneAuthCredential
                  credential,
            ) async {
          try {
            final userCredential =
                await auth
                    .signInWithCredential(
              credential,
            );

            final user =
                userCredential.user;

            if (user != null) {
              await saveUser(user);

              showMessage(
                "Phone verified successfully",
              );

              goHome(user);
            }
          } catch (e) {
            debugPrint(
              "AUTO VERIFY ERROR: $e",
            );
          }
        },

        /// =================================================
        /// VERIFICATION FAILED
        /// =================================================

        verificationFailed:
            (
              FirebaseAuthException e,
            ) {
          if (mounted) {
            setState(() {
              loading = false;
            });
          }

          String error =
              e.message ??
                  "Verification failed";

          if (e.code ==
              'too-many-requests') {
            error =
                "Too many attempts. Try again later.";
          }

          showMessage(
            error,
            isError: true,
          );
        },

        /// =================================================
        /// CODE SENT
        /// =================================================

        codeSent: (
          String id,
          int? token,
        ) {
          verificationId = id;

          resendToken = token;

          otpSent = true;

          startTimer();

          if (mounted) {
            setState(() {
              loading = false;
            });
          }

          showMessage(
            "OTP sent successfully",
          );
        },

        /// =================================================
        /// TIMEOUT
        /// =================================================

        codeAutoRetrievalTimeout:
            (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }

      showMessage(
        "Failed to send OTP",
        isError: true,
      );
    }
  }

  /// =====================================================
  /// VERIFY OTP
  /// =====================================================

  Future<void> verifyOtp() async {
    final otp =
        otpController.text.trim();

    if (otp.length != 6) {
      showMessage(
        "Enter valid 6 digit OTP",
        isError: true,
      );
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential =
          await auth
              .signInWithCredential(
        credential,
      );

      final user =
          userCredential.user;

      if (user == null) {
        throw Exception(
          "User not found",
        );
      }

      await saveUser(user);

      showMessage(
        "Login successful",
      );

      goHome(user);
    } on FirebaseAuthException catch (e) {
      showMessage(
        e.message ?? "Invalid OTP",
        isError: true,
      );
    } catch (e) {
      showMessage(
        "OTP verification failed",
        isError: true,
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  /// =====================================================
  /// MESSAGE
  /// =====================================================

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            isError
                ? Colors.red.shade400
                : Colors.green.shade600,
      ),
    );
  }

  /// =====================================================
  /// GO HOME
  /// =====================================================

  void goHome(User user) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BottomNavPage(
          userPhone:
              user.phoneNumber ??
                  widget.phone,
          userEmail:
              user.email ?? "",
        ),
      ),
      (route) => false,
    );
  }

  /// =====================================================
  /// DISPOSE
  /// =====================================================

  @override
  void dispose() {
    timer?.cancel();

    otpController.dispose();

    super.dispose();
  }

  /// =====================================================
  /// UI
  /// =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const SizedBox(
                height: 10,
              ),

              /// BACK BUTTON

              InkWell(
                onTap: () {
                  Navigator.pop(
                    context,
                  );
                },

                borderRadius:
                    BorderRadius.circular(
                  16,
                ),

                child: Container(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(
                          0.03,
                        ),
                        blurRadius: 10,
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons
                        .arrow_back_ios_new_rounded,
                  ),
                ),
              ),

              const SizedBox(
                height: 50,
              ),

              /// TITLE

              const Text(
                "Verify OTP",

                style: TextStyle(
                  fontSize: 34,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF111827),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                "Enter the 6 digit code sent to your mobile number.",

                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              /// PHONE BOX

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.03,
                      ),
                      blurRadius: 16,
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.all(
                        10,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEEF2FF,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),

                      child: const Icon(
                        Icons.phone,
                        color:
                            Color(
                          0xFF4F46E5,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Text(
                        widget.phone,

                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 45,
              ),

              /// OTP FIELD

              Container(
                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    28,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.04,
                      ),
                      blurRadius: 20,
                    ),
                  ],
                ),

                child: TextField(
                  controller:
                      otpController,

                  keyboardType:
                      TextInputType.number,

                  maxLength: 6,

                  autofocus: true,

                  textAlign:
                      TextAlign.center,

                  style:
                      const TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 12,
                  ),

                  decoration:
                      const InputDecoration(
                    border:
                        InputBorder.none,

                    counterText: "",

                    hintText: "••••••",

                    contentPadding:
                        EdgeInsets.symmetric(
                      vertical: 26,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              /// VERIFY BUTTON

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(
                  onPressed:
                      loading
                          ? null
                          : verifyOtp,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF4F46E5,
                    ),

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  child:
                      loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors
                                        .white,
                                strokeWidth:
                                    2.5,
                              ),
                            )
                          : const Text(
                              "Verify OTP",

                              style:
                                  TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              /// RESEND

              Center(
                child: TextButton(
                  onPressed:
                      resendSeconds == 0
                          ? sendOtp
                          : null,

                  child: Text(
                    resendSeconds == 0
                        ? "Resend OTP"
                        : "Resend OTP in $resendSeconds sec",

                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          resendSeconds == 0
                              ? const Color(
                                  0xFF4F46E5,
                                )
                              : Colors.grey,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              /// INFO

              Center(
                child: Text(
                  "OTP may auto detect automatically.",

                  textAlign:
                      TextAlign.center,

                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey.shade500,
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