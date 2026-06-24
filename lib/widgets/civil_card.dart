import 'package:flutter/material.dart';
import '../data/civil_data.dart';
import '../models/cart.dart';

const kCivilCartKey = "Civil";

/// Card that works directly with [SubService].
/// - Tapping the card body → [onTap] (navigate to detail)
/// - Tapping BOOK / SELECT button → [onAddCart] (cart action only)
class CivilServiceCard extends StatelessWidget {
  final SubService service;
  final String categoryName;
  final String categoryId;
  final VoidCallback onAddCart;
  final VoidCallback? onTap;

  const CivilServiceCard({
    super.key,
    required this.service,
    required this.categoryName,
    required this.categoryId,
    required this.onAddCart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth * 0.44;
    final cartCount = Cart.getItemCount(service.id, kCivilCartKey);
    final bool inCart = cartCount > 0;
    final bool isRenovation = categoryId == "renovation";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // ── BACKGROUND IMAGE ──────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  service.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.construction,
                        size: 48, color: Colors.grey),
                  ),
                ),
              ),

              // ── GRADIENT OVERLAY ──────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.40, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.20),
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                  ),
                ),
              ),

              // ── DISCOUNT BADGE — top left ─────────────────────────
              if (service.discount > 0)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${service.discount}% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

              // ── BOTTOM ROW: name + price + BOOK/SELECT button ─────
              Positioned(
                left: 12,
                right: 10,
                bottom: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Service name + price stacked
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            service.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Price chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 235, 217, 27).withOpacity(0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              service.price,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // BOOK / SELECT button
                    _ActionButton(
                      inCart: inCart,
                      cartCount: cartCount,
                      isRenovation: isRenovation,
                      onTap: onAddCart,
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
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final bool inCart;
  final int cartCount;
  final bool isRenovation;
  final VoidCallback onTap;

  const _ActionButton({
    required this.inCart,
    required this.cartCount,
    required this.isRenovation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isRenovation
        ? const Color(0xFF1565C0)
        : inCart
            ? Colors.green.shade600
            : const Color(0xFFE53935);

    final String label =
        isRenovation ? "SELECT" : inCart ? "ADDED" : "BOOK";

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (inCart && !isRenovation) ...[
                  const Icon(Icons.check, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (cartCount > 0)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                cartCount > 9 ? "9+" : "$cartCount",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}