import 'package:flutter/material.dart';

class BusinessDashboardPage extends StatelessWidget {
  final String businessName;

  const BusinessDashboardPage({
    super.key,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.blue.shade50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, $businessName 👋",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Manage your business, bookings, staff, and earnings from one place.",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Bookings",
                    "24",
                    Icons.book_online,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Earnings",
                    "₹4,500",
                    Icons.currency_rupee,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Staff",
                    "5",
                    Icons.groups,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Rating",
                    "4.8 ⭐",
                    Icons.star,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  context,
                  "Add Services",
                  Icons.design_services,
                ),
                _buildActionCard(
                  context,
                  "Manage Staff",
                  Icons.groups_2,
                ),
                _buildActionCard(
                  context,
                  "Bookings",
                  Icons.calendar_month,
                ),
                _buildActionCard(
                  context,
                  "Payments",
                  Icons.account_balance_wallet,
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Recent Bookings",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _buildBookingCard(
              customer: "Priya Sharma",
              service: "Deep Cleaning",
              date: "Today, 4:00 PM",
              status: "Pending",
            ),

            _buildBookingCard(
              customer: "Rahul Patil",
              service: "Home Cleaning",
              date: "Tomorrow, 10:00 AM",
              status: "Confirmed",
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required String customer,
    required String service,
    required String date,
    required String status,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(customer),
        subtitle: Text("$service\n$date"),
        trailing: Chip(
          label: Text(status),
        ),
      ),
    );
  }
}