import 'package:callme/Admin/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'myorders_page.dart';
import 'profile_page.dart';
import 'package:callme/provider/business_page.dart';


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

  late final bool isAdmin;
  late final List<Widget> _screens;
  late final List<BottomNavigationBarItem> _items;

  @override
  void initState() {
    super.initState();

    /// 🔥 ADMIN CHECK
    isAdmin = widget.userEmail == "allinonecallme@gmail.com";

    /// ✅ SCREENS
    _screens = [
      const HomePage(),
      BusinessPage(),
      MyOrdersPage(phone: widget.userPhone),
      ProfilePage(phone: widget.userPhone),

      /// 👑 ADMIN EXTRA SCREEN
      if (isAdmin) AdminDashboard(),
    ];

    /// ✅ NAV ITEMS
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

      /// 👑 ADMIN TAB
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: "Admin",
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: _items,
      ),
    );
  }
}