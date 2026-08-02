import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import '../widgets/hotel_card.dart';

class HotelServicePage extends StatefulWidget {
  const HotelServicePage({super.key});

  @override
  State<HotelServicePage> createState() => _HotelServicePageState();
}

class _HotelServicePageState extends State<HotelServicePage> {
  final TextEditingController searchController = TextEditingController();
  String selectedCity = "All";

  // ══════════════════════════════════════════════════════════════════
  // FIX (DARK THEME): same root cause as the other hotel pages — every
  // color here was a hardcoded light-mode value (Colors.grey.shade100,
  // Colors.white, Colors.black87, ...), so the page never looked at
  // Theme.of(context).brightness and always rendered light regardless
  // of the app's theme mode. These getters make the search bar, city
  // chips, and empty state adapt. The red app bar / selected-chip color
  // is a brand accent and is left unchanged — it reads fine in both
  // themes.
  // ══════════════════════════════════════════════════════════════════
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg =>
      _isDark ? const Color(0xFF121016) : Colors.grey.shade100;
  Color get _cardBg =>
      _isDark ? const Color(0xFF1E1B27) : Colors.white;
  Color get _textHigh =>
      _isDark ? Colors.white : Colors.black87;
  Color get _textMid =>
      _isDark ? Colors.white70 : Colors.grey.shade700;
  Color get _textLow =>
      _isDark ? Colors.white54 : Colors.grey.shade600;
  Color get _textFainter =>
      _isDark ? Colors.white24 : Colors.grey.shade400;
  Color get _divider =>
      _isDark ? Colors.white24 : Colors.grey.shade300;

  List<String> get cities {
    final list = hotels.map((e) => e.city).toSet().toList();
    list.sort();
    return ["All", ...list];
  }

  List<HotelData> get filtered {
    final searchText = searchController.text.trim().toLowerCase();
    return hotels.where((hotel) {
      final matchCity = selectedCity == "All" || hotel.city == selectedCity;
      final matchSearch =
          hotel.name.toLowerCase().contains(searchText) ||
          hotel.city.toLowerCase().contains(searchText);
      return matchCity && matchSearch;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX (DARK THEME): was Colors.grey.shade100.
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.red,
        title: const Text(
          "Hotels",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [

            /// ── SEARCH BAR ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  // FIX (DARK THEME): was Colors.white.
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  // FIX (DARK THEME): input text itself had no explicit
                  // color, so it would default to black on a dark field.
                  style: TextStyle(color: _textHigh),
                  decoration: InputDecoration(
                    hintText: "Search hotels or city...",
                    // FIX (DARK THEME): was Colors.grey.shade500.
                    hintStyle: TextStyle(color: _textLow),
                    // FIX (DARK THEME): dropped `const`, gave the icon an
                    // explicit adaptive color instead of the default
                    // (theme-dependent) icon color.
                    prefixIcon: Icon(Icons.search, color: _textLow),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            /// ── CITY FILTER CHIPS ──
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: cities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final isSelected = selectedCity == city;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCity = city),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        // FIX (DARK THEME): unselected chip was
                        // Colors.white.
                        color: isSelected ? Colors.red : _cardBg,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          // FIX (DARK THEME): was Colors.grey.shade300.
                          color: isSelected ? Colors.red : _divider,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          city,
                          style: TextStyle(
                            // FIX (DARK THEME): unselected text was
                            // Colors.black87.
                            color: isSelected ? Colors.white : _textHigh,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            /// ── HOTEL LIST ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // FIX (DARK THEME): was Colors.grey.shade400.
                          Icon(Icons.hotel,
                              size: 75, color: _textFainter),
                          const SizedBox(height: 14),
                          Text(
                            "No hotels available",
                            // FIX (DARK THEME): was Colors.grey.shade700.
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textMid,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Try another search or city",
                            // FIX (DARK THEME): was Colors.grey.shade600.
                            style: TextStyle(color: _textLow),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20, top: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        return HotelCard(hotel: filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}