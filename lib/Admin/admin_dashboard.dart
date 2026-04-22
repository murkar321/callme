import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// STATS CARDS
            Row(
              children: [
                _buildStatCard("Users", "120", Colors.blue),
                const SizedBox(width: 10),
                _buildStatCard("Providers", "45", Colors.green),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                _buildStatCard("Bookings", "230", Colors.orange),
                const SizedBox(width: 10),
                _buildStatCard("Revenue", "₹50K", Colors.purple),
              ],
            ),

            const SizedBox(height: 30),

            /// MANAGEMENT GRID
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                _buildGridItem(
                  icon: Icons.people,
                  title: "Manage Users",
                  color: Colors.blue,
                ),

                _buildGridItem(
                  icon: Icons.business,
                  title: "Providers",
                  color: Colors.green,
                ),

                _buildGridItem(
                  icon: Icons.miscellaneous_services,
                  title: "Services",
                  color: Colors.orange,
                ),

                _buildGridItem(
                  icon: Icons.book_online,
                  title: "Bookings",
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to respective pages
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}