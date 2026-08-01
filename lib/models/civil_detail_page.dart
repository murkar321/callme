import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/civil_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';
import '../widgets/renovation_bottom_sheet.dart';
import 'civil_services_page.dart';

class CivilServiceDetailPage extends StatefulWidget {
  final SubService service;
  final String mainServiceId;

  const CivilServiceDetailPage({
    super.key,
    required this.service,
    required this.mainServiceId,
  });

  @override
  State<CivilServiceDetailPage> createState() =>
      _CivilServiceDetailPageState();
}

class _CivilServiceDetailPageState extends State<CivilServiceDetailPage> {
  bool _addedToCart = false;

  bool get _isRenovation => widget.mainServiceId == 'renovation';

  int _extractPrice(String price) {
    final numbers = price.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isEmpty) return 0;
    return int.tryParse(numbers) ?? 0;
  }

  void _handlePrimaryAction() {
    if (_isRenovation) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => RenovationBottomSheet(
          packageId: widget.service.id,
          packageName: widget.service.name,
        ),
      );
    } else {
      HapticFeedback.lightImpact();
      Cart.add(
        CartItem(
          id: widget.service.id,
          name: widget.service.name,
          price: _extractPrice(widget.service.price),
          service: kCivilServiceKey,
          category: widget.mainServiceId,
          image: widget.service.image,
        ),
        service: kCivilServiceKey,
      );
      setState(() => _addedToCart = true);
    }
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          serviceName: 'Civil Contract Services',
          service: kCivilServiceKey,
          providerId: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final heroHeight = screenWidth * 0.72;

    // ── DARK MODE AWARENESS ──────────────────────────────────────────
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF121016) : const Color(0xFFF6F7FB);
    final Color appBarBg = isDark ? const Color(0xFF1B1922) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: heroHeight,
                pinned: true,
                backgroundColor: appBarBg,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                automaticallyImplyLeading: false,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroSection(service: widget.service),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16, 22, 16,
                    90 + mq.viewPadding.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.service.about != null &&
                          widget.service.about!.isNotEmpty) ...[
                        _SectionTitle(title: 'About this service', isDark: isDark),
                        const SizedBox(height: 10),
                        _AboutCard(about: widget.service.about!, isDark: isDark),
                        const SizedBox(height: 22),
                      ],

                      if (widget.service.features != null &&
                          widget.service.features!.isNotEmpty) ...[
                        _SectionTitle(title: "What's included", isDark: isDark),
                        const SizedBox(height: 12),
                        ...widget.service.features!
                            .map((f) => _FeatureRow(label: f, isDark: isDark)),
                        const SizedBox(height: 22),
                      ],

                      if (!_isRenovation && _addedToCart)
                        _CartAddedBanner(isDark: isDark),
                      if (!_isRenovation && !_addedToCart)
                        _BookInfoBanner(isDark: isDark),
                      if (_isRenovation) _RenovationHint(isDark: isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(
              isRenovation: _isRenovation,
              addedToCart: _addedToCart,
              onPrimary: _handlePrimaryAction,
              onViewCart: _openCart,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final SubService service;
  const _HeroSection({required this.service});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          service.image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Icon(Icons.construction, size: 64, color: Colors.grey),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.3, 0.7, 1.0],
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.85),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                service.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _Pill(
                color: Colors.green.shade600,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      service.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Pill({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: child,
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, this.isDark = false});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          letterSpacing: 0.1,
        ),
      );
}

class _AboutCard extends StatelessWidget {
  final String about;
  final bool isDark;
  const _AboutCard({required this.about, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1922) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(isDark ? 0.18 : 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: Color(0xFF1565C0), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              about,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF3D3D50),
                  height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FeatureRow({required this.label, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1922) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.withOpacity(0.15)
                    : Colors.green.shade50,
                shape: BoxShape.circle),
            child: Icon(Icons.check_rounded,
                color: isDark ? Colors.greenAccent.shade200 : Colors.green.shade700,
                size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF2D2D3A),
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _RenovationHint extends StatelessWidget {
  final bool isDark;
  const _RenovationHint({this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.orange.withOpacity(0.12) : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.orange.withOpacity(0.4) : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded,
              color: isDark ? Colors.orange.shade300 : Colors.orange.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tap 'Customize & Book' to choose specific services for this package.",
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.orange.shade200 : Colors.orange.shade800,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartAddedBanner extends StatelessWidget {
  final bool isDark;
  const _CartAddedBanner({this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withOpacity(0.12) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.green.withOpacity(0.4) : Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: isDark ? Colors.greenAccent.shade200 : Colors.green.shade600,
              size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Added to cart! Tap 'View Cart' to proceed.",
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.green.shade100 : const Color(0xFF2D5A27)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookInfoBanner extends StatelessWidget {
  final bool isDark;
  const _BookInfoBanner({this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withOpacity(0.12) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.blue.withOpacity(0.4) : Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade600, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tap 'Book Now' to add this service to your cart.",
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.blue.shade100 : Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool isRenovation;
  final bool addedToCart;
  final VoidCallback onPrimary;
  final VoidCallback onViewCart;
  final bool isDark;

  const _BottomActionBar({
    required this.isRenovation,
    required this.addedToCart,
    required this.onPrimary,
    required this.onViewCart,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1922) : Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: SizedBox(
        height: 52,
        child: isRenovation
            ? _PrimaryButton(
                label: 'Customize & Book',
                icon: Icons.edit_note_rounded,
                color: const Color(0xFF1565C0),
                onTap: onPrimary,
              )
            : addedToCart
                ? Row(
                    children: [
                      Expanded(
                        child: _PrimaryButton(
                          label: 'Book Another',
                          icon: Icons.add_rounded,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade700,
                          onTap: onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PrimaryButton(
                          label: 'View Cart',
                          icon: Icons.shopping_cart_rounded,
                          color: Colors.orange.shade700,
                          onTap: onViewCart,
                        ),
                      ),
                    ],
                  )
                : _PrimaryButton(
                    label: 'Book Now',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF1565C0),
                    onTap: onPrimary,
                  ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}