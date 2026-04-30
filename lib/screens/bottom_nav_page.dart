import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'myorders_page.dart';
import 'profile_page.dart';
import 'package:callme/provider/business_page.dart';
import 'package:callme/Admin/admin_dashboard.dart';

class BottomNavPage extends StatefulWidget {
  final String userPhone;
  final String userEmail;

  const BottomNavPage({
    super.key,
    required this.userPhone,
    required this.userEmail,
  });

  @override
  State<BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage> {
  int _currentIndex = 0;

  bool isAdmin = false;
  bool isGuest = false;

  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _items;

  @override
  void initState() {
    super.initState();
    _initUserRole();
  }

  /// 🔥 INIT ROLE (REALTIME SAFE)
  void _initUserRole() {
    final user = FirebaseAuth.instance.currentUser;

    isGuest = user == null;

    /// ✅ ADMIN CHECK (SAFE)
    isAdmin = (user?.email ?? "")
            .toLowerCase()
            .trim() ==
        "allinonecallme@gmail.com";

    debugPrint("User Email: ${user?.email}");
    debugPrint("Is Admin: $isAdmin");

    _buildNav();
  }

  /// 🔥 BUILD NAV (NO CONST LIST)
  void _buildNav() {

    _screens = [
      const HomePage(),
      BusinessPage(),
      MyOrdersPage(phone: widget.userPhone),
      ProfilePage(phone: widget.userPhone),
    ];

    _items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: "Home",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.business),
        label: "Business",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag),
        label: "Orders",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: "Profile",
      ),
    ];

    /// 👑 ADMIN ACCESS
    if (isAdmin) {
      _screens.add(AdminDashboard());
      _items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: "Admin",
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    /// ⏳ LOADING SAFE
    if (_screens.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,

        onTap: (index) {
          setState(() => _currentIndex = index);
        },

        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,

        items: _items,
      ),
    );
  }
}