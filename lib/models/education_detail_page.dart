import 'package:flutter/material.dart';
import '../data/education_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';

class EducationDetailPage extends StatelessWidget {
  final EducationService service;

  const EducationDetailPage({
    super.key,
    required this.service,
  });

  Color _accentColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains("beauty")) return const Color(0xFFE91E63);
    if (cat.contains("network") ||
        cat.contains("data") ||
        cat.contains("software")) return const Color(0xFF2563EB);
    return const Color(0xFFAE91BA);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(service.category);
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final double sp = sw / 390; // scale factor relative to 390px base

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.35),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          // ── Scrollable content ────────────────────────────────────────
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 88 + mq.viewPadding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Hero image ──────────────────────────────────────────
                _HeroImage(service: service, accent: accent),

                // ── Body ────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * sp,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Category chip + Duration
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(
                            label: service.category,
                            color: accent.withOpacity(0.12),
                            textColor: accent,
                          ),
                          _Chip(
                            icon: Icons.schedule_outlined,
                            label: service.duration,
                            color: Colors.grey.shade100,
                            textColor: Colors.grey.shade700,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // About section
                      _SectionTitle("About this course"),
                      const SizedBox(height: 8),
                      Text(
                        service.description,
                        style: TextStyle(
                          fontSize: 14 * sp,
                          color: const Color(0xFF4B5563),
                          height: 1.65,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // What you'll learn
                      if (service.includes.isNotEmpty) ...[
                        _BulletCard(
                          title: "What you'll learn",
                          items: service.includes,
                          iconColor: accent,
                          sp: sp, iconData: Icons.check,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Course flow / steps
                      if (service.steps.isNotEmpty) ...[
                        _StepsCard(
                          steps: service.steps,
                          accent: accent,
                          sp: sp,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tools & Materials
                      if (service.tools.isNotEmpty) ...[
                        _InfoCard(
                          icon: Icons.build_outlined,
                          title: "Tools & Materials",
                          body: service.tools,
                          accent: accent,
                          sp: sp,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Support / Warranty
                      if (service.warranty.isNotEmpty) ...[
                        _InfoCard(
                          icon: Icons.headset_mic_outlined,
                          title: "Support",
                          body: service.warranty,
                          accent: accent,
                          sp: sp,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky bottom bar ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(
              service: service,
              accent: accent,
              sp: sp,
              context: context,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HERO IMAGE
// ──────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final EducationService service;
  final Color accent;

  const _HeroImage({required this.service, required this.accent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(service.image, fit: BoxFit.cover),
          // Gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // Course name at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Text(
              service.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CHIP
// ──────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION TITLE
// ──────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
        letterSpacing: -0.2,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BULLET CARD  (What you'll learn)
// ──────────────────────────────────────────────────────────────────────────────

class _BulletCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color iconColor;
  final IconData iconData;
  final double sp;

  const _BulletCard({
    required this.title,
    required this.items,
    required this.iconColor,
    required this.iconData,
    required this.sp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, size: 11, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5 * sp,
                        color: const Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// STEPS CARD  (numbered course flow)
// ──────────────────────────────────────────────────────────────────────────────

class _StepsCard extends StatelessWidget {
  final List<String> steps;
  final Color accent;
  final double sp;

  const _StepsCard({
    required this.steps,
    required this.accent,
    required this.sp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle("Course flow"),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map(
            (entry) {
              final isLast = entry.key == steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number + line connector
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 28,
                          color: accent.withOpacity(0.18),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : 14,
                        top: 4,
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13.5 * sp,
                          color: const Color(0xFF374151),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// INFO CARD  (tools / support — single text block)
// ──────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final double sp;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.sp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13.5 * sp,
                    color: const Color(0xFF4B5563),
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// STICKY BOTTOM BAR
// ──────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final EducationService service;
  final Color accent;
  final double sp;
  final BuildContext context;

  const _BottomBar({
    required this.service,
    required this.accent,
    required this.sp,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            Cart.addEducation(
              id: service.id,
              name: service.name,
              price: 0,
              category: service.category,
              image: service.image,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${service.name} added to enquiry"),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                action: SnackBarAction(
                  label: "View Courses",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartPage(
                          service: "Education",
                          serviceName: '',
                          cart: [],
                          providerId: '',
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.send_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                "Send Enquiry",
                style: TextStyle(
                  fontSize: 15 * sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}