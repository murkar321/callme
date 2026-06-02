import 'package:callme/profile/about_page.dart';
import 'package:callme/profile/contactus_page.dart';
import 'package:callme/profile/feedback_page.dart';
import 'package:callme/profile/profile_page.dart';
import 'package:callme/screens/logo_page.dart';
import 'package:callme/login/auth_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // =====================================================
  // SERVICES
  // =====================================================

  final AuthService _authService = AuthService();

  // =====================================================
  // STATE
  // =====================================================

  String userName     = "CallMe User";
  String userPhone    = "";
  String userEmail    = "";
  String profileImage = "";
  bool   isLoading    = true;

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // =====================================================
  // FETCH USER DATA
  // Reads from "users" collection keyed by email.
  // Falls back to Firebase Auth fields if doc missing.
  // =====================================================

  Future<void> fetchUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final email = (user.email ?? "").trim().toLowerCase();

      if (email.isEmpty) {
        if (mounted) {
          setState(() {
            userName     = user.displayName ?? "CallMe User";
            userPhone    = user.phoneNumber ?? "";
            userEmail    = user.email       ?? "";
            profileImage = user.photoURL    ?? "";
            isLoading    = false;
          });
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(email)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName     = (data["name"]?.toString()  ?? "").isNotEmpty
              ? data["name"].toString()
              : (user.displayName ?? "CallMe User");

          userPhone    = (data["phone"]?.toString() ?? "").isNotEmpty
              ? data["phone"].toString()
              : (user.phoneNumber ?? "");

          userEmail    = (data["email"]?.toString() ?? "").isNotEmpty
              ? data["email"].toString()
              : (user.email ?? "");

          profileImage = (data["photo"]?.toString() ?? "").isNotEmpty
              ? data["photo"].toString()
              : (user.photoURL ?? "");

          isLoading = false;
        });
      } else {
        setState(() {
          userName     = user.displayName ?? "CallMe User";
          userPhone    = user.phoneNumber ?? "";
          userEmail    = user.email       ?? "";
          profileImage = user.photoURL    ?? "";
          isLoading    = false;
        });
      }
    } catch (e) {
      debugPrint("FETCH USER ERROR: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =====================================================
  // REFRESH — called when returning from ProfilePage
  // =====================================================

  Future<void> refreshUserData() async {
    if (mounted) setState(() => isLoading = true);
    await fetchUserData();
  }

  // =====================================================
  // PRIVACY POLICY
  // =====================================================

  Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://callmeallinoneservices.com/');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LogoPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FC),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xffF4F7FC),
        title: const Text(
          "My Account",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [

                    // ── PROFILE CARD ─────────────────────

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xff4A6CF7), Color(0xff6F8CFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.18),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [

                          // ── AVATAR ──────────────────────
                          _buildAvatar(),

                          const SizedBox(width: 18),

                          // ── USER INFO ───────────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    "Welcome Back 👋",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                if (userPhone.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded,
                                          color: Colors.white70, size: 15),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          userPhone,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                if (userEmail.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.email_rounded,
                                          color: Colors.white70, size: 15),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          userEmail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── SECTION TITLE ─────────────────────

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Account Settings",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── TILES ─────────────────────────────

                    _buildTile(
                      title: "Profile",
                      subtitle: "Manage personal details",
                      icon: Icons.person_outline,
                      color: Colors.blue,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(phone: userPhone),
                          ),
                        );
                        await refreshUserData();
                      },
                    ),

                    _buildTile(
                      title: "About Us",
                      subtitle: "Know more about CallMe",
                      icon: Icons.info_outline,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      ),
                    ),

                    _buildTile(
                      title: "Contact Us",
                      subtitle: "Reach our support team",
                      icon: Icons.support_agent,
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ContactUsPage()),
                      ),
                    ),

                    _buildTile(
                      title: "Feedback",
                      subtitle: "Share your experience",
                      icon: Icons.feedback_outlined,
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackPage()),
                      ),
                    ),

                    _buildTile(
                      title: "Privacy Policy",
                      subtitle: "Read our policies",
                      icon: Icons.privacy_tip_outlined,
                      color: Colors.red,
                      onTap: openPrivacyPolicy,
                    ),

                    const SizedBox(height: 30),

                    // ── LOGOUT ────────────────────────────

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white),
                        label: const Text(
                          "Logout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xff4A6CF7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // =====================================================
  // AVATAR BUILDER
  // Properly clipped CircleAvatar — handles network
  // image with loading/error states, falls back to
  // initials when no photo is set.
  // =====================================================

  Widget _buildAvatar() {
    return ClipOval(
      child: Container(
        width: 84,
        height: 84,
        color: const Color(0xFFEEF2FF),
        child: profileImage.isNotEmpty
            ? Image.network(
                profileImage,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff4A6CF7),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialsAvatar();
                },
              )
            : _buildInitialsAvatar(),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final String initial =
        userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : "U";

    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: Color(0xff4A6CF7),
        ),
      ),
    );
  }

  // =====================================================
  // SETTINGS TILE
  // =====================================================

  Widget _buildTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [

              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 26),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
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