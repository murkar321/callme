import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../screens/salon_detail_page.dart';
import '../models/cart_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SALON SERVICE CARD  – Android-safe, adaptive
// ─────────────────────────────────────────────────────────────────────────────

class SalonServiceCard extends StatefulWidget {
  final SalonService service;
  final VoidCallback? onUpdate;

  const SalonServiceCard({
    super.key,
    required this.service,
    this.onUpdate,
  });

  @override
  State<SalonServiceCard> createState() => _SalonServiceCardState();
}

class _SalonServiceCardState extends State<SalonServiceCard> {
  static const _theme = Color.fromARGB(255, 207, 16, 150);

  String _key(String visitType) => '${widget.service.id}_$visitType';
  int _getQty(String visitType) => Cart.getQuantity(_key(visitType), 'Salon');

  void _add(String visitType) {
    Cart.addSalon(
      id: _key(visitType),
      name: widget.service.name,
      price: widget.service.finalPrice,
      category: widget.service.category,
      visitType: visitType,
      image: widget.service.image,
    );
    setState(() {});
    widget.onUpdate?.call();
  }

  void _remove(String visitType) {
    Cart.removeById(_key(visitType), 'Salon');
    setState(() {});
    widget.onUpdate?.call();
  }

  String get _badge {
    if (widget.service.discount >= 25) return 'Best Deal';
    if (widget.service.price <= 300) return 'Budget';
    return 'Popular';
  }

  double get _rating => 4.2 + (widget.service.id % 5) * 0.1;

  @override
  Widget build(BuildContext context) {
    final homeQty = _getQty('Home');
    final salonQty = _getQty('Salon');
    final totalQty = homeQty + salonQty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(widget.service.image, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              if (totalQty > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: _theme, shape: BoxShape.circle),
                    child: Text('$totalQty',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),

          // ── Content ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(widget.service.slogan,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(_rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.service.time,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text('₹${widget.service.finalPrice}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(width: 8),
                  if (widget.service.discount > 0)
                    Text('₹${widget.service.price}',
                        style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade400,
                            fontSize: 12)),
                  const SizedBox(width: 8),
                  if (widget.service.discount > 0)
                    Text('${widget.service.discount}% OFF',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),

                // ── Button area ────────────────────────────────────────────
                if (totalQty == 0)
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalonDetailPage(
                                  service: widget.service),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: BorderSide(
                                color: Colors.grey.shade300, width: 1.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('VIEW',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => _showPopup(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _theme,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('BOOK',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ])
                else
                  Column(
                    children: [
                      _qtyRow('Home', homeQty),
                      const SizedBox(height: 6),
                      _qtyRow('Salon', salonQty),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CartPage(
                                service: 'Salon',
                                serviceName: 'Salon',
                                cart: Cart.getItems('Salon'),
                                providerId: '',
                              ),
                            ),
                          ).then((_) => setState(() {})),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _theme,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('View Cart ($totalQty)',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Qty row ────────────────────────────────────────────────────────────────
  Widget _qtyRow(String type, int qty) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(type,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        const Spacer(),
        if (qty == 0)
          GestureDetector(
            onTap: () => _add(type),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _theme.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Add',
                  style: TextStyle(
                      color: _theme,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          )
        else
          Row(children: [
            _smallBtn(Icons.remove, () => _remove(type)),
            SizedBox(
              width: 28,
              child: Text('$qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            _smallBtn(Icons.add, () => _add(type)),
          ]),
      ],
    );
  }

  Widget _smallBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: _theme.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: _theme),
        ),
      );

  // ── Bottom sheet popup ─────────────────────────────────────────────────────
  void _showPopup(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPad + 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44, height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Choose Appointment Type',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              _optionCard(
                icon: Icons.home_rounded,
                title: 'Home Appointment',
                subtitle: 'Professional visits your home',
                color: Colors.purple,
                onTap: () {
                  _add('Home');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              _optionCard(
                icon: Icons.storefront_rounded,
                title: 'Salon Visit',
                subtitle: 'Visit salon for premium experience',
                color: Colors.green,
                onTap: () {
                  _add('Salon');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.04),
          border: Border.all(color: color.withOpacity(0.2), width: 1.3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
