import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../bookings/booking_page.dart';
import '../bookings/salon_booking_page.dart';
import '../bookings/enquiry_page.dart';
import '../bookings/civil_book_page.dart';

// Services that use EnquiryPage (no booking, no payment).
const _enquiryServices = {'Education'};

class CartPage extends StatefulWidget {
  /// Short service key — used as cart key AND passed to booking pages as
  /// [serviceName] so Firestore queries use the right normalized value
  /// (e.g. "civil", "salon"). This must match the provider's serviceType field.
  final String service;

  /// Human-readable display label shown in the UI (e.g. "Civil Contract Services").
  final String serviceName;

  /// Provider ID resolved by the caller screen (may be empty — booking pages
  /// will self-resolve if needed).
  final String providerId;

  const CartPage({
    super.key,
    required this.service,
    required this.serviceName,
    required this.providerId,
    List<dynamic> cart = const [],
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  int get _totalAmount => Cart.getTotal(widget.service);

  String _visitLabel(CartItem item) {
    if (widget.service != 'Salon') return '';
    return item.id.toString().contains('Home') ? 'Home Visit' : 'Salon Visit';
  }

  Color get _accent {
    switch (widget.service) {
      case 'Salon':
        return const Color(0xFFB38BFA);
      case 'Education':
        return const Color(0xFF4CAF8C);
      case 'Civil':
        return const Color(0xFFE07B39);
      default:
        return const Color(0xFF6A5AE0);
    }
  }

  bool get _isEnquiry => _enquiryServices.contains(widget.service);

  // Civil uses CivilBookingPage (enquiry flow, no payment).
  bool get _isCivil => widget.service == 'Civil';

  // Salon uses SalonBookingPage (payment flow with home/salon popup).
  bool get _isSalon => widget.service == 'Salon';

  String get _ctaLabel {
    if (_isEnquiry) return 'Send Enquiry';
    if (_isCivil)   return 'Proceed to Book';
    return 'Book Now';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final items = Cart.getItems(widget.service);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              _buildHeader(items.length),
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState()
                    : _buildItemList(items),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: items.isEmpty ? null : _buildBottomBar(items),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.serviceName.isNotEmpty
                      ? widget.serviceName
                      : '${widget.service} Cart',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count item${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),

          if ((_isEnquiry || _isCivil) && count > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Enquiry',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ),

          if (count > 0)
            TextButton(
              onPressed: () {
                Cart.clear(widget.service);
                _refresh();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // ITEM LIST
  // =========================================================

  Widget _buildItemList(List<CartItem> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: items.length,
      itemBuilder: (_, index) => _buildCartItem(items[index]),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final visitLabel = _visitLabel(item);

    return Dismissible(
      key: ValueKey('${widget.service}_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 28),
      ),
      onDismissed: (_) {
        Cart.delete(item.id, widget.service);
        _refresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey.shade100,
                  child: item.image != null
                      ? Image.asset(
                          item.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade400,
                          ),
                        )
                      : Icon(Icons.image_outlined,
                          color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),

                    if (visitLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _badge(visitLabel),
                    ],

                    if (_isEnquiry || _isCivil) ...[
                      const SizedBox(height: 6),
                      _badge('Enquiry item', color: _accent),
                    ],

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '₹${item.price}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _accent,
                            ),
                          ),
                        ),

                        // Qty stepper
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _stepButton(
                                icon: Icons.remove,
                                onTap: () {
                                  Cart.removeById(item.id, widget.service);
                                  _refresh();
                                },
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${Cart.getItemCount(item.id, widget.service)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _stepButton(
                                icon: Icons.add,
                                color: _accent,
                                onTap: () {
                                  Cart.add(item, service: widget.service);
                                  _refresh();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Text(
                      'Subtotal: ₹${item.price * Cart.getItemCount(item.id, widget.service)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BOTTOM BAR
  // =========================================================

  Widget _buildBottomBar(List<CartItem> items) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enquiry notice for Education and Civil
            if (_isEnquiry || _isCivil) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _accent.withOpacity(0.25), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: _accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will send an enquiry to the provider. '
                        'They will contact you to confirm.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '₹$_totalAmount',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _onProceed(items),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isEnquiry || _isCivil)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.send_rounded, size: 16),
                          ),
                        Text(
                          _ctaLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  Future<void> _onProceed(List<CartItem> items) async {
    if (_isCivil) {
      // ── Civil: enquiry flow, no payment ──────────────────────────────────
      // Pass widget.service (short key = "Civil") as serviceName so the
      // booking page normalises it to "civil" and matches Firestore correctly.
      // Also pass providerId as initialProviderId so the lookup is skipped
      // entirely when the caller already resolved the provider.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CivilBookingPage(
            serviceName:       widget.service,       // "Civil" → normalised to "civil"
            cart:              items,
            products:          const [],
            initialProviderId: widget.providerId.isNotEmpty
                ? widget.providerId
                : null, providerId: '',
          ),
        ),
      );
    } else if (_isEnquiry) {
      // ── Education (and any future enquiry-only service) ───────────────────
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EnquiryPage(
            serviceName: widget.service,
            cart: items,
          ),
        ),
      );
    } else if (_isSalon) {
      // ── Salon: payment flow with home/salon visit popup ───────────────────
      // Pass providerId as initialProviderId so SalonBookingPage skips the
      // provider lookup when the caller already has the ID.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SalonBookingPage(
            cartItems:         items,
            providerId:        widget.providerId,    // kept for backwards compat
            initialProviderId: widget.providerId.isNotEmpty
                ? widget.providerId
                : null,
          ),
        ),
      );
    } else {
      // ── All other services: universal BookingPage ─────────────────────────
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingPage(
            serviceName:       widget.service,       // short key for Firestore match
            cart:              items,
            products:          const [],
            providerId:        widget.providerId,
            initialProviderId: widget.providerId.isNotEmpty
                ? widget.providerId
                : null,
          ),
        ),
      );
    }
    _refresh();
  }

  // =========================================================
  // UI HELPERS
  // =========================================================

  Widget _badge(String label, {Color? color}) {
    final c = color ?? _accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _stepButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text(
              'Browse Services',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}