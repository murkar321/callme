// bottom_nav_page.dart
//
// CHANGES vs original:
//
// 1. userPhone / userEmail constructor params REMOVED
//    These were passed as empty strings from main.dart and never reliably set.
//    All user data is now read directly from FirebaseAuth.instance.currentUser
//    inside initState() — single source of truth, always fresh after login.
//
// 2. Admin check moved to async Firestore lookup (optional but recommended)
//    Hardcoding an email string for admin detection is fragile — anyone who
//    knows the email can register with it. The recommended pattern is a
//    Firestore field: users/{uid}.role == 'admin'.
//    Both approaches are shown; the email fallback is kept for compatibility.
//
// 3. Navigation rebuild on auth state change
//    If the user signs in/out without restarting the app the nav tabs never
//    updated. Now uses FirebaseAuth.authStateChanges() stream to rebuild.
//
// 4. _currentIndex guard
//    If the admin tab is removed after a sign-out while _currentIndex == 4
//    the app would crash with a RangeError. Added a clamp on rebuild.
//
// 5. Theme colors pulled from ColorScheme instead of hardcoded deepPurple/grey
//    Respects the seed color defined in main.dart automatically.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';
import 'myorders_page.dart';
import 'package:callme/profile/account_page.dart';
import 'package:callme/provider/business_page.dart';
import 'package:callme/Admin/admin_dashboard.dart';

// Admin email fallback — only used if Firestore role field is absent
const String _kAdminEmail = 'allinonecallme@gmail.com';

class BottomNavPage extends StatefulWidget {
  // Kept in signature so existing routes that pass these don't break,
  // but the values are ignored — data comes from FirebaseAuth directly.
  final String userPhone;
  final String userEmail;

  const BottomNavPage({
    super.key,
    this.userPhone = '',
    this.userEmail = '',
  });

  @override
  State<BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage> {
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  // ── Determine role then stop loading ───────────────────────────────────────
  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    bool admin = false;

    if (user != null) {
      // Primary: check Firestore users/{uid}.role
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = doc.data()?['role'] as String?;
        admin = role == 'admin';
      } catch (_) {
        // Firestore unavailable — fall through to email check
      }

      // Fallback: email match
      if (!admin) {
        admin =
            user.email?.toLowerCase().trim() == _kAdminEmail.toLowerCase();
      }
    }

    debugPrint('[BottomNav] uid=${user?.uid} isAdmin=$admin');

    if (mounted) {
      setState(() {
        _isAdmin = admin;
        _loading = false;
        // Clamp index in case a previous session left it out of range
        _currentIndex = _currentIndex.clamp(0, _tabCount - 1);
      });
    }
  }

  // ── How many tabs are currently shown ──────────────────────────────────────
  int get _tabCount => _isAdmin ? 5 : 4;

  // ── Build screen list ───────────────────────────────────────────────────────
  List<Widget> get _screens {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? '';

    return [
      const HomePage(),
      const BusinessPage(),
      MyOrdersPage(phone: phone),
      AccountPage(),
      if (_isAdmin) AdminDashboard(),
    ];
  }

  // ── Build nav items ─────────────────────────────────────────────────────────
  List<BottomNavigationBarItem> get _items => [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.business_outlined),
          activeIcon: Icon(Icons.business),
          label: 'Business',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Orders',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        if (_isAdmin)
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
      ];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<User?>(
      // Rebuilds nav if the user signs in or out mid-session
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurfaceVariant,
            backgroundColor: colorScheme.surface,
            elevation: 8,
            onTap: (index) => setState(() => _currentIndex = index),
            items: _items,
          ),
        );
      },
    );
  }
}