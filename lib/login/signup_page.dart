import 'package:callme/screens/bottom_nav_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() =>
      _SignupPageState();
}

class _SignupPageState
    extends State<SignupPage> {
  /// =====================================================
  /// CONTROLLER
  /// =====================================================

  final TextEditingController
      phoneController =
      TextEditingController();

  /// =====================================================
  /// FIREBASE
  /// =====================================================

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  /// =====================================================
  /// STATE
  /// =====================================================

  bool loading = false;

  /// =====================================================
  /// SAVE USER
  /// =====================================================

  Future<void> saveUser(
    User user,
  ) async {
    try {
      await firestore
          .collection("users")
          .doc(user.uid)
          .set(
        {
          "uid": user.uid,
          "name":
              user.displayName ?? "",
          "email":
              user.email ?? "",
          "phone":
              user.phoneNumber ?? "",
          "photo":
              user.photoURL ?? "",
          "providers": user
              .providerData
              .map(
                (e) => e.providerId,
              )
              .toList(),
          "updatedAt":
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      debugPrint(
        "Save User Error: $e",
      );
    }
  }

  /// =====================================================
  /// GOOGLE LOGIN
  /// =====================================================

  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        loading = true;
      });

      final GoogleSignIn
          googleSignIn =
          GoogleSignIn();

      await googleSignIn.signOut();

      final googleUser =
          await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          loading = false;
        });

        return;
      }

      final googleAuth =
          await googleUser
              .authentication;

      final credential =
          GoogleAuthProvider
              .credential(
        accessToken:
            googleAuth.accessToken,
        idToken:
            googleAuth.idToken,
      );

      final userCredential =
          await auth
              .signInWithCredential(
        credential,
      );

      final user =
          userCredential.user!;

      await saveUser(user);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BottomNavPage(
            userPhone:
                user.phoneNumber ??
                    "",
            userEmail:
                user.email ?? "",
          ),
        ),
      );
    } catch (e) {
      showError(
        "Google Sign In Failed",
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// =====================================================
  /// ERROR
  /// =====================================================

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(msg),

        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            Colors.red.shade400,
      ),
    );
  }

  /// =====================================================
  /// DISPOSE
  /// =====================================================

  @override
  void dispose() {
    phoneController.dispose();
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

      resizeToAvoidBottomInset:
          true,

      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),

          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
          ),

          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),

              /// =================================================
              /// LOGO
              /// =================================================

              Container(
                height: 120,
                width: 120,

                padding:
                    const EdgeInsets.all(
                  18,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  shape:
                      BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.08,
                      ),

                      blurRadius: 25,

                      offset:
                          const Offset(
                        0,
                        12,
                      ),
                    ),
                  ],
                ),

                child: ClipOval(
                  child: Image.asset(
                    "assets/logo.png",

                    fit:
                        BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              /// =================================================
              /// TITLE
              /// =================================================

              const Text(
                "Get Started",

                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,

                  color:
                      Color(0xFF111827),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                "Login using your mobile number or continue with Google",

                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  fontSize: 15,

                  height: 1.5,

                  color: Colors
                      .grey.shade600,
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              /// =================================================
              /// MAIN CARD
              /// =================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(
                  24,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.04,
                      ),

                      blurRadius: 20,

                      offset:
                          const Offset(
                        0,
                        8,
                      ),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    /// LABEL

                    const Text(
                      "Mobile Number",

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    /// PHONE FIELD

                    Container(
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF7F8FC,
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),

                        border:
                            Border.all(
                          color: Colors
                              .grey
                              .shade200,
                        ),
                      ),

                      child: TextField(
                        controller:
                            phoneController,

                        keyboardType:
                            TextInputType
                                .phone,

                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),

                        decoration:
                            InputDecoration(
                          border:
                              InputBorder.none,

                          hintText:
                              "Enter mobile number",

                          prefixIcon:
                              const Icon(
                            Icons.phone_rounded,

                            color:
                                Color(
                              0xFF3D5AFE,
                            ),
                          ),

                          prefixText:
                              "+91 ",

                          contentPadding:
                              const EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    /// OTP BUTTON

                    SizedBox(
                      width:
                          double.infinity,

                      height: 58,

                      child:
                          ElevatedButton(
                        onPressed:
                            loading
                                ? null
                                : () {
                                    if (phoneController
                                            .text
                                            .trim()
                                            .length !=
                                        10) {
                                      showError(
                                        "Enter valid mobile number",
                                      );

                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                OtpPage(
                                          phone:
                                              "+91${phoneController.text.trim()}",
                                        ),
                                      ),
                                    );
                                  },

                        style:
                            ElevatedButton
                                .styleFrom(
                          elevation: 0,

                          backgroundColor:
                              const Color(
                            0xFF3D5AFE,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),
                        ),

                        child:
                            loading
                                ? const CircularProgressIndicator(
                                    color:
                                        Colors.white,
                                  )
                                : const Text(
                                    "Continue with OTP",

                                    style:
                                        TextStyle(
                                      fontSize:
                                          16,

                                      fontWeight:
                                          FontWeight.bold,

                                      color:
                                          Colors.white,
                                    ),
                                  ),
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    /// DIVIDER

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),

                          child: Text(
                            "OR",

                            style:
                                TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w700,

                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ),

                        Expanded(
                          child: Divider(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    /// GOOGLE BUTTON

                    SizedBox(
                      width:
                          double.infinity,

                      height: 58,

                      child:
                          OutlinedButton.icon(
                        onPressed:
                            loading
                                ? null
                                : signInWithGoogle,

                        icon: Image.asset(
                          "assets/google.png",

                          height: 22,
                        ),

                        label: const Text(
                          "Continue with Google",

                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .w700,

                            color:
                                Colors.black,
                          ),
                        ),

                        style:
                            OutlinedButton
                                .styleFrom(
                          backgroundColor:
                              Colors.white,

                          side:
                              BorderSide(
                            color: Colors
                                .grey
                                .shade300,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    /// GUEST BUTTON

                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const BottomNavPage(
                                userPhone: "",
                                userEmail: "",
                              ),
                            ),
                          );
                        },

                        child: Text(
                          "Continue as Guest",

                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,

                            color: Colors
                                .grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}