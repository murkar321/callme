import 'package:callme/login/otp_page.dart';
import 'package:callme/screens/bottom_nav_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() =>
      _SignupPageState();
}

class _SignupPageState
    extends State<SignupPage> {
  /// =====================================================
  /// CONTROLLERS
  /// =====================================================

  final TextEditingController
      phoneController =
      TextEditingController();

  final TextEditingController
      emailController =
      TextEditingController();

  final TextEditingController
      passwordController =
      TextEditingController();

  /// =====================================================
  /// FIREBASE
  /// =====================================================

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  /// =====================================================
  /// STATE
  /// =====================================================

  bool loading = false;

  bool adminLoading = false;

  bool obscurePassword = true;

  /// =====================================================
  /// INIT
  /// =====================================================

  @override
  void initState() {
    super.initState();

    autoLogin();
  }

  /// =====================================================
  /// AUTO LOGIN
  /// =====================================================

  Future<void> autoLogin() async {
    final user = auth.currentUser;

    if (user == null) return;

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

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
  /// PHONE LOGIN
  /// =====================================================

  void continueWithPhone() {
    FocusScope.of(context).unfocus();

    final phone =
        phoneController.text
            .trim();

    if (phone.isEmpty) {
      showError(
        "Enter mobile number",
      );
      return;
    }

    if (phone.length != 10) {
      showError(
        "Enter valid 10 digit mobile number",
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpPage(
          phone: "+91$phone",
          isLogin: true,
        ),
      ),
    );
  }

  /// =====================================================
  /// ADMIN EMAIL LOGIN
  /// =====================================================

  Future<void> adminLogin() async {
    FocusScope.of(context).unfocus();

    final email =
        emailController.text
            .trim();

    final password =
        passwordController.text
            .trim();

    if (email.isEmpty) {
      showError(
        "Enter admin email",
      );
      return;
    }

    if (password.isEmpty) {
      showError(
        "Enter password",
      );
      return;
    }

    try {
      setState(() {
        adminLoading = true;
      });

      await auth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BottomNavPage(
            userPhone:
                auth.currentUser
                        ?.phoneNumber ??
                    "",
            userEmail:
                auth.currentUser
                        ?.email ??
                    "",
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      showError(
        e.message ??
            "Admin login failed",
      );
    } catch (e) {
      showError(
        "Something went wrong",
      );
    } finally {
      if (mounted) {
        setState(() {
          adminLoading = false;
        });
      }
    }
  }

  /// =====================================================
  /// GUEST LOGIN
  /// =====================================================

  void continueAsGuest() {
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

    emailController.dispose();

    passwordController.dispose();

    super.dispose();
  }

  /// =====================================================
  /// UI
  /// =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7FC),

      body: Stack(
        children: [
          /// BACKGROUND

          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: Colors.blue
                    .withOpacity(
                  0.08,
                ),
              ),
            ),
          ),

          Positioned(
            top: 120,
            left: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color: Colors
                    .deepPurple
                    .withOpacity(
                  0.06,
                ),
              ),
            ),
          ),

          SafeArea(
            child:
                SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 20,
              ),

              child: Center(
                child:
                    ConstrainedBox(
                  constraints:
                      const BoxConstraints(
                    maxWidth: 470,
                  ),

                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),

                      /// LOGO

                      Hero(
                        tag: "logo",

                        child: Container(
                          width: 120,
                          height: 120,

                          padding:
                              const EdgeInsets.all(
                            18,
                          ),

                          decoration:
                              BoxDecoration(
                            shape:
                                BoxShape.circle,

                            gradient:
                                const LinearGradient(
                              colors: [
                                Color(
                                  0xFF4F46E5,
                                ),
                                Color(
                                  0xFF2563EB,
                                ),
                              ],
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .blue
                                    .withOpacity(
                                  0.25,
                                ),
                                blurRadius: 30,
                                offset:
                                    const Offset(
                                  0,
                                  14,
                                ),
                              ),
                            ],
                          ),

                          child: Container(
                            padding:
                                const EdgeInsets.all(
                              18,
                            ),

                            decoration:
                                const BoxDecoration(
                              color: Colors.white,
                              shape:
                                  BoxShape.circle,
                            ),

                            child: ClipOval(
                              child:
                                  Image.asset(
                                "assets/logo.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      /// TITLE

                      const Text(
                        "Welcome to CallMe",

                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          fontSize: 30,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        "Login using mobile OTP or admin email login.",

                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors
                              .grey.shade600,
                        ),
                      ),

                      const SizedBox(
                        height: 36,
                      ),

                      /// PHONE LOGIN CARD

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          24,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                            32,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                0.05,
                              ),
                              blurRadius: 30,
                              offset:
                                  const Offset(
                                0,
                                10,
                              ),
                            ),
                          ],
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            const Text(
                              "User Login",

                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            Text(
                              "Continue with mobile OTP verification.",

                              style:
                                  TextStyle(
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            /// PHONE FIELD

                            Container(
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF8FAFC,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  20,
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

                                maxLength: 10,

                                decoration:
                                    InputDecoration(
                                  counterText: "",

                                  border:
                                      InputBorder
                                          .none,

                                  hintText:
                                      "Enter mobile number",

                                  prefixText:
                                      "+91 ",

                                  prefixStyle:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        Colors.black,
                                  ),

                                  prefixIcon:
                                      const Icon(
                                    Icons.phone,
                                    color:
                                        Color(
                                      0xFF4F46E5,
                                    ),
                                  ),

                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            /// OTP BUTTON

                            SizedBox(
                              width:
                                  double.infinity,

                              height: 58,

                              child:
                                  ElevatedButton(
                                onPressed:
                                    continueWithPhone,

                                style:
                                    ElevatedButton.styleFrom(
                                  elevation: 0,

                                  backgroundColor:
                                      const Color(
                                    0xFF4F46E5,
                                  ),

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                ),

                                child: const Text(
                                  "Continue with OTP",

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            Center(
                              child: TextButton(
                                onPressed:
                                    continueAsGuest,

                                child: Text(
                                  "Continue as Guest",

                                  style:
                                      TextStyle(
                                    color: Colors
                                        .grey
                                        .shade700,

                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      /// ADMIN LOGIN CARD

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          24,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors.white,

                          borderRadius:
                              BorderRadius.circular(
                            32,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
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
                            Row(
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(
                                    12,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .orange
                                        .withOpacity(
                                      0.12,
                                    ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      16,
                                    ),
                                  ),

                                  child: const Icon(
                                    Icons
                                        .admin_panel_settings_rounded,
                                    color:
                                        Colors.orange,
                                  ),
                                ),

                                const SizedBox(
                                  width: 14,
                                ),

                                const Expanded(
                                  child: Text(
                                    "Admin Login",

                                    style:
                                        TextStyle(
                                      fontSize:
                                          20,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              "Admins can login using email and password.",

                              style:
                                  TextStyle(
                                color: Colors
                                    .grey
                                    .shade600,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(
                              height: 24,
                            ),

                            /// EMAIL FIELD

                            Container(
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF8FAFC,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  20,
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
                                    emailController,

                                keyboardType:
                                    TextInputType
                                        .emailAddress,

                                decoration:
                                    const InputDecoration(
                                  border:
                                      InputBorder
                                          .none,

                                  hintText:
                                      "Enter admin email",

                                  prefixIcon:
                                      Icon(
                                    Icons.email,
                                    color:
                                        Color(
                                      0xFF4F46E5,
                                    ),
                                  ),

                                  contentPadding:
                                      EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            /// PASSWORD FIELD

                            Container(
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF8FAFC,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  20,
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
                                    passwordController,

                                obscureText:
                                    obscurePassword,

                                decoration:
                                    InputDecoration(
                                  border:
                                      InputBorder
                                          .none,

                                  hintText:
                                      "Enter password",

                                  prefixIcon:
                                      const Icon(
                                    Icons.lock,
                                    color:
                                        Color(
                                      0xFF4F46E5,
                                    ),
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
                                          ? Icons
                                              .visibility_off
                                          : Icons
                                              .visibility,
                                    ),
                                  ),

                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 24,
                            ),

                            /// LOGIN BUTTON

                            SizedBox(
                              width:
                                  double.infinity,

                              height: 58,

                              child:
                                  ElevatedButton(
                                onPressed:
                                    adminLoading
                                        ? null
                                        : adminLogin,

                                style:
                                    ElevatedButton.styleFrom(
                                  elevation: 0,

                                  backgroundColor:
                                      Colors.orange,

                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                ),

                                child:
                                    adminLoading
                                        ? const SizedBox(
                                            height:
                                                24,
                                            width:
                                                24,
                                            child:
                                                CircularProgressIndicator(
                                              color:
                                                  Colors.white,
                                              strokeWidth:
                                                  2.5,
                                            ),
                                          )
                                        : const Text(
                                            "Admin Login",

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors.white,
                                              fontSize:
                                                  16,
                                              fontWeight:
                                                  FontWeight.bold,
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
            ),
          ),
        ],
      ),
    );
  }
}