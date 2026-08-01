import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';

class SalonDetailPage extends StatefulWidget {
  final SalonService service;

  const SalonDetailPage({
    super.key,
    required this.service,
  });

  @override
  State<SalonDetailPage> createState() => _SalonDetailPageState();
}

class _SalonDetailPageState extends State<SalonDetailPage> {
  static const String serviceName = "Salon";
  static const Color _brand = Color(0xFFAE91BA);

  void refresh() => setState(() {});

  /// UNIQUE IDS
  String _id(String type) => "${widget.service.id}_$type";

  int _qty(String type) => Cart.getQuantity(_id(type), serviceName);

  int get totalQty => _qty("Home") + _qty("Salon");

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color cardBg = theme.cardColor;
    final Color subtleText = cs.onSurface.withOpacity(0.6);

    /// Bottom system navigation bar height (handles gesture bar & button nav)
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    /// Total height of the floating bottom bar + safe area
    final double bottomBarHeight = 84 + bottomPadding;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: Stack(
        children: [

          /// ================= BODY =================
          CustomScrollView(
            slivers: [

              /// ================= APP BAR =================
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: _brand,

                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [

                      /// IMAGE
                      Image.asset(
                        widget.service.image,
                        fit: BoxFit.cover,
                      ),

                      /// DARK OVERLAY
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),

                      /// TEXT
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// CATEGORY
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                widget.service.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            /// NAME
                            Text(
                              widget.service.name,
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// SLOGAN
                            Text(
                              widget.service.slogan,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// ================= CONTENT =================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// ================= PRICE CARD =================
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [

                            /// PRICE
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Starting Price",
                                  style: TextStyle(color: subtleText),
                                ),

                                const SizedBox(height: 6),

                                Row(
                                  children: [
                                    Text(
                                      "₹${widget.service.finalPrice}",
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    if (widget.service.discount > 0)
                                      Text(
                                        "₹${widget.service.price}",
                                        style: TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: subtleText,
                                          fontSize: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),

                            const Spacer(),

                            /// DISCOUNT BADGE
                            if (widget.service.discount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.green.withOpacity(0.18)
                                      : Colors.green.shade100,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Text(
                                  "${widget.service.discount}% OFF",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.greenAccent.shade200
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// ================= DESCRIPTION =================
                      _sectionTitle("About Service"),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.service.description,
                          style: const TextStyle(
                            height: 1.6,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// ================= INCLUDES =================
                      _sectionTitle("What's Included"),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: widget.service.includes.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  /// ICON
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.green
                                          .withOpacity(isDark ? 0.18 : 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: isDark
                                          ? Colors.greenAccent.shade200
                                          : Colors.green,
                                      size: 18,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      /// ── BOTTOM CLEARANCE ──────────────────────────────────
                      /// Ensures content scrolls above the floating bottom bar
                      /// (bar height 84 + safe area + 16px breathing room)
                      SizedBox(height: bottomBarHeight + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          /// ================= BOTTOM BAR =================
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,                           // ← anchored to screen edge
            child: Container(
              /// ── SAFE AREA AWARE PADDING ───────────────────────────────────
              /// Adds dynamic padding so the bar content sits above the
              /// system navigation bar (gesture strip or 3-button nav).
              padding: EdgeInsets.fromLTRB(
                14,
                14,
                14,
                14 + bottomPadding,              // ← key fix
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),

              child: Row(
                children: [

                  /// CART BUTTON
                  if (totalQty > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 55),
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                          side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CartPage(
                                service: serviceName,
                                serviceName: serviceName,
                                cart: Cart.getItems(serviceName),
                                providerId: '',
                              ),
                            ),
                          ).then((_) => refresh());
                        },
                        child: Text(
                          "Cart ($totalQty)",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                  if (totalQty > 0) const SizedBox(width: 12),

                  /// BOOK BUTTON
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        elevation: 0,
                        minimumSize: const Size(0, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _showBookingPopup(context),
                      child: Text(
                        totalQty == 0 ? "Book Appointment" : "Add More",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  /// ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// ================= CENTER BOOKING POPUP =================
  void _showBookingPopup(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Booking",
      barrierColor: Colors.black.withOpacity(0.55),

      transitionDuration: const Duration(milliseconds: 300),

      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,

            child: Container(
              width: size.width * 0.88,

              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: size.height * 0.75,
              ),

              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(30),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// CLOSE BUTTON
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => Navigator.pop(context),

                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// ICON
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _brand.withOpacity(isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        color: _brand,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// TITLE
                    const Text(
                      "Choose Appointment",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// SUBTITLE
                    Text(
                      "Select your preferred service experience",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.6),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// HOME APPOINTMENT
                    _appointmentCard(
                      context: context,
                      icon: Icons.home_rounded,
                      title: "Home Appointment",
                      subtitle: "Professional visits your home",
                      color: Colors.purple,
                      onTap: () {
                        Cart.addSalon(
                          id: _id("Home"),
                          name: widget.service.name,
                          price: widget.service.finalPrice,
                          category: widget.service.category,
                          visitType: "Home",
                          image: widget.service.image,
                        );

                        Navigator.pop(context);
                        refresh();
                        _showSnack("Added to Cart (Home)");
                      },
                    ),

                    const SizedBox(height: 18),

                    /// SALON APPOINTMENT
                    _appointmentCard(
                      context: context,
                      icon: Icons.storefront_rounded,
                      title: "Salon Visit",
                      subtitle: "Visit salon for premium experience",
                      color: Colors.green,
                      onTap: () {
                        Cart.addSalon(
                          id: _id("Salon"),
                          name: widget.service.name,
                          price: widget.service.finalPrice,
                          category: widget.service.category,
                          visitType: "Salon",
                          image: widget.service.image,
                        );

                        Navigator.pop(context);
                        refresh();
                        _showSnack("Added to Cart (Salon)");
                      },
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },

      /// ANIMATION
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
    );
  }

  /// ================= APPOINTMENT CARD =================
  Widget _appointmentCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.65);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.35 : 0.2),
          ),
          color: color.withOpacity(isDark ? 0.12 : 0.05),
        ),
        child: Row(
          children: [

            /// ICON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.25 : 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),

            const SizedBox(width: 16),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SNACKBAR =================
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}