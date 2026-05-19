import 'dart:async';

import 'package:callme/screens/bottom_nav_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OtpPage extends StatefulWidget {
  final String phone;

  const OtpPage({
    super.key,
    required this.phone,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController otpController =
      TextEditingController();

  String verificationId = "";

  bool isLoading = false;

  int resendSeconds = 120;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    sendOtp();
  }

  /// =====================================================
  /// START TIMER
  /// =====================================================

  void startTimer() {
    resendSeconds = 120;

    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (resendSeconds <= 0) {
          t.cancel();
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
  /// GENERATE USER DOC ID
  /// =====================================================

  String generateUserId(User user) {
    String base = "";

    if (user.email != null &&
        user.email!.isNotEmpty) {
      base = user.email!
          .split("@")
          .first;
    } else if (user.phoneNumber != null &&
        user.phoneNumber!.isNotEmpty) {
      base = user.phoneNumber!
          .replaceAll("+91", "");
    } else {
      base = "user";
    }

    base = base
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );

    return "${base}_${DateTime.now().millisecondsSinceEpoch}";
  }

  /// =====================================================
  /// SAVE USER
  /// =====================================================

  Future<void> saveUser(User user) async {
    try {
      /// CHECK EXISTING USER
      final existingUser =
          await _firestore
              .collection("users")
              .where(
                "authUid",
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

      String docId;

      if (existingUser.docs.isNotEmpty) {
        docId = existingUser.docs.first.id;
      } else {
        docId = generateUserId(user);
      }

      await _firestore
          .collection("users")
          .doc(docId)
          .set(
        {
          "docId": docId,

          /// AUTH
          "authUid": user.uid,
          "uid": user.uid,

          /// USER INFO
          "name": user.displayName ?? "",
          "email": user.email ?? "",
          "phone":
              user.phoneNumber ??
                  widget.phone,
          "photo": user.photoURL ?? "",

          /// LOGIN PROVIDERS
          "providers": user.providerData
              .map((e) => e.providerId)
              .toList(),

          /// STATUS
          "isActive": true,

          /// TIMESTAMPS
          "updatedAt":
              FieldValue.serverTimestamp(),

          "lastLogin":
              FieldValue.serverTimestamp(),

          "createdAt":
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
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
      setState(() {
        isLoading = true;
      });

      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phone,

        timeout: const Duration(
          seconds: 120,
        ),

        /// AUTO VERIFY
        verificationCompleted:
            (
              PhoneAuthCredential
                  credential,
            ) async {
          try {
            final userCredential =
                await _auth
                    .signInWithCredential(
              credential,
            );

            final user =
                userCredential.user;

            if (user != null) {
              await saveUser(user);

              if (!mounted) return;

              goHome(user);
            }
          } catch (e) {
            showMessage(
              "Auto verification failed",
              isError: true,
            );
          }
        },

        /// FAILED
        verificationFailed:
            (
              FirebaseAuthException e,
            ) {
          showMessage(
            e.message ??
                "OTP verification failed",
            isError: true,
          );

          setState(() {
            isLoading = false;
          });
        },

        /// OTP SENT
        codeSent: (
          String verification,
          int? resendToken,
        ) {
          verificationId = verification;

          startTimer();

          showMessage(
            "OTP sent successfully",
          );

          setState(() {
            isLoading = false;
          });
        },

        /// TIMEOUT
        codeAutoRetrievalTimeout:
            (String verification) {
          verificationId = verification;
        },
      );
    } catch (e) {
      showMessage(
        "Failed to send OTP",
        isError: true,
      );

      setState(() {
        isLoading = false;
      });
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
        isLoading = true;
      });

      final credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential =
          await _auth
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

      if (!mounted) return;

      goHome(user);
    } on FirebaseAuthException catch (e) {
      showMessage(
        e.message ?? "Invalid OTP",
        isError: true,
      );
    } catch (e) {
      showMessage(
        "Something went wrong",
        isError: true,
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
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
        backgroundColor:
            isError
                ? Colors.red
                : Colors.green,
        content: Text(message),
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
        builder: (_) => BottomNavPage(
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
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 10),

              /// BACK BUTTON
              InkWell(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),

                onTap: () {
                  Navigator.pop(context);
                },

                child: Container(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(
                          0.04,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),

                  child: const Icon(
                    Icons
                        .arrow_back_ios_new_rounded,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              /// TITLE
              const Text(
                "OTP Verification",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Enter the verification code sent to",

                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.phone,

                style: const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 50),

              /// OTP BOX
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.05,
                      ),
                      blurRadius: 12,
                    ),
                  ],
                ),

                child: TextField(
                  controller: otpController,

                  keyboardType:
                      TextInputType.number,

                  maxLength: 6,

                  textAlign:
                      TextAlign.center,

                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 12,
                    fontWeight:
                        FontWeight.bold,
                  ),

                  decoration:
                      const InputDecoration(
                    counterText: "",
                    border:
                        InputBorder.none,
                    hintText: "------",
                    contentPadding:
                        EdgeInsets.symmetric(
                      vertical: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : verifyOtp,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.black,

                    foregroundColor:
                        Colors.white,

                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),

                  child:
                      isLoading
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 28),

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
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,

                      color:
                          resendSeconds == 0
                              ? Colors.black
                              : Colors.grey,
                    ),
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