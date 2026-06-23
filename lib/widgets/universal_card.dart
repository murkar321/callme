import 'package:flutter/material.dart';

enum ServiceActionType {
  normal,
  quantity,
}

class UniversalServiceCard extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final double? rating;
  final int price;
  final Color primaryColor;
  final ServiceActionType actionType;
  final int quantity;
  final VoidCallback onView;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  const UniversalServiceCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.primaryColor,
    required this.onView,
    required this.onPrimaryAction,
    this.rating,
    this.actionType = ServiceActionType.normal,
    this.quantity = 0,
    this.onIncrease,
    this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + badge ───────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  image,
                  height: width * 0.40,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: width * 0.40,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              if (quantity > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // ── Content ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(rating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12)),
                    ],
                    const Spacer(),
                    Text('₹$price',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Buttons ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: onView,
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
                        child: _buildAction(),
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

  Widget _buildAction() {
    if (actionType == ServiceActionType.quantity) {
      return quantity == 0
          ? ElevatedButton(
              onPressed: onIncrease,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('ADD',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            )
          : Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SmallBtn(icon: Icons.remove, color: primaryColor, onTap: onDecrease),
                  Flexible(
                    child: Text(quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  _SmallBtn(icon: Icons.add, color: primaryColor, onTap: onIncrease),
                ],
              ),
            );
    }

    return ElevatedButton(
      onPressed: onPrimaryAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('ADD',
          style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ── Compact +/- button ──────────────────────────────────────────────────────

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SmallBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}