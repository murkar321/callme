import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'otp_page.dart';
import 'role_selection_page.dart'; // ✅ ADD THIS

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = false;

  /// 🔥 HANDLE USER DATA + NAVIGATION
  Future<void> handleUserAfterLogin(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    final doc = await userRef.get();

    bool isProvider = false;
    bool isAdmin = false;

    if (!doc.exists) {
      /// ✅ NEW USER → CREATE DATA
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'photo': user.photoURL,
        'isProvider': false,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } else {
      /// ✅ EXISTING USER → FETCH ROLES
      final data = doc.data()!;
      isProvider = data['isProvider'] ?? false;
      isAdmin = data['isAdmin'] ?? false;
    }

    if (!mounted) return;

    /// 🚀 NAVIGATE TO ROLE SELECTION
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

  // ✅ GOOGLE SIGN-IN
  Future<void> signInWithGoogle() async {
    try {
      setState(() => loading = true);

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        await handleUserAfterLogin(user); // ✅ NEW FLOW
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
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
                "Welcome to CallMe",
                style:
                    TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sign up or log in securely",
                style:
                    TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              /// 📞 PHONE INPUT
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  prefixText: "+91 ",
                  prefixIcon:
                      const Icon(Icons.phone, color: Colors.indigo),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// 📲 OTP BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final phone = phoneController.text.trim();

                    if (phone.length != 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text("Enter valid phone number")),
                      );
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Send OTP",
                    style: TextStyle(
                        fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// DIVIDER
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              /// 🔐 GOOGLE LOGIN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: Image.asset(
                    "assets/google.png",
                    height: 22,
                  ),
                  label: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Continue with Google"),
                  onPressed:
                      loading ? null : signInWithGoogle,
                ),
              ),

              const Spacer(),

              /// ⚠️ GUEST LOGIN (NO ROLE)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, '/bottomnav');
                  },
                  child: const Text(
                    "Continue without login",
                    style:
                        TextStyle(color: Colors.indigo),
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