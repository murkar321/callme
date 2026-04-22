import 'package:callme/Admin/admin_dashboard.dart';
import 'package:callme/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:callme/provider/provider_dashboard.dart';


class RoleSelectionPage extends StatelessWidget {
  final bool isProvider;
  final bool isAdmin;

  const RoleSelectionPage({
    super.key,
    required this.isProvider,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Select Role"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// USER CARD
            _buildRoleCard(
              context,
              title: "User",
              subtitle: "Browse and book services",
              icon: Icons.person,
              color: Colors.blue,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            /// PROVIDER CARD
            if (isProvider)
              _buildRoleCard(
                context,
                title: "Provider",
                subtitle: "Manage your services & business",
                icon: Icons.business_center,
                color: Colors.green,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BusinessDashboardPage(businessName: '', categoryRoute: '',),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            /// ADMIN CARD
            if (isAdmin)
              _buildRoleCard(
                context,
                title: "Admin",
                subtitle: "Full control & analytics",
                icon: Icons.admin_panel_settings,
                color: Colors.red,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminDashboard(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}