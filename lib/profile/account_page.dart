import 'dart:ui';
import 'dart:math' as math;

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

class _AccountPageState extends State<AccountPage>
    with TickerProviderStateMixin {
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
  bool   isRefreshing = false;

  // =====================================================
  // ANIMATION CONTROLLERS
  // =====================================================

  late final AnimationController _entranceController;
  late final AnimationController _avatarRingController;
  late final AnimationController _bgController;
  late final AnimationController _blobController1;
  late final AnimationController _blobController2;
  late final AnimationController _blobController3;

  // Pastel palette for the header
  static const List<Color> _pastelPalette = [
    Color(0xFFFFD6E8), // blush pink
    Color(0xFFD6E4FF), // periwinkle
    Color(0xFFFFF0C2), // soft butter
    Color(0xFFD3F5E4), // mint
    Color(0xFFE7D9FF), // lavender
  ];

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  // Precomputed staggered tile animations — built once instead of on
  // every build() call (avoids creating fresh CurvedAnimation/Tween
  // objects each frame).
  static const int _tileCount = 5;
  final List<Animation<double>> _tileFades = [];
  final List<Animation<Offset>> _tileSlides = [];
  late final Animation<double> _logoutFade;
  late final Animation<double> _logoutScale;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1100),
    );

    _avatarRingController = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _bgController = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _blobController1 = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);

    _blobController2 = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _blobController3 = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve:  const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end:   Offset.zero,
    ).animate(_cardFade);

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve:  const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end:   Offset.zero,
    ).animate(_titleFade);

    for (int i = 0; i < _tileCount; i++) {
      final start = (0.45 + i * 0.09).clamp(0.0, 0.9);
      final end   = (start + 0.35).clamp(0.0, 1.0);
      final fade = CurvedAnimation(
        parent: _entranceController,
        curve:  Interval(start, end, curve: Curves.easeOut),
      );
      _tileFades.add(fade);
      _tileSlides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.25),
          end:   Offset.zero,
        ).animate(fade),
      );
    }

    _logoutFade = CurvedAnimation(
      parent: _entranceController,
      curve:  const Interval(0.75, 1.0, curve: Curves.easeOut),
    );
    _logoutScale = Tween<double>(begin: 0.96, end: 1.0).animate(_logoutFade);

    // Entrance animation starts immediately — it should not wait on the
    // network fetch, otherwise a slow connection stalls the whole page.
    _entranceController.forward();

    fetchUserData();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _avatarRingController.dispose();
    _bgController.dispose();
    _blobController1.dispose();
    _blobController2.dispose();
    _blobController3.dispose();
    super.dispose();
  }

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
  // FETCH USER DATA  (users collection is keyed by email)
  // =====================================================

  Future<void> fetchUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading    = false;
            isRefreshing = false;
          });
        }
        return;
      }

      final email = (user.email ?? '').trim().toLowerCase();

      if (email.isEmpty) {
        if (mounted) {
          setState(() {
            userName     = user.displayName ?? 'CallMe User';
            userPhone    = user.phoneNumber ?? '';
            userEmail    = '';
            profileImage = user.photoURL ?? '';
            isLoading    = false;
            isRefreshing = false;
          });
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
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

          isLoading    = false;
          isRefreshing = false;
        });
      } else {
        setState(() {
          userName     = user.displayName ?? 'CallMe User';
          userPhone    = user.phoneNumber ?? '';
          userEmail    = user.email       ?? '';
          profileImage = user.photoURL    ?? '';
          isLoading    = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('FETCH USER ERROR: $e');
      if (mounted) {
        setState(() {
          isLoading    = false;
          isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not load your profile. Pull to retry.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // =====================================================
  // REFRESH
  // =====================================================
  // NOTE: pull-to-refresh should keep existing content on screen and let
  // RefreshIndicator's own spinner communicate loading state — swapping
  // the whole page to the skeleton loader (as the original did) defeats
  // the purpose of pull-to-refresh and causes a jarring flash.

  Future<void> refreshUserData() async {
    if (!mounted) return;
    setState(() => isRefreshing = true);
    await fetchUserData();
  }

  // =====================================================
  // PRIVACY POLICY
  // =====================================================

  Future<void> openPrivacyPolicy() async {
    final Uri url = Uri.parse('https://callmeallinoneservices.com/');
    try {
      final launched =
          await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showError('Could not open the Privacy Policy page.');
      }
    } catch (e) {
      debugPrint('PRIVACY POLICY LAUNCH ERROR: $e');
      if (mounted) _showError('Could not open the Privacy Policy page.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

    if (confirm != true || !mounted) return;

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

    // Adaptive scale factor clamped so very small or very large real
    // devices (and split-screen / tablets) don't get illegibly tiny or
    // comically oversized text.
    final double sp = (sw / 390).clamp(0.85, 1.25);

    // Clamp the system text scale so a user's Android accessibility
    // "large text" setting can't blow up the fixed-height header card
    // or push the tiles off-screen.
    final clampedTextScaler =
        mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);

    // Real Android devices vary widely in gesture-nav / 3-button-nav
    // bottom insets — always add viewPadding.bottom instead of a fixed
    // number so content never sits under the system nav bar.
    final double bottomSafePad = mq.viewPadding.bottom;

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedTextScaler),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation:       0,
          centerTitle:     true,
          backgroundColor: Colors.transparent,
          title: Text(
            'My Account',
            style: TextStyle(
              color:      const Color(0xFF2D2A45),
              fontWeight: FontWeight.bold,
              fontSize:   22 * sp,
            ),
          ),
        ),
        body: isLoading
            ? _buildLoadingSkeleton(sp, bottomSafePad)
            : RefreshIndicator(
                color: const Color(0xFFB79CE0),
                onRefresh: refreshUserData,
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      18, 0, 18, 24 + bottomSafePad,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        SizedBox(height: mq.padding.top + kToolbarHeight - 18),

                        // ── PROFILE CARD ─────────────────────
                        FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: _buildProfileCard(sp),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── SECTION TITLE ─────────────────────
                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Row(
                              children: [
                                Container(
                                  width:  4,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB79CE0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Account Settings',
                                  style: TextStyle(
                                    fontSize:   20 * sp,
                                    fontWeight: FontWeight.bold,
                                    color:      Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── TILES (staggered) ─────────────────
                        _buildStaggeredTile(
                          index:    0,
                          sp:       sp,
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

                        _buildStaggeredTile(
                          index:    1,
                          sp:       sp,
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

                        _buildStaggeredTile(
                          index:    2,
                          sp:       sp,
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

                        _buildStaggeredTile(
                          index:    3,
                          sp:       sp,
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

                        _buildStaggeredTile(
                          index:    4,
                          sp:       sp,
                          title:    'Privacy Policy',
                          subtitle: 'Read our policies',
                          icon:     Icons.privacy_tip_outlined,
                          color:    Colors.red,
                          onTap:    openPrivacyPolicy,
                        ),

                        const SizedBox(height: 28),

                        // ── LOGOUT ────────────────────────────
                        FadeTransition(
                          opacity: _logoutFade,
                          child: ScaleTransition(
                            scale: _logoutScale,
                            child: SizedBox(
                              width:  double.infinity,
                              height: 54,
                              child: OutlinedButton.icon(
                                onPressed: logout,
                                icon: const Icon(Icons.logout_rounded, size: 18),
                                label: Text(
                                  'Log Out',
                                  style: TextStyle(
                                    fontSize:   15 * sp,
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

  // =====================================================
  // LOADING SKELETON (shimmer-style)
  // =====================================================

  Widget _buildLoadingSkeleton(double sp, double bottomSafePad) {
    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, topPad - 6, 18, 24 + bottomSafePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(height: 150 * sp, borderRadius: 28),
            const SizedBox(height: 32),
            _ShimmerBox(height: 22 * sp, width: 160 * sp, borderRadius: 8),
            const SizedBox(height: 18),
            ...List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ShimmerBox(height: 84 * sp, borderRadius: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // STAGGERED WRAPPER FOR TILES
  // =====================================================

  Widget _buildStaggeredTile({
    required int index,
    required double sp,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: _tileFades[index],
      child: SlideTransition(
        position: _tileSlides[index],
        child: _AnimatedTile(
          sp:       sp,
          title:    title,
          subtitle: subtitle,
          icon:     icon,
          color:    color,
          onTap:    onTap,
        ),
      ),
    );
  }

  // =====================================================
  // PROFILE CARD  with time-based greeting
  // =====================================================

  Widget _buildProfileCard(double sp) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        [_bgController, _blobController1, _blobController2, _blobController3],
      ),
      builder: (context, child) {
        final t = _bgController.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width:   double.infinity,
            padding: EdgeInsets.all(22 * sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(_pastelPalette[0], _pastelPalette[4], t)!,
                  Color.lerp(_pastelPalette[1], _pastelPalette[2], t)!,
                  Color.lerp(_pastelPalette[3], _pastelPalette[1], t)!,
                ],
                begin: Alignment(-1 + t * 0.3, -1),
                end:   Alignment(1, 1 - t * 0.3),
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color:      const Color(0xFFB9A6E0).withOpacity(0.28),
                  blurRadius: 26,
                  offset:     const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── floating pastel blobs (soft, blurred, drifting) ──
                _floatingBlob(
                  controller: _blobController1,
                  color: const Color(0xFFFFFFFF).withOpacity(0.35),
                  size:  120,
                  basePosition: const Offset(-24, -34),
                  amplitude: const Offset(10, 14),
                ),
                _floatingBlob(
                  controller: _blobController2,
                  color: const Color(0xFFFFE3F1).withOpacity(0.45),
                  size:  90,
                  basePosition: const Offset(250, 60),
                  amplitude: const Offset(-12, 10),
                ),
                _floatingBlob(
                  controller: _blobController3,
                  color: const Color(0xFFE0F3FF).withOpacity(0.4),
                  size:  70,
                  basePosition: const Offset(200, -40),
                  amplitude: const Offset(8, -12),
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // ── AVATAR ──────────────────────────────────
                    _buildAvatar(sp),

                    SizedBox(width: 18 * sp),

                    // ── TEXT ────────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // Greeting pill — frosted glass. FittedBox
                          // guards against the pill overflowing when
                          // Android system font scaling is high.
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12 * sp, vertical: 5 * sp),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _greetingEmoji,
                                        style: TextStyle(fontSize: 13 * sp),
                                      ),
                                      SizedBox(width: 6 * sp),
                                      Text(
                                        _greeting,
                                        style: TextStyle(
                                          color:      const Color(0xFF3A3660),
                                          fontWeight: FontWeight.w700,
                                          fontSize:   13 * sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 12 * sp),

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
                                          color: const Color(0xFF2D2A45),
                                          fontSize:   22 * sp,
                                          fontWeight: FontWeight.w800,
                                          height:     1.2,
                                        ),
                                      ),
                                      // last name / rest of name smaller
                                      if (userName.trim().split(' ').length >
                                          1)
                                        TextSpan(
                                          text: userName
                                              .trim()
                                              .split(' ')
                                              .skip(1)
                                              .join(' '),
                                          style: TextStyle(
                                            color: const Color(0xFF5C5780),
                                            fontSize:   14 * sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ]
                                  : [
                                      TextSpan(
                                        text: userName,
                                        style: TextStyle(
                                          color: const Color(0xFF2D2A45),
                                          fontSize:   20 * sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                            ),
                          ),

                          SizedBox(height: 10 * sp),

                          // Phone
                          if (userPhone.isNotEmpty)
                            _infoRow(Icons.phone_rounded, userPhone, sp),

                          if (userPhone.isNotEmpty && userEmail.isNotEmpty)
                            SizedBox(height: 5 * sp),

                          // Email
                          if (userEmail.isNotEmpty)
                            _infoRow(Icons.email_rounded, userEmail, sp),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // A soft, blurred pastel circle that drifts gently in a loop
  Widget _floatingBlob({
    required AnimationController controller,
    required Color color,
    required double size,
    required Offset basePosition,
    required Offset amplitude,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final wave = math.sin(controller.value * 2 * math.pi);
        return Positioned(
          left: basePosition.dx + amplitude.dx * wave,
          top:  basePosition.dy + amplitude.dy * wave,
          child: child!,
        );
      },
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width:  size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, double sp) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B6690), size: 14 * sp),
        SizedBox(width: 6 * sp),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:      const Color(0xFF4B4770),
              fontSize:   12 * sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // AVATAR  (with animated rotating ring)
  // =====================================================

  Widget _buildAvatar(double sp) {
    final double outer = 92 * sp;
    final double inner = 80 * sp;
    return SizedBox(
      width:  outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // rotating pastel sweep ring
          RotationTransition(
            turns: _avatarRingController,
            child: Container(
              width:  outer,
              height: outer,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    const Color(0xFFFFD6E8),
                    const Color(0xFFD6E4FF),
                    const Color(0xFFFFF0C2),
                    Colors.white.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
                ),
              ),
            ),
          ),
          ClipOval(
            child: Container(
              width:  inner,
              height: inner,
              color:  Colors.white,
              child: profileImage.isNotEmpty
                  ? Image.network(
                      profileImage,
                      width:  inner,
                      height: inner,
                      fit:    BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFB79CE0),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _initialsAvatar(sp),
                    )
                  : _initialsAvatar(sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(double sp) {
    final initial = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'U';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize:   32 * sp,
          fontWeight: FontWeight.bold,
          color:      const Color(0xFFB79CE0),
        ),
      ),
    );
  }
}

// =====================================================
// ANIMATED SETTINGS TILE
// (scale + shadow feedback on press, arrow slide on tap)
// =====================================================

class _AnimatedTile extends StatefulWidget {
  final double sp;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedTile({
    required this.sp,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final sp = widget.sp;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp:   (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(16 * sp),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_pressed ? 0.02 : 0.05),
                  blurRadius: _pressed ? 6 : 14,
                  offset:     Offset(0, _pressed ? 2 : 5),
                ),
              ],
            ),
            child: Row(
              children: [

                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width:  52 * sp,
                  height: 52 * sp,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(_pressed ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 24 * sp),
                ),

                SizedBox(width: 16 * sp),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:   15 * sp,
                          fontWeight: FontWeight.w700,
                          color:      const Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 3 * sp),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5 * sp,
                          color:    Colors.grey.shade500,
                          height:   1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8 * sp),

                AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  offset: _pressed ? const Offset(0.15, 0) : Offset.zero,
                  child: Container(
                    padding: EdgeInsets.all(7 * sp),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size:  13 * sp,
                      color: Colors.black45,
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

// =====================================================
// SHIMMER LOADING BOX
// =====================================================

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const _ShimmerBox({
    required this.height,
    this.width,
    this.borderRadius = 12,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            final dx = _controller.value * 2 - 1;
            return LinearGradient(
              colors: [
                const Color(0xFFE9EDF5),
                const Color(0xFFF7F9FC),
                const Color(0xFFE9EDF5),
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(-1 + dx, 0),
              end:   Alignment(1 + dx, 0),
            ).createShader(rect);
          },
          child: Container(
            width:  widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDF5),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}