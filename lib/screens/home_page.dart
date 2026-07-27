// lib/screens/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:callme/models/service_category.dart';
import 'package:callme/widgets/category_card.dart';
import 'package:callme/profile/notification_page.dart';

import 'package:callme/screens/universal_services_page.dart';
import 'package:callme/screens/salon_page.dart';
import 'package:callme/models/hotel_service_page.dart';
import 'package:callme/models/civil_services_page.dart';
import 'package:callme/screens/resort_page.dart';
import 'package:callme/screens/laundry_service_page.dart';
import 'package:callme/screens/education_services_page.dart';

// ── Theme-aware brand palette ───────────────────────────────────────────────
// These used to be flat `const Color` values, which is exactly why this page
// stayed light even after switching to dark mode. They're now small helper
// functions keyed off Theme.of(context).brightness, so every widget that
// calls them automatically follows whatever ThemeMode SettingsController is
// currently set to — no per-widget wiring needed beyond calling the helper.
Color _bgTop(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B1922)
        : const Color(0xFFFDFBFF);

Color _bgBottom(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121016)
        : const Color(0xFFF1EEFF);

// Brand indigo reads fine on both light and dark backgrounds, so it stays
// constant — only the neutrals (backgrounds/text) need to flip.
const Color _kPrimary = Color(0xFF6C5CE7);
const Color _kAccentPink = Color(0xFFFF8FAB);

Color _primaryDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF3A2E5C);

Color _mutedLabel(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF3A2E5C).withOpacity(0.65);

