import 'package:flutter/material.dart';
import 'package:callme/bookings/civil_book_page.dart';
import '../data/renovation_options.dart';

class RenovationBottomSheet extends StatefulWidget {
  final String packageId;
  final String packageName;

  const RenovationBottomSheet({
    super.key,
    required this.packageId,
    required this.packageName,
  });

  @override
  State<RenovationBottomSheet> createState() => _RenovationBottomSheetState();
}

class _RenovationBottomSheetState extends State<RenovationBottomSheet> {
  List<RenovationOption> selected = [];

  static const _accent = Color(0xFF6A5AE0);

  int get total {
    int sum = 0;
    for (var item in selected) {
      sum += int.tryParse(item.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return sum;
  }

  String get _priceRange {
    switch (widget.packageId) {
      case 'basic':
        return '₹1,200 – ₹2,800 / sq.ft';
      case 'standard':
        return '₹2,800 – ₹4,500 / sq.ft';
      case 'premium':
        return '₹4,500+ / sq.ft';
      default:
        return '';
    }
  }

  String get _bestFor {
    switch (widget.packageId) {
      case 'basic':
        return 'Low budget refresh';
      case 'standard':
        return 'Mid-range overhaul';
      case 'premium':
        return 'Luxury transformation';
      default:
        return '';
    }
  }

  Color get _packageColor {
    switch (widget.packageId) {
      case 'basic':
        return const Color(0xFF2E7D32);
      case 'standard':
        return const Color(0xFF1565C0);
      case 'premium':
        return const Color(0xFF6A1B9A);
      default:
        return _accent;
    }
  }

  void _proceed() {
    if (selected.isEmpty) return;

    // Build selected item names list to pass to booking page
    final selectedNames = selected.map((e) => e.name).toList();

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CivilBookingPage(
          serviceName: widget.packageName,
          providerId: '',
          cart: [],
          products: [],
          selectedRenovationItems: selectedNames,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final bottomPad = mq.viewPadding.bottom;
    final options = renovationOptions[widget.packageId] ?? [];
    final pkgColor = _packageColor;

    return Container(
      height: screenHeight * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),

          // ── Header ───────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pkgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.packageName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _priceRange,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _bestFor,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Worker illustration
                SizedBox(
                  height: 80,
                  child: Image.asset(
                    'assets/worker.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.construction_rounded,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Section label ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Text(
                  'Select services',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                if (selected.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pkgColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${selected.length} selected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: pkgColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Options list ──────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                final isSelected = selected.contains(opt);

                return GestureDetector(
                  onTap: () => setState(() {
                    isSelected ? selected.remove(opt) : selected.add(opt);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? pkgColor.withOpacity(0.07)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? pkgColor.withOpacity(0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? pkgColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? pkgColor
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? pkgColor
                                  : const Color(0xFF2D2D3A),
                            ),
                          ),
                        ),
                        if (opt.price.isNotEmpty)
                          Text(
                            opt.price,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? pkgColor
                                  : Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Bottom bar: total + proceed ───────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${selected.length} service${selected.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        total > 0 ? '₹$total est.' : 'Select services',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: total > 0
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Proceed button
                GestureDetector(
                  onTap: selected.isEmpty ? null : _proceed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected.isEmpty
                          ? Colors.grey.shade300
                          : pkgColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: selected.isEmpty
                          ? []
                          : [
                              BoxShadow(
                                color: pkgColor.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          selected.isEmpty ? 'Select items' : 'Proceed',
                          style: TextStyle(
                            color: selected.isEmpty
                                ? Colors.grey.shade500
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}