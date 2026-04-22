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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = false;

  /// SAVE USER
  Future<void> saveUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName,
      'phone': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// GOOGLE LOGIN
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

      final userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await saveUser(userCredential.user!);
        goToHome();
      }
    } catch (e) {
      showError("Google Login Failed");
    } finally {
      setState(() => loading = false);
    }
  }

  /// EMAIL SIGNUP
  Future<void> signUpWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      showError("Enter valid email & password");
      return;
    }

    try {
      setState(() => loading = true);

      final userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await saveUser(userCredential.user!);
        goToHome();
      }
    } catch (e) {
      showError("Signup Failed");
    } finally {
      setState(() => loading = false);
    }
  }

  /// EMAIL LOGIN
  Future<void> loginWithEmail() async {
    try {
      setState(() => loading = true);

      final userCredential =
          await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await saveUser(userCredential.user!);
        goToHome();
      }
    } catch (e) {
      showError("Login Failed");
    } finally {
      setState(() => loading = false);
    }
  }

  void goToHome() {
    Navigator.pushReplacementNamed(context, '/bottomnav');
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),

              /// 🔥 HEADER
              const Text(
                "CallMe",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Login or Signup",
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 30),

              /// 🔥 CARD UI
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
                        /// EMAIL
                        _inputField(
                          controller: emailController,
                          label: "Email",
                          icon: Icons.email,
                        ),

                        const SizedBox(height: 15),

                        /// PASSWORD
                        _inputField(
                          controller: passwordController,
                          label: "Password",
                          icon: Icons.lock,
                          obscure: true,
                        ),

                        const SizedBox(height: 20),

                        /// SIGNUP BUTTON
                        _primaryButton(
                          text: "Sign Up",
                          onTap: signUpWithEmail,
                        ),

                        /// LOGIN TEXT
                        TextButton(
                          onPressed: loginWithEmail,
                          child:
                              const Text("Already have account? Login"),
                        ),

                        const SizedBox(height: 20),

                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("OR"),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// PHONE
                        _inputField(
                          controller: phoneController,
                          label: "Mobile Number",
                          icon: Icons.phone,
                          prefix: "+91 ",
                        ),

                        const SizedBox(height: 15),

                        _primaryButton(
                          text: "Send OTP",
                          onTap: () {
                            final phone = phoneController.text.trim();
                            if (phone.length != 10) {
                              showError("Enter valid phone");
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    OtpPage(phone: "+91$phone"),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        /// GOOGLE BUTTON
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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

                        /// GUEST
                        TextButton(
                          onPressed: goToHome,
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
    );
  }

  /// 🔹 INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 🔹 PRIMARY BUTTON
  Widget _primaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3F51B5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}