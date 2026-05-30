import 'package:callme/profile/about_page.dart';
import 'package:callme/profile/contactus_page.dart';
import 'package:callme/profile/feedback_page.dart';
import 'package:callme/profile/profile_page.dart';
import 'package:callme/screens/logo_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() =>
      _AccountPageState();
}

class _AccountPageState
    extends State<AccountPage> {
  /// =========================================================
  /// FIREBASE
  /// =========================================================

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

Future<void> openPrivacyPolicy() async {
  final Uri url = Uri.parse(
    'https://callmeallinoneservices.com/',
  );

  await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  );
}
  /// =========================================================
  /// USER DATA
  /// =========================================================

  String userName = "CallMe User";

  String userPhone = "";

  String userEmail = "";

  String profileImage = "";

  bool isLoading = true;

  /// =========================================================
  /// INIT
  /// =========================================================

  @override
  void initState() {
    super.initState();

    fetchUserData();
  }

  /// =========================================================
  /// GET USER DOC ID
  /// =========================================================

  String getUserDocId(User user) {
    /// PHONE USER

    if (user.phoneNumber != null &&
        user.phoneNumber!
            .trim()
            .isNotEmpty) {
      return user.phoneNumber!
          .trim();
    }

    /// GOOGLE USER

    if (user.email != null &&
        user.email!
            .trim()
            .isNotEmpty) {
      return user.email!
          .trim()
          .toLowerCase();
    }

    /// FALLBACK

    return user.uid;
  }

  /// =========================================================
  /// FETCH USER DATA
  /// =========================================================

  Future<void> fetchUserData() async {
    try {
      final user = auth.currentUser;

      if (user == null) {
        setState(() {
          isLoading = false;
        });

        return;
      }

      /// =====================================================
      /// FIXED DOC ID
      /// =====================================================

      final docId =
          getUserDocId(user);

      final doc = await firestore
          .collection("users")
          .doc(docId)
          .get();

      /// =====================================================
      /// USER FOUND
      /// =====================================================

      if (doc.exists) {
        final data =
            doc.data() ?? {};

        setState(() {
          userName =
              data["name"] ??
                  "CallMe User";

          userPhone =
              data["phone"] ?? "";

          userEmail =
              data["email"] ?? "";

          profileImage =
              data["photo"] ?? "";

          isLoading = false;
        });
      } else {
        /// ===================================================
        /// FALLBACK FROM FIREBASE AUTH
        /// ===================================================

        setState(() {
          userName =
              user.displayName ??
                  "CallMe User";

          userPhone =
              user.phoneNumber ?? "";

          userEmail =
              user.email ?? "";

          profileImage =
              user.photoURL ?? "";

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// =========================================================
  /// LOGOUT
  /// =========================================================

  Future<void> logout() async {
    try {
      try {
        await GoogleSignIn()
            .signOut();
      } catch (_) {}

      await auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LogoPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Logout Failed : $e",
          ),
        ),
      );
    }
  }

  /// =========================================================
  /// UI
  /// =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF4F7FC),

      /// =====================================================
      /// APP BAR
      /// =====================================================

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor:
            const Color(0xffF4F7FC),

        title: const Text(
          "My Account",

          style: TextStyle(
            color: Colors.black87,
            fontWeight:
                FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      /// =====================================================
      /// BODY
      /// =====================================================

      body:
          isLoading
              ? const Center(
                child:
                    CircularProgressIndicator(),
              )
              : SafeArea(
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    18,
                  ),

                  child: Column(
                    children: [
                      /// ===================================================
                      /// PROFILE CARD
                      /// ===================================================

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets.all(
                          24,
                        ),

                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(
                                0xff4A6CF7,
                              ),
                              Color(
                                0xff6F8CFF,
                              ),
                            ],

                            begin:
                                Alignment
                                    .topLeft,

                            end:
                                Alignment
                                    .bottomRight,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            32,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .blue
                                  .withOpacity(
                                0.18,
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

                        child: Row(
                          children: [
                            /// PROFILE IMAGE

                            Hero(
                              tag:
                                  "profile_image",

                              child: Container(
                                height: 90,
                                width: 90,

                                decoration:
                                    BoxDecoration(
                                  shape:
                                      BoxShape
                                          .circle,

                                  border:
                                      Border.all(
                                    color:
                                        Colors
                                            .white,

                                    width: 3,
                                  ),

                                  color:
                                      Colors
                                          .white,
                                ),

                                child:
                                    ClipOval(
                                  child:
                                      profileImage
                                              .isNotEmpty
                                          ? Image.network(
                                            profileImage,

                                            fit:
                                                BoxFit.cover,

                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                              return const Icon(
                                                Icons
                                                    .person_rounded,

                                                size:
                                                    45,

                                                color:
                                                    Color(
                                                  0xff4A6CF7,
                                                ),
                                              );
                                            },
                                          )
                                          : const Icon(
                                            Icons
                                                .person_rounded,

                                            size:
                                                45,

                                            color:
                                                Color(
                                              0xff4A6CF7,
                                            ),
                                          ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 18,
                            ),

                            /// USER INFO

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          12,

                                      vertical:
                                          6,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .white
                                          .withOpacity(
                                        0.16,
                                      ),

                                      borderRadius:
                                          BorderRadius.circular(
                                        30,
                                      ),
                                    ),

                                    child:
                                        const Text(
                                      "Welcome Back 👋",

                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white,

                                        fontWeight:
                                            FontWeight.w600,

                                        fontSize:
                                            13,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 14,
                                  ),

                                  Text(
                                    userName,

                                    maxLines:
                                        1,

                                    overflow:
                                        TextOverflow
                                            .ellipsis,

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors
                                              .white,

                                      fontSize:
                                          24,

                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  if (userPhone
                                      .isNotEmpty)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .phone_rounded,

                                          color:
                                              Colors
                                                  .white70,

                                          size:
                                              16,
                                        ),

                                        const SizedBox(
                                          width:
                                              6,
                                        ),

                                        Expanded(
                                          child:
                                              Text(
                                            userPhone,

                                            maxLines:
                                                1,

                                            overflow:
                                                TextOverflow
                                                    .ellipsis,

                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors.white,

                                              fontSize:
                                                  14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  if (userEmail
                                      .isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(
                                        top:
                                            6,
                                      ),

                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons
                                                .email_rounded,

                                            color:
                                                Colors
                                                    .white70,

                                            size:
                                                16,
                                          ),

                                          const SizedBox(
                                            width:
                                                6,
                                          ),

                                          Expanded(
                                            child:
                                                Text(
                                              userEmail,

                                              maxLines:
                                                  1,

                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,

                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.white,

                                                fontSize:
                                                    13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      /// ===================================================
                      /// TITLE
                      /// ===================================================

                      const Align(
                        alignment:
                            Alignment.centerLeft,

                        child: Text(
                          "Account Settings",

                          style: TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Colors.black87,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      /// PROFILE

                      _buildTile(
                        title: "Profile",

                        subtitle:
                            "Manage personal details",

                        icon:
                            Icons.person_outline,

                        color:
                            Colors.blue,

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      ProfilePage(
                                        phone:
                                            userPhone,
                                      ),
                            ),
                          );
                        },
                      ),

                      /// ABOUT

                      _buildTile(
                        title: "About Us",

                        subtitle:
                            "Know more about CallMe",

                        icon:
                            Icons.info_outline,

                        color:
                            Colors.orange,

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const AboutPage(),
                            ),
                          );
                        },
                      ),

                      /// CONTACT

                      _buildTile(
                        title: "Contact Us",

                        subtitle:
                            "Reach our support team",

                        icon:
                            Icons.support_agent,

                        color:
                            Colors.green,

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const ContactUsPage(),
                            ),
                          );
                        },
                      ),

                      /// FEEDBACK

                      _buildTile(
                        title: "Feedback",

                        subtitle:
                            "Share your experience",

                        icon:
                            Icons.feedback_outlined,

                        color:
                            Colors.purple,

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const FeedbackPage(),
                            ),
                          );
                        },
                      ),

                      /// PRIVACY

                     _buildTile(
  title: "Privacy Policy",
  subtitle: "Read our policies",
  icon: Icons.privacy_tip_outlined,
  color: Colors.red,
  onTap: openPrivacyPolicy,
),

                      const SizedBox(
                        height: 30,
                      ),

                      /// ===================================================
                      /// LOGOUT BUTTON
                      /// ===================================================

                      SizedBox(
                        width:
                            double.infinity,

                        height: 58,

                        child:
                            ElevatedButton.icon(
                          onPressed:
                              logout,

                          icon:
                              const Icon(
                            Icons
                                .logout_rounded,

                            color:
                                Colors.white,
                          ),

                          label:
                              const Text(
                            "Logout",

                            style:
                                TextStyle(
                              fontSize:
                                  16,

                              fontWeight:
                                  FontWeight
                                      .bold,

                              color:
                                  Colors.white,
                            ),
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            elevation:
                                0,

                            backgroundColor:
                                const Color(
                              0xff4A6CF7,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  /// =========================================================
  /// SETTINGS TILE
  /// =========================================================

  Widget _buildTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 16,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          24,
        ),

        onTap: onTap,

        child: Container(
          padding:
              const EdgeInsets.all(
            18,
          ),

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
                  0.04,
                ),

                blurRadius: 12,

                offset:
                    const Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),

          child: Row(
            children: [
              /// ICON

              Container(
                height: 58,
                width: 58,

                decoration:
                    BoxDecoration(
                  color:
                      color.withOpacity(
                    0.12,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: Icon(
                  icon,

                  color: color,

                  size: 28,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              /// TEXT

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      title,

                      style:
                          const TextStyle(
                        fontSize: 17,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            Colors.black87,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      subtitle,

                      style: TextStyle(
                        fontSize: 13,

                        color: Colors
                            .grey
                            .shade600,

                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              /// ARROW

              Container(
                padding:
                    const EdgeInsets.all(
                  8,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors
                      .grey
                      .shade100,

                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons
                      .arrow_forward_ios_rounded,

                  size: 15,

                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}