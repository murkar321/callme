import 'package:callme/models/service_product.dart';
import 'package:callme/screens/about_page.dart';
import 'package:callme/screens/booking_page.dart';
import 'package:callme/screens/contactus_page.dart';
import 'package:callme/screens/home_page.dart';
import 'package:callme/screens/myorders_page.dart';
import 'package:callme/screens/profile_page.dart';
import 'package:callme/models/service_products.dart';
import 'package:flutter/material.dart';
import 'package:callme/screens/ProductDetailPage.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            accountName: const Text(
              'Dhanaya Indap',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: const Text('example@email.com'),
          ),

          // Menu Items
          _drawerItem(
            context,
            icon: Icons.person,
            title: 'Home',
            page: HomePage(),
          ),
          _drawerItem(
            context,
            icon: Icons.person,
            title: 'My Profile',
            page: const ProfilePage(),
          ),
          _drawerItem(
            context,
            icon: Icons.shopping_bag,
            title: 'My Orders',
            page: const MyOrdersPage(),
          ),
          _drawerItem(
            context,
            icon: Icons.calendar_today,
            title: 'Book Service',
           page: BookingPage(
  serviceName: 'General Service',
  product: ServiceProduct(
    name: 'General Service',
    price: 568,
    imagePath: 'assets/default_service.jpg',
  ),
),

          ),
          _drawerItem(
            context,
            icon: Icons.info_outline,
            title: 'About Us',
            page: const AboutPage(),
          ),
          _drawerItem(
            context,
            icon: Icons.contact_support,
            title: 'Contact Us',
            page: const ContactUsPage(),
          ),

          const Spacer(),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}
