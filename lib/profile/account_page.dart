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

  String userName     = 'CallMe User';
  String userPhone    = '';
  String userEmail    = '';
  String profileImage = '';
  bool   isLoading    = true;

  // =====================================================
  // TIME-BASED GREETING
  // =====================================================

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5  && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour >= 5  && hour < 12) return '☀️';
    if (hour >= 12 && hour < 17) return '👋';
    if (hour >= 17 && hour < 21) return '🌇';
    return '🌙';
  }

  // first name only for greeting (e.g. "Good Morning, Raj")
  String get _firstName {
    final name = userName.trim();
    if (name.isEmpty || name == 'CallMe User') return '';
    return name.split(' ').first;
  }

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // =====================================================
  // FETCH USER DATA  (doc ID = UID)
  // =====================================================

  Future<void> fetchUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc((user.email ?? '').trim().toLowerCase())
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = (data['name']?.toString() ?? '').isNotEmpty
              ? data['name'].toString()
              : (user.displayName ?? 'CallMe User');

          userPhone = (data['phone']?.toString() ?? '').isNotEmpty
              ? data['phone'].toString()
              : (user.phoneNumber ?? '');

          userEmail = (data['email']?.toString() ?? '').isNotEmpty
              ? data['email'].toString()
              : (user.email ?? '');

          profileImage = (data['photo']?.toString() ?? '').isNotEmpty
              ? data['photo'].toString()
              : (user.photoURL ?? '');

          isLoading = false;
        });
      } else {
        setState(() {
          userName     = user.displayName ?? 'CallMe User';
          userPhone    = user.phoneNumber ?? '';
          userEmail    = user.email       ?? '';
          profileImage = user.photoURL    ?? '';
          isLoading    = false;
        });
      }
    } catch (e) {
      debugPrint('FETCH USER ERROR: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // =====================================================
  // REFRESH
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text('You will be signed out of your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final double sp = sw / 390;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),

      appBar: AppBar(
        elevation:       0,
        centerTitle:     true,
        backgroundColor: const Color(0xFFF4F7FC),
        title: const Text(
          'My Account',
          style: TextStyle(
            color:      Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize:   22,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18, 12, 18, 24 + mq.viewPadding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── PROFILE CARD ─────────────────────
                    _buildProfileCard(sp),

                    const SizedBox(height: 32),

                    // ── SECTION TITLE ─────────────────────
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize:   20,
                        fontWeight: FontWeight.bold,
                        color:      Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── TILES ─────────────────────────────
                    _buildTile(
                      title:    'Profile',
                      subtitle: 'Manage personal details',
                      icon:     Icons.person_outline,
                      color:    Colors.blue,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfilePage(phone: userPhone),
                          ),
                        );
                        await refreshUserData();
                      },
                    ),

                    _buildTile(
                      title:    'About Us',
                      subtitle: 'Know more about CallMe',
                      icon:     Icons.info_outline,
                      color:    Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AboutPage()),
                      ),
                    ),

                    _buildTile(
                      title:    'Contact Us',
                      subtitle: 'Reach our support team',
                      icon:     Icons.support_agent,
                      color:    Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ContactUsPage()),
                      ),
                    ),

                    _buildTile(
                      title:    'Feedback',
                      subtitle: 'Share your experience',
                      icon:     Icons.feedback_outlined,
                      color:    Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FeedbackPage()),
                      ),
                    ),

                    _buildTile(
                      title:    'Privacy Policy',
                      subtitle: 'Read our policies',
                      icon:     Icons.privacy_tip_outlined,
                      color:    Colors.red,
                      onTap:    openPrivacyPolicy,
                    ),

                    const SizedBox(height: 28),

                    // ── LOGOUT ────────────────────────────
                    SizedBox(
                      width:  double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: logout,
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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

  // =====================================================
  // PROFILE CARD  with time-based greeting
  // =====================================================

  Widget _buildProfileCard(double sp) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6CF7), Color(0xFF6F8CFF)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:      Colors.blue.withOpacity(0.2),
            blurRadius: 24,
            offset:     const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [

          // ── AVATAR ──────────────────────────────────
          _buildAvatar(),

          const SizedBox(width: 18),

          // ── TEXT ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Greeting pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _greetingEmoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _greeting,
                        style: const TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize:   13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Name (first name only in large, rest smaller)
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: _firstName.isNotEmpty
                        ? [
                            TextSpan(
                              text: '$_firstName\n',
                              style: TextStyle(
                                color:      Colors.white,
                                fontSize:   22 * sp,
                                fontWeight: FontWeight.w800,
                                height:     1.2,
                              ),
                            ),
                            // last name / rest of name smaller
                            if (userName.trim().split(' ').length > 1)
                              TextSpan(
                                text: userName
                                    .trim()
                                    .split(' ')
                                    .skip(1)
                                    .join(' '),
                                style: TextStyle(
                                  color:      Colors.white70,
                                  fontSize:   14 * sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ]
                        : [
                            TextSpan(
                              text: userName,
                              style: TextStyle(
                                color:      Colors.white,
                                fontSize:   20 * sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                  ),
                ),

                const SizedBox(height: 10),

                // Phone
                if (userPhone.isNotEmpty)
                  _infoRow(Icons.phone_rounded, userPhone),

                if (userPhone.isNotEmpty && userEmail.isNotEmpty)
                  const SizedBox(height: 5),

                // Email
                if (userEmail.isNotEmpty)
                  _infoRow(Icons.email_rounded, userEmail),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // AVATAR
  // =====================================================

  Widget _buildAvatar() {
    return ClipOval(
      child: Container(
        width:  80,
        height: 80,
        color:  const Color(0xFFEEF2FF),
        child: profileImage.isNotEmpty
            ? Image.network(
                profileImage,
                width:  80,
                height: 80,
                fit:    BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4A6CF7),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _initialsAvatar(),
              )
            : _initialsAvatar(),
      ),
    );
  }

  Widget _initialsAvatar() {
    final initial = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize:   32,
          fontWeight: FontWeight.bold,
          color:      Color(0xFF4A6CF7),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap:        onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [

              Container(
                width:  52,
                height: 52,
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w700,
                        color:      Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color:    Colors.grey.shade500,
                        height:   1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size:  13,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}