Color _surfaceCard(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF232030)
        : Colors.white;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  // Using a ValueNotifier instead of setState-on-every-scroll-pixel keeps
  // the rest of the page (AppBar, StreamBuilder, grid/list) from rebuilding
  // on every frame of the scroll — this is what was causing jank on Android.
  final ValueNotifier<double> _offsetNotifier = ValueNotifier<double>(0.0);

  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();

  final List<ServiceCategory> categories = [
    ServiceCategory(name: 'Education', imagePath: 'assets/Education.jpg'),
    ServiceCategory(name: 'Salon', imagePath: 'assets/salon.png'),
    ServiceCategory(name: 'Cleaning', imagePath: 'assets/cleaning.jpg'),
    ServiceCategory(name: 'Resorts', imagePath: 'assets/resort.jpg'),
    ServiceCategory(name: 'Plumbing', imagePath: 'assets/plumbing.jpg'),
    ServiceCategory(name: 'Laundry', imagePath: 'assets/laundary.jpg'),
    ServiceCategory(name: 'Hotel', imagePath: 'assets/hotel.jfif'),
    ServiceCategory(name: 'Water', imagePath: 'assets/water services.jpeg'),
    ServiceCategory(name: 'Civil Services', imagePath: 'assets/civil.jpeg'),
  ];

  /// Service-specific icon map. Used as fallback icon on failed image
  /// loads, and as the badge icon on vertical cards.
  static const Map<String, IconData> _categoryIcons = {
    'Education': Icons.school_rounded,
    'Salon': Icons.content_cut_rounded,
    'Cleaning': Icons.cleaning_services_rounded,
    'Resorts': Icons.beach_access_rounded,
    'Plumbing': Icons.plumbing_rounded,
    'Laundry': Icons.local_laundry_service_rounded,
    'Hotel': Icons.hotel_rounded,
    'Water': Icons.water_drop_rounded,
    'Civil Services': Icons.engineering_rounded,
  };

  IconData _iconFor(String name) =>
      _categoryIcons[name] ?? Icons.miscellaneous_services_rounded;

  String searchQuery = '';
  String selectedCategory = '';

  List<ServiceCategory> get filteredCategories {
    return categories.where((category) {
      final matchesSearch = category.name
          .toLowerCase()
          .contains(searchQuery.toLowerCase().trim());
      final matchesSelected =
          selectedCategory.isEmpty || category.name == selectedCategory;
      return matchesSearch && matchesSelected;
    }).toList();
  }

  List<ServiceCategory> get filteredHorizontal {
    return categories.where((category) {
      return category.name
          .toLowerCase()
          .contains(searchQuery.toLowerCase().trim());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    // Only updates the ValueNotifier — no setState() here, so the page
    // doesn't rebuild on every scroll frame. Only widgets that actually
    // listen to _offsetNotifier (the chip scale animation) rebuild.
    _scrollController.addListener(() {
      _offsetNotifier.value = _scrollController.offset;
    });
    Future.delayed(const Duration(milliseconds: 500), autoScroll);
    _searchController.addListener(() {
      // Rebuild so the live tagline hides/shows as the user types.
      if (mounted) setState(() {});
    });
  }

  void autoScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    double next = _scrollController.offset + 120;
    if (next >= max) next = 0;
    _scrollController.animateTo(
      next,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(seconds: 4), autoScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _offsetNotifier.dispose();
    super.dispose();
  }

  // ── Fetch the first active salon provider ID from Firestore ──────────────
  Future<String> _fetchSalonProviderId() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('providers')
          .where('serviceType', isEqualTo: 'salon')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) return snap.docs.first.id;
    } catch (_) {}
    return ''; // fallback — SalonBookingPage will show error if still empty
  }

  // ── Navigate to the correct page for each service ────────────────────────
  // Used by BOTH the horizontal quick-pick chips and the vertical
  // "Explore services" list/grid, so tapping a category always lands on
  // the exact same destination page regardless of which section it was
  // tapped from.
  Future<void> _navigateToService(String serviceName) async {
    Widget page;

    if (serviceName == 'Salon') {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final providerId = await _fetchSalonProviderId();

      if (!mounted) return;
      Navigator.pop(context); // dismiss loader

      page = SalonPage(providerId: providerId);
    } else {
      page = _getStaticPage(serviceName);
    }

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // ── All non-Salon pages (no async needed) ────────────────────────────────
  Widget _getStaticPage(String serviceName) {
    switch (serviceName.trim()) {
      case 'Cleaning':
      case 'Plumbing':
      case 'Water':
        return UniversalServicesPage(serviceName: serviceName);
      case 'Laundry':
        return const LaundryServicePage();
      case 'Resorts':
        return const ResortPage(resorts: []);
      case 'Hotel':
        return const HotelServicePage();
      case 'Civil Services':
        return const CivilServicesPage();
      case 'Education':
        return const EducationServicesPage();
      default:
        return UniversalServicesPage(serviceName: serviceName);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  Stream<int> get _unreadCountStream {
    if (_uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isSmallPhone = screenWidth < 340;
    final chipWidth = (screenWidth / (isTablet ? 7 : 4)).clamp(
      isSmallPhone ? 76.0 : 84.0,
      130.0,
    );
    final textScaler = MediaQuery.of(context).textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
        );

    // Theme-driven values computed once per build — this is what makes the
    // page actually flip dark instead of only the bottom nav bar doing so.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryDark = _primaryDark(context);
    final Color mutedLabel = _mutedLabel(context);
    final Color appBarBg = _surfaceCard(context);
    final Color bellIconBg = _kPrimary.withOpacity(isDark ? 0.18 : 0.08);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          // 🔹 Logo only — icon + "Callme Services" text removed.
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Image.asset(
              'assets/logo.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                'Callme Services',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: primaryDark,
                ),
              ),
            ),
          ),
          centerTitle: true,
          backgroundColor: appBarBg,
          foregroundColor: primaryDark,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: StreamBuilder<int>(
                stream: _unreadCountStream,
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: bellIconBg,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_rounded,
                              size: 26, color: _kPrimary),
                          onPressed: _openNotifications,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
                              decoration: BoxDecoration(
                                color: _kAccentPink,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: appBarBg, width: 1.5),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop(context), _bgBottom(context)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 14,
                vertical: 12,
              ),
              child: Column(
                children: [
                  // 🔍 LIVE SEARCH BAR
                  _LiveSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        selectedCategory = '';
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Section label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Quick pick',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: mutedLabel,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // 🔹 HORIZONTAL SCROLL
                  // Height bumped up a bit + FittedBox inside CategoryCard
                  // guarantees this never overflows, even with larger
                  // system font scaling.
                  //
                  // Tapping a chip navigates straight to that service's
                  // page via `_navigateToService` — the SAME function the
                  // vertical list below uses, so both sections always
                  // land on the identical destination page for a given
                  // category. It also updates `selectedCategory` first
                  // (so the vertical list stays filtered/highlighted if
                  // the user backs out of the pushed page).
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredHorizontal.length,
                      itemBuilder: (context, index) {
                        final category = filteredHorizontal[index];
                        final isSelected = selectedCategory == category.name;
                        final width = chipWidth + 12;

                        // Only this single chip rebuilds when the scroll
                        // offset changes — not the whole page.
                        return ValueListenableBuilder<double>(
                          valueListenable: _offsetNotifier,
                          builder: (context, offset, child) {
                            final scale = 1 -
                                (((offset / width) - index).abs() * 0.18)
                                    .clamp(0.0, 0.18);
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: CategoryCard(
                              name: category.name,
                              imagePath: category.imagePath,
                              icon: _iconFor(category.name),
                              showName: true,
                              cardWidth: chipWidth,
                              onTap: () {
                                setState(() {
                                  selectedCategory =
                                      isSelected ? '' : category.name;
                                });
                                _navigateToService(category.name);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Explore services',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: mutedLabel,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // 🔹 VERTICAL LIST / GRID (adaptive: grid on wide screens)
                  // Same `_navigateToService(category.name)` call as the
                  // horizontal chips above — tapping "Salon" here fetches
                  // the provider and opens SalonPage; any other category
                  // opens its matching static page. Identical destination
                  // to tapping the same category as a chip.
                  Expanded(
                    child: isTablet
                        ? GridView.builder(
                            itemCount: filteredCategories.length,
                            padding: const EdgeInsets.only(bottom: 12),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 380,
                              mainAxisExtent: 150,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              return CategoryCard(
                                name: category.name,
                                imagePath: category.imagePath,
                                icon: _iconFor(category.name),
                                showName: false,
                                onTap: () => _navigateToService(category.name),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: filteredCategories.length,
                            padding: const EdgeInsets.only(bottom: 12),
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: CategoryCard(
                                  name: category.name,
                                  imagePath: category.imagePath,
                                  icon: _iconFor(category.name),
                                  showName: false,
                                  onTap: () =>
                                      _navigateToService(category.name),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Live typewriter search bar ──────────────────────────────────────────────
// Shows a pastel search field. When empty, an animated typewriter caption
// cycles through catchlines about the app; disappears the moment the user
// types, and reappears if they clear the field.
class _LiveSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _LiveSearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_LiveSearchBar> createState() => _LiveSearchBarState();
}

class _LiveSearchBarState extends State<_LiveSearchBar> {
  static const List<String> _taglines = [
    'Find trusted salons near you...',
    'Book plumbers in minutes...',
    'Explore top-rated stays...',
    'Home services, simplified...',
    'One app, every service you need...',
    'Reliable help, right around the corner...',
  ];

  Timer? _timer;
  int _phraseIndex = 0;
  int _charCount = 0;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 65), (timer) {
      if (!mounted) return;
      final phrase = _taglines[_phraseIndex];

      setState(() {
        if (!_deleting) {
          if (_charCount < phrase.length) {
            _charCount++;
          } else {
            _deleting = true;
            _timer?.cancel();
            _timer = Timer(const Duration(milliseconds: 1400), () {
              _deleting = true;
              _startTyping();
            });
          }
        } else {
          if (_charCount > 0) {
            _charCount--;
          } else {
            _deleting = false;
            _phraseIndex = (_phraseIndex + 1) % _taglines.length;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTagline = widget.controller.text.isEmpty;
    final visibleText = _taglines[_phraseIndex].substring(0, _charCount);

    final Color fieldBg = _surfaceCard(context);
    final Color textColor = _primaryDark(context);
    final Color taglineColor = _mutedLabel(context);

    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: showTagline ? '' : 'Search for a service...',
              hintStyle: TextStyle(color: taglineColor),
              prefixIcon: const Icon(Icons.search, color: _kPrimary),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (showTagline)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: IgnorePointer(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        visibleText,
                        style: TextStyle(
                          color: taglineColor,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        maxLines: 1,
                      ),
                    ),
                    // simple blinking cursor for the "live" feel
                    const _BlinkingCursor(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 16,
        margin: const EdgeInsets.only(left: 2),
        color: _kPrimary.withOpacity(0.6),
      ),
    );
  }
}