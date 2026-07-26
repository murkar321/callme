import 'package:flutter/material.dart';
import 'package:callme/models/cart.dart';
import 'package:callme/data/service_product.dart';

const List<String> kLaundryFabrics = [
  'Cotton', 'Silk', 'Wool', 'Denim', 'Polyester', 'Curtains', 'Shoes',
];

/// Shared fabric-selection bottom sheet used by every laundry entry point
/// (product card ADD button, detail page ADD/BOOK bar). One popup, one
/// add-to-cart logic path — keeps them from drifting out of sync.
Future<void> showLaundryFabricSheet(
  BuildContext context, {
  required ServiceProduct product,
  required String category,
  Color themeColor = const Color(0xFFAE91BA),
  VoidCallback? onAdded,
}) {
  final Map<String, int> qty = {for (final f in kLaundryFabrics) f: 0};

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true, // handles gesture-nav / 3-button nav bar automatically
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          final totalPieces = qty.values.fold(0, (s, q) => s + q);
          final maxHeight = MediaQuery.of(ctx).size.height * 0.7;

          return Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Choose fabric & quantity',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 18),
                    itemCount: kLaundryFabrics.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final name = kLaundryFabrics[i];
                      final q = qty[name]!;
                      final active = q > 0;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? themeColor.withOpacity(0.07)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? themeColor.withOpacity(0.5)
                                : Colors.grey.shade200,
                            width: 1.3,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            _QtyControl(
                              qty: q,
                              color: themeColor,
                              onDecrement: q > 0
                                  ? () => setModal(() => qty[name] = q - 1)
                                  : null,
                              onIncrement: () =>
                                  setModal(() => qty[name] = q + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (totalPieces > 0) ...[
                        Text(
                          '$totalPieces piece${totalPieces == 1 ? '' : 's'} selected',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: totalPieces == 0
                              ? null
                              : () {
                                  for (final name in kLaundryFabrics) {
                                    final q = qty[name]!;
                                    for (int i = 0; i < q; i++) {
                                      Cart.addLaundry(
                                        id: '${product.id}_${name.toLowerCase()}',
                                        name: '${product.name} ($name)',
                                        price: product.calculatedFinalPrice,
                                        category: category,
                                        image: product.imagePath,
                                      );
                                    }
                                  }
                                  Navigator.pop(ctx);
                                  onAdded?.call();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            disabledBackgroundColor: Colors.grey.shade200,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            totalPieces == 0
                                ? 'ADD TO CART'
                                : 'ADD $totalPieces ITEM${totalPieces == 1 ? '' : 'S'} TO CART',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final Color color;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _QtyControl({
    required this.qty,
    required this.color,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove,
          color: color,
          enabled: onDecrement != null,
          onTap: onDecrement ?? () {},
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        _Btn(icon: Icons.add, color: color, enabled: true, onTap: onIncrement),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _Btn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.15) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: enabled ? color : Colors.grey.shade400),
      ),
    );
  }
}