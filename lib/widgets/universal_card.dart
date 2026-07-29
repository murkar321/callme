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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final onSurface = theme.colorScheme.onSurface;
    final subTextColor = onSurface.withOpacity(0.62);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.grey.shade300;
    final imagePlaceholder = isDark ? Colors.grey.shade800 : Colors.grey[200];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.asset(
                  image,
                  height: width * 0.32,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: width * 0.32,
                    color: imagePlaceholder,
                    child: Icon(Icons.image, color: subTextColor),
                  ),
                ),
              ),
              if (quantity > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // ── Content ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: onSurface)),
                const SizedBox(height: 3),
                Text(description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: subTextColor)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star, size: 13, color: Colors.orange),
                      const SizedBox(width: 3),
                      Text(rating!.toStringAsFixed(1),
                          style: TextStyle(fontSize: 11.5, color: onSurface)),
                    ],
                    const Spacer(),
                    Text('₹$price',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: onSurface)),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Buttons ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: onView,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: BorderSide(color: borderColor, width: 1.1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9)),
                          ),
                          child: Text('VIEW',
                              style: TextStyle(
                                  fontSize: 11.5, color: onSurface)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
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
                    borderRadius: BorderRadius.circular(9)),
              ),
              child: const Text('ADD',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold)),
            )
          : Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SmallBtn(
                      icon: Icons.remove, color: primaryColor, onTap: onDecrease),
                  Flexible(
                    child: Text(quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  _SmallBtn(
                      icon: Icons.add, color: primaryColor, onTap: onIncrease),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: const Text('ADD',
          style: TextStyle(
              color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}