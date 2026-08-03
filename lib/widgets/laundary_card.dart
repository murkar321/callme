import 'package:flutter/material.dart';
import 'package:callme/data/service_product.dart';
import 'package:callme/models/luandary_detail_page.dart';
import 'package:callme/data/laundry_fabric_sheet.dart';

/// Self-contained laundry product card. ADD opens the shared fabric sheet,
/// VIEW opens the detail page — both by default. Override onAdd/onView only
/// if a specific screen needs different behavior.
class LaundryCard extends StatelessWidget {
  final ServiceProduct product;
  final String category;
  final String serviceName;
  final VoidCallback? onAdd;
  final VoidCallback? onView;
  final VoidCallback? onCartChanged;

  const LaundryCard({
    super.key,
    required this.product,
    required this.category,
    this.serviceName = 'Laundry',
    this.onAdd,
    this.onView,
    this.onCartChanged,
  });

  static const _theme = Color(0xFFAE91BA);

  void _handleAdd(BuildContext context) {
    if (onAdd != null) {
      onAdd!();
      return;
    }
    showLaundryFabricSheet(
      context,
      product: product,
      category: category,
      themeColor: _theme,
      onAdded: onCartChanged,
    );
  }

  void _handleView(BuildContext context) {
    if (onView != null) {
      onView!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LaundryDetailPage(
          product: product,
          category: category,
          serviceName: serviceName,
        ),
      ),
    ).then((_) => onCartChanged?.call());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ THEME FIX: card surface, text, and border colors now branch on
    // isDark instead of the previous hardcoded light-mode values.
    final Color cardBg = isDark ? const Color(0xFF1B1922) : Colors.white;
    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.35) : Colors.grey.shade300;
    final Color primaryText = isDark ? Colors.white : Colors.black;
    final Color mutedText = isDark ? Colors.white54 : Colors.grey.shade600;
    final Color outlineBorder = isDark ? Colors.white24 : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: AspectRatio(
                  aspectRatio: 5 / 3,
                  child: Image.asset(product.imagePath, fit: BoxFit.cover),
                ),
              ),
              if (product.badge != null && product.badge!.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryText),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '₹${product.calculatedFinalPrice}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryText),
                      ),
                      const SizedBox(width: 6),
                      if (product.discount != null && product.discount! > 0)
                        Text(
                          '${product.discount}% OFF',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(product.safeRating.toString(),
                          style: TextStyle(fontSize: 10, color: primaryText)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          product.serviceTime,
                          style: TextStyle(fontSize: 10, color: mutedText),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: () => _handleAdd(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _theme,
                              padding: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('ADD',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () => _handleView(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: BorderSide(
                                  color: outlineBorder, width: 1.2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('VIEW',
                                style:
                                    TextStyle(fontSize: 12, color: primaryText)),
                          ),
                        ),
                      ),
                    ],
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