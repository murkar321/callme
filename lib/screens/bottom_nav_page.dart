import 'package:callme/profile/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';
import 'myorders_page.dart';
import 'package:callme/profile/account_page.dart';
import 'package:callme/profile/notification_router.dart';
import 'package:callme/provider/business_page.dart';
import 'package:callme/Admin/admin_dashboard.dart';

const String _kAdminEmail = 'allinonecallme@gmail.com';

class BottomNavPage extends StatefulWidget {
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

  // Screens are built exactly ONCE after the role check and never rebuilt.
  // Rebuilding them would create new widget instances with new keys each time,
  // which is the primary cause of "Duplicate GlobalKeys" crashes.
  late final List<Widget> _screens;

  // Guard so _checkRole can never run twice (e.g. hot-restart edge cases).
  bool _roleChecked = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    if (_roleChecked) return;
    _roleChecked = true;

    final user = FirebaseAuth.instance.currentUser;
    bool admin = false;

    if (user != null) {
      // 1. Check Firestore role field first.
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = doc.data()?['role'] as String?;
        admin = role == 'admin';
      } catch (e) {
        debugPrint('[BottomNav] Firestore role check failed: $e');
      }

      // 2. Fallback: check email.
      if (!admin) {
        admin =
            user.email?.toLowerCase().trim() == _kAdminEmail.toLowerCase();
      }
    }

    debugPrint('[BottomNav] uid=${user?.uid}  isAdmin=$admin');

    // Build the screen list ONCE, before setState, so no screen is ever
    // recreated. All screens are held in a `late final` field.
    final phone = user?.phoneNumber ?? widget.userPhone;

    _screens = [
      const HomePage(),
      const BusinessPage(),
      MyOrdersPage(phone: phone),
      const AccountPage(),
      if (admin) const AdminDashboard(),
    ];

    // Guard against the widget being disposed while the async gap was open.
    if (!mounted) return;

    setState(() {
      _isAdmin = admin;
      _loading = false;
      // Clamp in case index is out-of-range after admin tab appears/disappears.
      _currentIndex = _currentIndex.clamp(0, _screens.length - 1);
    });
  }

  List<BottomNavigationBarItem> get _navItems => [
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

  /// Returns true when the currently visible tab is the Admin dashboard.
  bool get _isAdminTabActive =>
      _isAdmin && _currentIndex == _screens.length - 1;

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationPage(onNotificationTap: routeNotification),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a plain loader while the role check is in flight.
    // This Scaffold has no key so it cannot conflict with anything.
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      // IndexedStack keeps every tab alive (preserves scroll / state) without
      // recreating widgets when switching tabs — critical for avoiding
      // deactivated-ancestor errors.
      //
      // Wrapped in a Stack so a notification bell can float above every
      // tab without needing to touch each tab's own AppBar/layout — none
      // of the individual screens (HomePage, BusinessPage, etc.) need to
      // change for this to work.
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Hide the floating bell on the Admin tab — AdminDashboard
          // already has its own notification UI built in.
          if (uid != null && !_isAdminTabActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: _NotificationBell(
                uid: uid,
                onTap: _openNotifications,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        elevation: 8,
        onTap: (index) {
          if (index != _currentIndex) {
            setState(() => _currentIndex = index);
          }
        },
        items: _navItems,
      ),
    );
  }
}

/// Floating bell icon showing a live unread-notification count.
/// Sits above whichever tab is currently visible (except Admin).
class _NotificationBell extends StatelessWidget {
  final String uid;
  final VoidCallback onTap;

  const _NotificationBell({
    required this.uid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unreadStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: StreamBuilder<int>(
        stream: unreadStream,
        builder: (context, snapshot) {
          final unread = snapshot.data ?? 0;
          return IconButton(
            tooltip: 'Notifications',
            onPressed: onTap,
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          );
        },
      ),
    );
  }
}