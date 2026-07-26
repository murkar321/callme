import 'package:flutter/material.dart';
import '../data/civil_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';
import '../widgets/civil_card.dart';
import '../widgets/renovation_bottom_sheet.dart';
import '../models/civil_detail_page.dart';

/// Single source of truth for the Civil cart key
const kCivilServiceKey = "Civil";

class CivilServicesPage extends StatefulWidget {
  const CivilServicesPage({super.key});

  @override
  State<CivilServicesPage> createState() => _CivilServicesPageState();
}

class _CivilServicesPageState extends State<CivilServicesPage> {
  int selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  int _extractPrice(String price) {
    final numbers = price.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.isEmpty) return 0;
    return int.tryParse(numbers) ?? 0;
  }

  void _addToCart(SubService sub, String categoryName) {
    Cart.add(
      CartItem(
        id: sub.id,
        name: sub.name,
        price: _extractPrice(sub.price),
        service: kCivilServiceKey,
        category: categoryName,
        image: sub.image,
      ),
      service: kCivilServiceKey,
    );
    _refresh();
  }

  void _handleBooking(SubService sub, String categoryId, String categoryName) {
    if (categoryId == "renovation") {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => RenovationBottomSheet(
          packageId: sub.id,
          packageName: sub.name,
        ),
      );
    } else {
      _addToCart(sub, categoryName);
    }
  }

  void _openDetail(SubService sub, String categoryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CivilServiceDetailPage(
          service: sub,
          mainServiceId: categoryId,
        ),
      ),
    ).then((_) => _refresh());
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartPage(
          serviceName: "Civil Contract Services",
          service: kCivilServiceKey,
          providerId: '',
        ),
      ),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final categories = civilServices;
    final selectedService = categories[selectedIndex];

    // Filter sub-services by the search query, case-insensitive.
    final query = _searchQuery.trim().toLowerCase();
    final subServices = query.isEmpty
        ? selectedService.subServices
        : selectedService.subServices
            .where((s) => s.name.toLowerCase().contains(query))
            .toList();

    final totalItems = Cart.getTotalItems(kCivilServiceKey);
    final bottomPad = mq.viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          "Civil Contract Services",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CartIconButton(
              count: totalItems,
              onTap: totalItems > 0 ? _openCart : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── SEARCH BAR ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: _SearchField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),

            // ── HINT BANNER ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: _TapHintBanner(),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            Expanded(
              child: Row(
                children: [
                  // ── LEFT CATEGORY PANEL ──────────────────────────────
                  _CategoryPanel(
                    categories: categories,
                    selectedIndex: selectedIndex,
                    onSelect: (i) => setState(() => selectedIndex = i),
                  ),

                  // ── RIGHT SERVICE LIST ───────────────────────────────
                  Expanded(
                    child: subServices.isEmpty
                        ? const _EmptySearchState()
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              10,
                              10,
                              10,
                              totalItems > 0 ? 80 + bottomPad : 10 + bottomPad,
                            ),
                            itemCount: subServices.length,
                            itemBuilder: (context, index) {
                              final sub = subServices[index];

                              return CivilServiceCard(
                                service: sub,
                                categoryName: selectedService.name,
                                categoryId: selectedService.id,
                                onTap: () =>
                                    _openDetail(sub, selectedService.id),
                                onAddCart: () => _handleBooking(
                                  sub,
                                  selectedService.id,
                                  selectedService.name,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // ── VIEW CART BAR ──────────────────────────────────────────
            if (totalItems > 0)
              _ViewCartBar(
                totalItems: totalItems,
                bottomPad: bottomPad,
                onTap: _openCart,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: 'Search civil services…',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _TapHintBanner extends StatelessWidget {
  const _TapHintBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_rounded,
              color: const Color(0xFF1565C0), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap on any card to view full service details',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF1565C0).withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No services match your search',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _CartIconButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.shopping_cart_outlined,
            color: count > 0
                ? const Color(0xFF1565C0)
                : Colors.grey.shade500,
          ),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? "9+" : "$count",
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

class _CategoryPanel extends StatelessWidget {
  final List<CivilService> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _CategoryPanel({
    required this.categories,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      color: const Color(0xFFF0F0F5),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1565C0)
                        : Colors.transparent,
                    width: 3.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage(cat.image),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ViewCartBar extends StatelessWidget {
  final int totalItems;
  final double bottomPad;
  final VoidCallback onTap;

  const _ViewCartBar({
    required this.totalItems,
    required this.bottomPad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + bottomPad),
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$totalItems item${totalItems > 1 ? 's' : ''} selected",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_rounded,
                      color: Colors.white, size: 17),
                  SizedBox(width: 8),
                  Text(
                    "View Cart",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
}