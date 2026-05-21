import 'package:callme/screens/bottom_nav_page.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'otp_page.dart';

class SignupPage extends StatefulWidget {

  const SignupPage({
    super.key,
  });

  @override
  State<SignupPage> createState() =>
      _SignupPageState();
}

class _SignupPageState
    extends State<SignupPage> {

  /// =====================================================
  /// CONTROLLERS
  /// =====================================================

  final phoneController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
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

  bool obscurePassword = true;

  /// =====================================================
  /// GENERATE DOC ID
  /// =====================================================

  String generateUserDocId({

    required String email,

    required String phone,
  }) {

    String base = "";

    if (email.isNotEmpty) {

      base =
          email.split("@").first;

    } else if (phone.isNotEmpty) {

      base =
          phone.replaceAll(
            "+91",
            "",
          );

    } else {

      base = "user";
    }

    base = base

        .trim()

        .toLowerCase()

        .replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );

    final unique =
        DateTime.now()
            .millisecondsSinceEpoch
            .toString();

    return "${base}_$unique";
  }

  /// =====================================================
  /// FIND EXISTING USER
  /// =====================================================

  Future<DocumentSnapshot?> findExistingUser({

    String? authUid,

    String? email,

    String? phone,
  }) async {

    try {

      /// AUTH UID

      if (authUid != null &&
          authUid.isNotEmpty) {

        final result =

        await firestore

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

        final result =

        await firestore

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

        final result =

        await firestore

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

    } catch (e) {

      debugPrint(
        "Find User Error: $e",
      );

      return null;
    }
  }

  /// =====================================================
  /// SAVE USER
  /// =====================================================

  Future<void> saveUser(
      User user,
      ) async {

    try {

      /// IMPORTANT
      /// REFRESH AUTH USER

      await user.reload();

      final refreshedUser =
          auth.currentUser!;

      /// FIND EXISTING USER

      final existing =
      await findExistingUser(

        authUid:
        refreshedUser.uid,

        email:
        refreshedUser.email,

        phone:
        refreshedUser.phoneNumber,
      );

      String docId;

      Map<String, dynamic>
      oldData = {};

      /// EXISTING USER

      if (existing != null) {

        docId =
            existing.id;

        oldData =

            existing.data()
            as Map<String, dynamic>;

      } else {

        /// NEW USER

        docId =
            generateUserDocId(

              email:
              refreshedUser.email ?? "",

              phone:
              refreshedUser.phoneNumber ?? "",
            );
      }

      /// =================================================
      /// KEEP OLD PROVIDERS
      /// =================================================

      List providers =

      List.from(
        oldData['providers'] ?? [],
      );

      final authProviders =

      refreshedUser.providerData

          .map((e) => e.providerId)

          .toList();

      for (var p in authProviders) {

        if (!providers.contains(p)) {

          providers.add(p);
        }
      }

      /// =================================================
      /// IMPORTANT FIX
      /// NEVER OVERWRITE WITH EMPTY DATA
      /// =================================================

      final data = {

        /// IDS

        'docId':
        docId,

        'authUid':
        refreshedUser.uid,

        'uid':
        refreshedUser.uid,

        /// USER DATA

        'email':

        refreshedUser.email != null &&
            refreshedUser.email!
                .trim()
                .isNotEmpty

            ? refreshedUser.email

            : oldData['email'] ?? "",

        'phone':

        refreshedUser.phoneNumber != null &&
            refreshedUser.phoneNumber!
                .trim()
                .isNotEmpty

            ? refreshedUser.phoneNumber

            : oldData['phone'] ?? "",

        'name':

        refreshedUser.displayName != null &&
            refreshedUser.displayName!
                .trim()
                .isNotEmpty

            ? refreshedUser.displayName

            : oldData['name'] ?? "",

        'photo':

        refreshedUser.photoURL != null &&
            refreshedUser.photoURL!
                .trim()
                .isNotEmpty

            ? refreshedUser.photoURL

            : oldData['photo'] ?? "",

        /// IMPORTANT
        /// PRESERVE PROFILE DATA

        'firstName':
        oldData['firstName'] ?? "",

        'lastName':
        oldData['lastName'] ?? "",

        'address':
        oldData['address'] ?? "",

        /// PROVIDERS

        'providers':
        providers,

        /// STATUS

        'role':
        oldData['role'] ?? "user",

        'status':
        oldData['status'] ?? "active",

        /// TIMESTAMPS

        'updatedAt':
        FieldValue.serverTimestamp(),

        'lastLogin':
        FieldValue.serverTimestamp(),

        'createdAt':

        oldData['createdAt'] ??

            FieldValue.serverTimestamp(),
      };

      /// =================================================
      /// SAVE
      /// =================================================

      await firestore

          .collection("users")

          .doc(docId)

          .set(

        data,

        SetOptions(
          merge: true,
        ),
      );

    } catch (e) {

      debugPrint(
        "Save User Error: $e",
      );

      rethrow;
    }
  }

  /// =====================================================
  /// GOOGLE LINK
  /// =====================================================

  Future<void> linkGoogle(
      User user,
      ) async {

    try {

      final providers =

      user.providerData

          .map((e) => e.providerId)

          .toList();

      if (providers.contains(
        'google.com',
      )) {

        return;
      }

      final googleUser =

      await GoogleSignIn()
          .signIn();

      if (googleUser == null) {

        return;
      }

      final googleAuth =

      await googleUser
          .authentication;

      final credential =
      GoogleAuthProvider.credential(

        accessToken:
        googleAuth.accessToken,

        idToken:
        googleAuth.idToken,
      );

      await user.linkWithCredential(
        credential,
      );

    } catch (e) {

      debugPrint(
        "Link Google Error: $e",
      );
    }
  }

  /// =====================================================
  /// NAVIGATE
  /// =====================================================

  void goToHome(User user) {

    Navigator.pushReplacement(

      context,

      MaterialPageRoute(

        builder: (_) => BottomNavPage(

          userPhone:
          user.phoneNumber ?? "",

          userEmail:
          user.email ?? "",
        ),
      ),
    );
  }

  /// =====================================================
  /// GOOGLE LOGIN
  /// =====================================================

  Future<void> signInWithGoogle() async {

    try {

      setState(() {
        loading = true;
      });

      final googleSignIn =
      GoogleSignIn();

      /// FORCE ACCOUNT PICKER

      await googleSignIn
          .signOut();

      final googleUser =

      await googleSignIn
          .signIn();

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
      GoogleAuthProvider.credential(

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

      /// IMPORTANT

      await user.reload();

      await saveUser(user);

      if (!mounted) return;

      goToHome(user);

    } on FirebaseAuthException catch (e) {

      debugPrint(
        "Google Login Error: $e",
      );

      if (mounted) {

        showError(
          e.message ??
              "Google Sign-In failed",
        );
      }

    } finally {

      if (mounted) {

        setState(() {
          loading = false;
        });
      }
    }
  }

  /// =====================================================
  /// EMAIL SIGNUP
  /// =====================================================

  Future<void> signUpEmail() async {

    try {

      setState(() {
        loading = true;
      });

      final email =

      emailController.text
          .trim();

      final password =

      passwordController.text
          .trim();

      /// LINK EXISTING

      if (auth.currentUser != null) {

        final credential =

        EmailAuthProvider
            .credential(

          email: email,

          password: password,
        );

        final userCred =

        await auth.currentUser!
            .linkWithCredential(
          credential,
        );

        final user =
        userCred.user!;

        await user.reload();

        await saveUser(user);

        if (!mounted) return;

        goToHome(user);

        return;
      }

      /// NORMAL SIGNUP

      final userCredential =

      await auth

          .createUserWithEmailAndPassword(

        email: email,

        password: password,
      );

      final user =
      userCredential.user!;

      await user.reload();

      await saveUser(user);

      if (!mounted) return;

      goToHome(user);

    } on FirebaseAuthException catch (e) {

      debugPrint(
        "Signup Error: $e",
      );

      if (mounted) {

        showError(

          e.message ??

              "Signup failed",
        );
      }

    } finally {

      if (mounted) {

        setState(() {
          loading = false;
        });
      }
    }
  }

  /// =====================================================
  /// EMAIL LOGIN
  /// =====================================================

  Future<void> loginEmail() async {

    try {

      setState(() {
        loading = true;
      });

      final email =

      emailController.text
          .trim();

      final password =

      passwordController.text
          .trim();

      final userCredential =

      await auth
          .signInWithEmailAndPassword(

        email: email,

        password: password,
      );

      final user =
      userCredential.user!;

      /// IMPORTANT

      await user.reload();

      await linkGoogle(user);

      await saveUser(user);

      if (!mounted) return;

      goToHome(user);

    } on FirebaseAuthException catch (e) {

      debugPrint(
        "Login Error: $e",
      );

      if (mounted) {

        showError(
          e.message ??
              "Login failed",
        );
      }

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

        behavior:
        SnackBarBehavior.floating,

        content:
        Text(msg),
      ),
    );
  }

  /// =====================================================
  /// DISPOSE
  /// =====================================================

  @override
  void dispose() {

    phoneController.dispose();

    emailController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  /// =====================================================
  /// UI
  /// =====================================================

  @override
  Widget build(BuildContext context) {

    final size =
    MediaQuery.of(context).size;

    return Scaffold(

      body: SafeArea(

        child: Container(

          width: double.infinity,

          height: double.infinity,

          decoration: const BoxDecoration(

            gradient: LinearGradient(

              colors: [

                Color(0xFF3F51B5),

                Color(0xFF5C6BC0),
              ],

              begin:
              Alignment.topCenter,

              end:
              Alignment.bottomCenter,
            ),
          ),

          child: SingleChildScrollView(

            child: ConstrainedBox(

              constraints: BoxConstraints(
                minHeight: size.height,
              ),

              child: Column(

                children: [

                  const SizedBox(height: 40),

                  const Icon(

                    Icons.miscellaneous_services,

                    size: 70,

                    color: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  const Text(

                    "CallMe",

                    style: TextStyle(

                      fontSize: 34,

                      fontWeight:
                      FontWeight.bold,

                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(

                    "Login or Signup",

                    style: TextStyle(

                      fontSize: 16,

                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Container(

                    width: double.infinity,

                    padding:
                    const EdgeInsets.all(24),

                    decoration:
                    const BoxDecoration(

                      color: Colors.white,

                      borderRadius:
                      BorderRadius.vertical(

                        top:
                        Radius.circular(34),
                      ),
                    ),

                    child: Column(

                      children: [

                        /// PHONE

                        TextField(

                          controller:
                          phoneController,

                          keyboardType:
                          TextInputType.phone,

                          decoration:
                          InputDecoration(

                            labelText:
                            "Mobile Number",

                            prefixText:
                            "+91 ",

                            filled: true,

                            fillColor:
                            Colors.grey.shade100,

                            border:
                            OutlineInputBorder(

                              borderRadius:
                              BorderRadius.circular(16),

                              borderSide:
                              BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(

                          width: double.infinity,

                          height: 52,

                          child: ElevatedButton(

                            onPressed: () {

                              if (phoneController
                                  .text
                                  .trim()
                                  .length != 10) {

                                showError(
                                  "Enter valid phone number",
                                );

                                return;
                              }

                              Navigator.push(

                                context,

                                MaterialPageRoute(

                                  builder: (_) =>
                                      OtpPage(

                                        phone:
                                        "+91${phoneController.text.trim()}",
                                      ),
                                ),
                              );
                            },

                            style:
                            ElevatedButton.styleFrom(

                              backgroundColor:
                              Colors.indigo,

                              shape:
                              RoundedRectangleBorder(

                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                            ),

                            child:
                            const Text(

                              "Send OTP",

                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Row(

                          children: [

                            Expanded(
                              child: Divider(),
                            ),

                            Padding(

                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),

                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                            Expanded(
                              child: Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        /// EMAIL

                        TextField(

                          controller:
                          emailController,

                          keyboardType:
                          TextInputType.emailAddress,

                          decoration:
                          InputDecoration(

                            labelText:
                            "Email",

                            filled: true,

                            fillColor:
                            Colors.grey.shade100,

                            border:
                            OutlineInputBorder(

                              borderRadius:
                              BorderRadius.circular(16),

                              borderSide:
                              BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// PASSWORD

                        TextField(

                          controller:
                          passwordController,

                          obscureText:
                          obscurePassword,

                          decoration:
                          InputDecoration(

                            labelText:
                            "Password",

                            filled: true,

                            fillColor:
                            Colors.grey.shade100,

                            border:
                            OutlineInputBorder(

                              borderRadius:
                              BorderRadius.circular(16),

                              borderSide:
                              BorderSide.none,
                            ),

                            suffixIcon:
                            IconButton(

                              onPressed: () {

                                setState(() {

                                  obscurePassword =
                                  !obscurePassword;
                                });
                              },

                              icon: Icon(

                                obscurePassword

                                    ? Icons.visibility_off

                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(

                          width: double.infinity,

                          height: 54,

                          child: ElevatedButton(

                            onPressed:
                            loading
                                ? null
                                : signUpEmail,

                            style:
                            ElevatedButton.styleFrom(

                              backgroundColor:
                              Colors.indigo,

                              shape:
                              RoundedRectangleBorder(

                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                            ),

                            child:

                            loading

                                ? const CircularProgressIndicator(
                              color: Colors.white,
                            )

                                : const Text(

                              "Sign Up",

                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextButton(

                          onPressed:
                          loading
                              ? null
                              : loginEmail,

                          child: const Text(
                            "Already have account? Login",
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// GOOGLE

                        SizedBox(

                          width: double.infinity,

                          height: 54,

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

                            label:

                            loading

                                ? const SizedBox(

                              height: 20,

                              width: 20,

                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )

                                : const Text(
                              "Continue with Google",
                            ),

                            style:
                            OutlinedButton.styleFrom(

                              shape:
                              RoundedRectangleBorder(

                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextButton(

                          onPressed: () {

                            Navigator.pushReplacement(

                              context,

                              MaterialPageRoute(

                                builder: (_) =>
                                    const BottomNavPage(

                                      userPhone: "",

                                      userEmail: "",
                                    ),
                              ),
                            );
                          },

                          child:
                          const Text(
                            "Continue as Guest",
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}