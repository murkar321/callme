import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "About Us",
          style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Header Card
            // ✅ Gradient header stays a brand-blue accent in both themes —
            // it's decorative, not a surface, so it doesn't need to flip.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF0D47A1), Color(0xFF1976D2)]
                      : const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.home_repair_service,
                      size: 40,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Callme All in One Service",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
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
              context: context,
              title: "About Callme",
              icon: Icons.info_outline,
              child: Text(
                "Callme All in One Service is a comprehensive digital marketplace designed to connect customers with trusted service providers through a single platform. Our goal is to make it easy, fast, and convenient for users to find and book professional services according to their needs.\n\n"
                "We offer access to multiple service categories including Laundry Services, Water Supply, Education Services, Home Cleaning, Plumbing, Electrical Services, Repair & Maintenance, and many more. Customers can submit service requirements, receive qualified leads, and connect directly with professionals through consultations, conference bookings, and appointment scheduling.\n\n"
                "We are committed to quality, reliability, transparency, and customer satisfaction while helping service providers grow their businesses.",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: cs.onSurface.withOpacity(0.85),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Features
            _buildCard(
              context: context,
              title: "Our Features",
              icon: Icons.star_outline,
              child: Column(
                children: const [
                  FeatureTile(icon: Icons.apps, title: "All-in-One Service Platform"),
                  FeatureTile(icon: Icons.leaderboard, title: "Lead Generation System"),
                  FeatureTile(icon: Icons.calendar_month, title: "Conference & Appointment Booking"),
                  FeatureTile(icon: Icons.send, title: "Easy Service Requests"),
                  FeatureTile(icon: Icons.verified_user, title: "Verified Service Providers"),
                  FeatureTile(icon: Icons.flash_on, title: "Fast Response Time"),
                  FeatureTile(icon: Icons.visibility, title: "Transparent Process"),
                  FeatureTile(icon: Icons.security, title: "Secure Platform"),
                  FeatureTile(icon: Icons.support_agent, title: "Customer Support"),
                  FeatureTile(icon: Icons.phone_android, title: "User-Friendly Experience"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Vision
            _buildCard(
              context: context,
              title: "Our Vision",
              icon: Icons.visibility_outlined,
              child: Text(
                "To become a leading all-in-one service platform that simplifies the way people discover, connect with, and book professional services. We aim to create a trusted digital ecosystem that benefits both customers and service providers.",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: cs.onSurface.withOpacity(0.85),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Mission
            _buildCard(
              context: context,
              title: "Our Mission",
              icon: Icons.flag_outlined,
              child: const Column(
                children: [
                  MissionTile(text: "Connect customers with reliable service providers."),
                  MissionTile(text: "Provide high-quality leads and booking solutions."),
                  MissionTile(text: "Simplify the service discovery and booking process."),
                  MissionTile(text: "Promote transparency, trust, and customer satisfaction."),
                  MissionTile(text: "Empower service providers with opportunities to grow."),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Why Choose Us
            _buildCard(
              context: context,
              title: "Why Choose Callme?",
              icon: Icons.thumb_up_alt_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "One Platform. Multiple Services. Trusted Professionals. Easy Booking.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Callme All in One Service is dedicated to delivering convenience, efficiency, and quality by bringing all your service needs together in one place. Whether you need home services, educational support, maintenance solutions, or other professional services, we help you find the right solution quickly and easily.",
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: cs.onSurface.withOpacity(0.85),
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
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "Application Version",
                    style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "v1.0.0",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: cs.onSurface,
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
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
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
              Icon(icon, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          Divider(height: 24, color: cs.outlineVariant),
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
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: cs.primary.withOpacity(0.12),
        child: Icon(icon, color: cs.primary),
      ),
      title: Text(
        title,
        style: TextStyle(color: cs.onSurface),
      ),
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(height: 1.5, color: cs.onSurface.withOpacity(0.85)),
            ),
          ),
        ],
      ),
    );
  }
}