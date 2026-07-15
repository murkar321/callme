import 'package:flutter/material.dart';
import '../data/salon_data.dart';
import '../models/cart.dart';
import '../models/cart_page.dart';
import '../widgets/salon_service_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SALON PAGE  – Android-safe, adaptive layout, with cross-category search
// ─────────────────────────────────────────────────────────────────────────────

class SalonPage extends StatefulWidget {
  const SalonPage({super.key, required String providerId});

  @override
  State<SalonPage> createState() => _SalonPageState();
}

class _SalonPageState extends State<SalonPage> {
  static const _theme = Color.fromARGB(255, 228, 33, 189);

  int selectedIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  void refresh() => setState(() {});

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  /// Searches across ALL categories — matches service name, category name,
  /// and slogan/description so users can find sub-services regardless of
  /// which category tab is currently selected.
  List<SalonService> _searchResults() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];

    return salonServices.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.category.toLowerCase().contains(query) ||
          s.slogan.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = salonCategories;

    if (categories.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('No categories found')));
    }

    if (selectedIndex >= categories.length) selectedIndex = 0;

    final selectedCategory = categories[selectedIndex];
    final categoryServices =
        salonServices.where((s) => s.category == selectedCategory).toList();

    final searchResults = _searchResults();

    final totalItems =
        Cart.getItems('Salon').fold(0, (sum, i) => sum + i.quantity);
    final totalAmount = Cart.getTotal('Salon');
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Salon Services',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: _theme,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: totalItems > 0
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CartPage(
                            service: 'Salon',
                            serviceName: 'Salon',
                            cart: Cart.getItems('Salon'),
                            providerId: '',
                          ),
                        ),
                      );
                      refresh();
                    }
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 26),
                  if (totalItems > 0)
                    Positioned(
                      top: -6, right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        child: Text(
                          totalItems > 99 ? '99+' : '$totalItems',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search all salon services...',
                        hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  if (_isSearching)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey.shade500),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_isSearching)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                '${searchResults.length} result${searchResults.length == 1 ? '' : 's'} for "${_searchQuery.trim()}"',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

          // ── Main content ─────────────────────────────────────────────
          Expanded(
            child: _isSearching
                ? _buildSearchResults(searchResults, totalItems, bottomPad)
                : _buildCategoryBrowser(
                    categories, categoryServices, totalItems, bottomPad),
          ),
        ],
      ),

      // ── Bottom cart bar — SafeArea handles nav bar ──────────────────────
      bottomNavigationBar: totalItems == 0
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _theme,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$totalItems item${totalItems == 1 ? '' : 's'} • ₹$totalAmount',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _theme,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CartPage(
                                service: 'Salon',
                                serviceName: 'Salon',
                                cart: Cart.getItems('Salon'),
                                providerId: '',
                              ),
                            ),
                          );
                          refresh();
                        },
                        child: const Text('View Cart',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Category browser (rail + list) — default view ─────────────────────
  Widget _buildCategoryBrowser(List<String> categories,
      List<SalonService> services, int totalItems, double bottomPad) {
    return Row(
      children: [
        // ── Left: category rail ─────────────────────────────────────────
        Container(
          width: 90,
          color: Colors.white,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 6),
            itemCount: categories.length,
            itemBuilder: (_, index) {
              final category = categories[index];
              final isSelected = selectedIndex == index;
              final firstItem = salonServices
                  .where((s) => s.category == category)
                  .toList();
              final image = firstItem.isNotEmpty
                  ? firstItem.first.image
                  : 'assets/salon.png';

              return GestureDetector(
                onTap: () => setState(() => selectedIndex = index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            isSelected ? _theme : Colors.grey.shade200,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(image),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? _theme : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Right: services list ────────────────────────────────────────
        Expanded(
          child: services.isEmpty
              ? const Center(
                  child: Text('No services in this category',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  // Extra bottom padding = cart bar (68) + nav bar inset
                  padding: EdgeInsets.fromLTRB(
                      8, 8, 8, totalItems > 0 ? 68 + bottomPad + 10 : 10),
                  itemCount: services.length,
                  itemBuilder: (_, index) => SalonServiceCard(
                    service: services[index],
                    onUpdate: refresh,
                  ),
                ),
        ),
      ],
    );
  }

  // ── Search results — full width, spans all categories ─────────────────
  Widget _buildSearchResults(
      List<SalonService> results, int totalItems, double bottomPad) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 44, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No services found for "${_searchQuery.trim()}"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Try a different keyword or category name',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          8, 4, 8, totalItems > 0 ? 68 + bottomPad + 10 : 10),
      itemCount: results.length,
      itemBuilder: (_, index) => SalonServiceCard(
        service: results[index],
        onUpdate: refresh,
        showCategory: true,
      ),
    );
  }
}