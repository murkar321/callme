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

  void refresh() => setState(() {});

  /// UNIQUE IDS
  String _id(String type) => "${widget.service.id}_$type";

  int _qty(String type) => Cart.getQuantity(_id(type), serviceName);

  int get totalQty => _qty("Home") + _qty("Salon");

  @override
  Widget build(BuildContext context) {
    /// Bottom system navigation bar height (handles gesture bar & button nav)
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    /// Total height of the floating bottom bar + safe area
    final double bottomBarHeight = 84 + bottomPadding;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),

      body: Stack(
        children: [

          /// ================= BODY =================
          CustomScrollView(
            slivers: [

              /// ================= APP BAR =================
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: const Color(0xFFAE91BA),

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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                const Text(
                                  "Starting Price",
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
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
                                        style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
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
                                  color: Colors.green.shade100,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Text(
                                  "${widget.service.discount}% OFF",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
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
                          color: Colors.white,
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
                          color: Colors.white,
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
                                      color:
                                          Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.green,
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
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                        backgroundColor: const Color(0xFFAE91BA),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
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
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// ICON
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAE91BA).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.content_cut_rounded,
                        color: Color(0xFFAE91BA),
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
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 28),

                    /// HOME APPOINTMENT
                    _appointmentCard(
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
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [

            /// ICON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
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