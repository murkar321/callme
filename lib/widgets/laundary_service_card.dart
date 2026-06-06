import 'package:flutter/material.dart';
import 'package:callme/models/luandary_detail_page.dart';
import 'package:callme/data/service_product.dart';

class LaundryServiceCard extends StatefulWidget {
  final ServiceProduct service;
  final String serviceName;
  final String category;

  const LaundryServiceCard({
    super.key,
    required this.service,
    required this.serviceName,
    required this.category,
  });

  @override
  State<LaundryServiceCard> createState() => _LaundryServiceCardState();
}

class _LaundryServiceCardState extends State<LaundryServiceCard> {
  int quantity = 0;

  void _increment() {
    setState(() => quantity++);
  }

  void _decrement() {
    if (quantity > 0) setState(() => quantity--);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LaundryDetailPage(
              product: widget.service,
              serviceName: widget.serviceName,
              category: widget.category,
            ),
          ),
        );
      },

      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [

            /// 🖼 IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                widget.service.imagePath,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 70,
                  width: 70,
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// 📄 DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// NAME
                  Text(
                    widget.service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// DESCRIPTION
                  Text(
                    widget.service.description ?? "Laundry Service",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // ✅ Price is hidden here — shown only after adding
                ],
              ),
            ),

            /// ➕ ADD / QUANTITY CONTROL
            GestureDetector(
              onTap: null, // prevent card tap when tapping controls
              child: quantity == 0
                  ? _AddButton(onTap: _increment)
                  : _QuantityControl(
                      quantity: quantity,
                      price: widget.service.calculatedFinalPrice,
                      onIncrement: _increment,
                      onDecrement: _decrement,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ADD Button (shown when quantity == 0)
// ─────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6C47FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'ADD',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUANTITY CONTROL + PRICE (shown when quantity > 0)
// ─────────────────────────────────────────────────────────────
class _QuantityControl extends StatelessWidget {
  final int quantity;
  final num price;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityControl({
    required this.quantity,
    required this.price,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        // ── ₹ Price (only visible after adding) ──
        Text(
          '₹${(price * quantity).toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF6C47FF),
          ),
        ),

        const SizedBox(height: 6),

        // ── − qty + ──
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6C47FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyButton(
                icon: Icons.remove,
                onTap: onDecrement,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add,
                onTap: onIncrement,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}