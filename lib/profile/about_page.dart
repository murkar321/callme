import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          "About Us",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF42A5F5),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.home_repair_service,
                      size: 40,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Callme All in One Service",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "One Platform • Multiple Services • Trusted Professionals",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// About Section
            _buildCard(
              title: "About Callme",
              icon: Icons.info_outline,
              child: const Text(
                "Callme All in One Service is a comprehensive digital marketplace designed to connect customers with trusted service providers through a single platform. Our goal is to make it easy, fast, and convenient for users to find and book professional services according to their needs.\n\n"
                "We offer access to multiple service categories including Laundry Services, Water Supply, Education Services, Home Cleaning, Plumbing, Electrical Services, Repair & Maintenance, and many more. Customers can submit service requirements, receive qualified leads, and connect directly with professionals through consultations, conference bookings, and appointment scheduling.\n\n"
                "We are committed to quality, reliability, transparency, and customer satisfaction while helping service providers grow their businesses.",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Features
            _buildCard(
              title: "Our Features",
              icon: Icons.star_outline,
              child: Column(
                children: const [
                  FeatureTile(
                    icon: Icons.apps,
                    title: "All-in-One Service Platform",
                  ),
                  FeatureTile(
                    icon: Icons.leaderboard,
                    title: "Lead Generation System",
                  ),
                  FeatureTile(
                    icon: Icons.calendar_month,
                    title: "Conference & Appointment Booking",
                  ),
                  FeatureTile(
                    icon: Icons.send,
                    title: "Easy Service Requests",
                  ),
                  FeatureTile(
                    icon: Icons.verified_user,
                    title: "Verified Service Providers",
                  ),
                  FeatureTile(
                    icon: Icons.flash_on,
                    title: "Fast Response Time",
                  ),
                  FeatureTile(
                    icon: Icons.visibility,
                    title: "Transparent Process",
                  ),
                  FeatureTile(
                    icon: Icons.security,
                    title: "Secure Platform",
                  ),
                  FeatureTile(
                    icon: Icons.support_agent,
                    title: "Customer Support",
                  ),
                  FeatureTile(
                    icon: Icons.phone_android,
                    title: "User-Friendly Experience",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Vision
            _buildCard(
              title: "Our Vision",
              icon: Icons.visibility_outlined,
              child: const Text(
                "To become a leading all-in-one service platform that simplifies the way people discover, connect with, and book professional services. We aim to create a trusted digital ecosystem that benefits both customers and service providers.",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Mission
            _buildCard(
              title: "Our Mission",
              icon: Icons.flag_outlined,
              child: const Column(
                children: [
                  MissionTile(
                    text:
                        "Connect customers with reliable service providers.",
                  ),
                  MissionTile(
                    text:
                        "Provide high-quality leads and booking solutions.",
                  ),
                  MissionTile(
                    text:
                        "Simplify the service discovery and booking process.",
                  ),
                  MissionTile(
                    text:
                        "Promote transparency, trust, and customer satisfaction.",
                  ),
                  MissionTile(
                    text:
                        "Empower service providers with opportunities to grow.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Why Choose Us
            _buildCard(
              title: "Why Choose Callme?",
              icon: Icons.thumb_up_alt_outlined,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "One Platform. Multiple Services. Trusted Professionals. Easy Booking.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Callme All in One Service is dedicated to delivering convenience, efficiency, and quality by bringing all your service needs together in one place. Whether you need home services, educational support, maintenance solutions, or other professional services, we help you find the right solution quickly and easily.",
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Version
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    "Application Version",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "v1.0.0",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Color(0xFFE3F2FD),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title),
    );
  }
}

class MissionTile extends StatelessWidget {
  final String text;

  const MissionTile({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}