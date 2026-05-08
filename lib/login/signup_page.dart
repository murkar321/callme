import 'package:callme/screens/bottom_nav_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'otp_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = false;
  bool obscurePassword = true;

  /// ================= SAVE USER =================
  Future<void> saveUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? "",
      'name': user.displayName ?? "",
      'phone': user.phoneNumber ?? "",
      'photo': user.photoURL ?? "",
      'providers': user.providerData.map((e) => e.providerId).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ================= LINK GOOGLE =================
  Future<void> linkGoogle(User user) async {
    final providers =
        user.providerData.map((e) => e.providerId).toList();

    if (providers.contains('google.com')) return;

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);
    } catch (e) {
      debugPrint("Google link error: $e");
    }
  }

  /// ================= NAVIGATION =================
  void goToHome(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => BottomNavPage(
          userPhone: user.phoneNumber ?? "",
          userEmail: user.email ?? "",
        ),
      ),
    );
  }

  /// ================= GOOGLE SIGN-IN =================
  Future<void> signInWithGoogle() async {
    try {
      setState(() => loading = true);

      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential;

      try {
        userCredential =
            await _auth.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code ==
            'account-exists-with-different-credential') {
          showError("Login with email first, then try Google");
          return;
        }
        rethrow;
      }

      final user = userCredential.user!;

      /// 🔥 LINK IF ALREADY LOGGED IN (OTP/EMAIL FLOW)
      if (_auth.currentUser != null &&
          _auth.currentUser!.uid != user.uid) {
        try {
          await _auth.currentUser!
              .linkWithCredential(credential);
        } catch (e) {
          debugPrint("Link error: $e");
        }
      }

      await saveUser(user);
      goToHome(user);

    } catch (e) {
      showError("Google Sign-In failed");
    } finally {
      setState(() => loading = false);
    }
  }

  /// ================= EMAIL SIGNUP =================
  Future<void> signUpEmail() async {
    try {
      setState(() => loading = true);

      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      /// 🔥 IF USER ALREADY EXISTS (OTP USER)
      if (_auth.currentUser != null) {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        final userCred = await _auth.currentUser!
            .linkWithCredential(credential);

        final user = userCred.user!;
        await saveUser(user);
        goToHome(user);
        return;
      }

      /// NORMAL SIGNUP
      final userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      await saveUser(user);
      goToHome(user);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showError("Email already exists. Please login.");
      } else {
        showError(e.message ?? "Signup failed");
      }
    } finally {
      setState(() => loading = false);
    }
  }

  /// ================= EMAIL LOGIN =================
  Future<void> loginEmail() async {
    try {
      setState(() => loading = true);

      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      /// 🔥 LINK GOOGLE AUTOMATICALLY
      await linkGoogle(user);

      await saveUser(user);
      goToHome(user);

    } catch (e) {
      showError("Login failed");
    } finally {
      setState(() => loading = false);
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    /// ✅ UI SAME (UNCHANGED)
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  "CallMe",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text("Login or Signup",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 30),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [

                          /// PHONE
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "Mobile Number",
                              prefixText: "+91 ",
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 15),

                          ElevatedButton(
                            onPressed: () {
                              if (phoneController.text.length != 10) {
                                showError("Enter valid phone");
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OtpPage(
                                    phone: "+91${phoneController.text}",
                                  ),
                                ),
                              );
                            },
                            child: const Text("Send OTP"),
                          ),

                          const SizedBox(height: 25),
                          const Divider(),
                          const SizedBox(height: 25),

                          /// EMAIL
                          TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// PASSWORD
                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: signUpEmail,
                            child: const Text("Sign Up"),
                          ),

                          TextButton(
                            onPressed: loginEmail,
                            child:
                                const Text("Already have account? Login"),
                          ),

                          const SizedBox(height: 20),

                          /// GOOGLE
                          OutlinedButton.icon(
                            icon: Image.asset(
                              "assets/google.png",
                              height: 22,
                            ),
                            label: loading
                                ? const CircularProgressIndicator()
                                : const Text("Continue with Google"),
                            onPressed:
                                loading ? null : signInWithGoogle,
                          ),

                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BottomNavPage(
                                    userPhone: "",
                                    userEmail: "",
                                  ),
                                ),
                              );
                            },
                            child: const Text("Continue as Guest"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}