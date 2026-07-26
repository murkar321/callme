import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:callme/provider/service_provider_form.dart';
import 'package:callme/provider/provider_dashboard.dart';

// ⚠️ Adjust this import path if order_service.dart lives somewhere else
// in your project (e.g. package:callme/services/order_service.dart).
// We need categoryMatchFuzzy/providerCategories/providerSubCategories
// AND the OrderStatus constants from here so the badge count uses the
// EXACT SAME matching logic and status vocabulary as OrderService's
// fan-out and business_dashboard_page.dart's Available tab — otherwise
// "got notified" and "badge shows a number" can drift apart again,
// which was the original bug.
import 'package:callme/provider/order_service.dart';

// =====================================================
// CATEGORY MODEL
// =====================================================

class ServiceCategoryStyle {
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const ServiceCategoryStyle({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

// =====================================================
// SMALL RESPONSIVE HELPER (header / typography only —
// does NOT touch grid column count, aspect ratio, or the
// category sort order, all of which are left exactly as-is)
// =====================================================
class _Responsive {
  final double width;
  const _Responsive(this.width);

  bool get isTablet => width >= 600;
  bool get isLargeTablet => width >= 900;

  // Slightly taller so the redesigned header has room to breathe
  // without touching the grid/card layout below it.
  double get headerExpandedHeight {
    if (isLargeTablet) return 250;
    if (isTablet) return 228;
    return 214;
  }

  double get horizontalPagePadding {
    if (isLargeTablet) return 32;
    if (isTablet) return 24;
    return 16;
  }

  double get titleFontSize => isTablet ? 19 : 17;
  double get taglineFontSize => isTablet ? 14 : 13;
}

// =====================================================
// TINY REUSABLE "PRESS TO SHRINK" WRAPPER
// Adds a light, springy tactile animation to anything tappable
// without changing the tap logic itself — onTap still fires
// exactly as before, this just wraps the visuals.
// =====================================================
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;

  void _setScale(double s) => setState(() => _scale = s);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.94),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// =====================================================
// BUSINESS PAGE
// =====================================================

class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage>
    with TickerProviderStateMixin {

  // ── Firebase ──────────────────────────────────────
  User? get user => FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  // ── Location ──────────────────────────────────────
  String city = "";
  bool loadingLocation = true;

  // ── Stagger animation (grid cards) ────────────────
  late AnimationController _listController;

  // ── Header ambient animation (pastel blobs + sparkle) ──
  late AnimationController _headerController;

  // Rotating catchy taglines shown under the headline.
  static const List<String> _taglines = [
    "Turn your skills into steady income",
    "Your next customer is one tap away",
    "Set your hours. Set your rates. Get booked.",
    "Trusted by neighborhoods, powered by you",
  ];
  int _taglineIndex = 0;
  Timer? _taglineTimer;

  // NOTE: This page used to run its own separate FCM permission
  // request / token-save / foreground-listener block (`_setupFCM`).
  // That duplicated — and could race with — the single canonical
  // NotificationService already running app-wide (which saves tokens
  // to users/{uid}, users/{email} (back-compat), AND providers/{id},
  // and is what actually makes notifications ring on lock screen /
  // off-screen). Removed here so there's exactly one place doing FCM
  // setup, matching the project's "single source of truth" pattern.
  // If you were relying on the in-app SnackBar this page used to show
  // for foreground messages, NotificationService already shows a real
  // system-style local notification for those instead.

  // ── Categories (UNCHANGED — same 9 categories, same order) ──
  static const List<ServiceCategoryStyle> businessCategories = [
    ServiceCategoryStyle(
      name: 'Salon',
      icon: Icons.content_cut_rounded,
      iconColor: Color(0xFFE91E8C),
      iconBg: Color(0xFFFCE4F1),
    ),
    ServiceCategoryStyle(
      name: 'Educational Services',
      icon: Icons.menu_book_rounded,
      iconColor: Color(0xFF5C6BC0),
      iconBg: Color(0xFFE8EAF6),
    ),
    ServiceCategoryStyle(
      name: 'Cleaning',
      icon: Icons.cleaning_services_rounded,
      iconColor: Color(0xFF00897B),
      iconBg: Color(0xFFE0F2F1),
    ),
    ServiceCategoryStyle(
      name: 'Plumbing',
      icon: Icons.plumbing_rounded,
      iconColor: Color(0xFF0288D1),
      iconBg: Color(0xFFE1F5FE),
    ),
    ServiceCategoryStyle(
      name: 'Hotel',
      icon: Icons.hotel_rounded,
      iconColor: Color(0xFFF57C00),
      iconBg: Color(0xFFFFF3E0),
    ),
    ServiceCategoryStyle(
      name: 'Resort',
      icon: Icons.beach_access_rounded,
      iconColor: Color(0xFF2E7D32),
      iconBg: Color(0xFFE8F5E9),
    ),
    ServiceCategoryStyle(
      name: 'Laundry',
      icon: Icons.local_laundry_service_rounded,
      iconColor: Color(0xFF8E24AA),
      iconBg: Color(0xFFF3E5F5),
    ),
    ServiceCategoryStyle(
      name: 'Water',
      icon: Icons.water_drop_rounded,
      iconColor: Color(0xFF1976D2),
      iconBg: Color(0xFFE3F2FD),
    ),
    ServiceCategoryStyle(
      name: 'Civil',
      icon: Icons.construction_rounded,
      iconColor: Color(0xFFD84315),
      iconBg: Color(0xFFFBE9E7),
    ),
  ];

  // ── Init ──────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Slow, gentle infinite loop that drives the floating pastel
    // blobs + sparkle icon in the header. Purely decorative — no
    // business logic depends on this value.
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Rotates the header subtitle every few seconds for a livelier,
    // more "marketing" feel without needing any extra state elsewhere.
    _taglineTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _taglineIndex = (_taglineIndex + 1) % _taglines.length);
    });

    _getLocation();
  }

  @override
  void dispose() {
    _listController.dispose();
    _headerController.dispose();
    _taglineTimer?.cancel();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────
  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => loadingLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 8));
      final marks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        city = marks.first.locality ?? "";
        loadingLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingLocation = false);
    }
  }

  // ── Helpers ───────────────────────────────────────
  String normalize(String s) => s.trim().toLowerCase();

  String _getServiceType(String name) {
    if (name == "Educational Services") return "education";
    return normalize(name);
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError
                ? Icons.error_outline
                : isSuccess
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: isError
            ? const Color(0xFFD84315)
            : isSuccess
                ? const Color(0xFF388E3C)
                : const Color(0xFF37474F),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =====================================================
  // Badge / order-count logic — UNCHANGED from the working
  // fixed version: an order only counts if it is genuinely
  // new / unread / not yet accepted by anyone.
  // =====================================================
  Map<String, int> _computeOrderCounts(
    List<QueryDocumentSnapshot> orderDocs,
    Map<String, Map<String, dynamic>> providerMap,
  ) {
    final counts = <String, int>{};

    for (final doc in orderDocs) {
      final order = doc.data() as Map<String, dynamic>? ?? {};

      final status =
          (order['status'] ?? '').toString().toLowerCase().trim();
      final bool isAssigned = order['isAssigned'] == true;
      final bool reopened = order['reopenForOthers'] == true;

      final bool isUnreadAndOpen = !isAssigned &&
          (status == OrderStatus.pending ||
              status == OrderStatus.enquiry ||
              (status == OrderStatus.cancelled && reopened));

      if (!isUnreadAndOpen) continue; // accepted / in-progress / completed / firmly closed

      final orderServiceType =
          normalize((order['serviceType'] ?? '').toString());

      final provider = providerMap[orderServiceType];
      if (provider == null) continue; // not registered for this service

      final providerCats = providerCategories(provider);
      final providerSubCats = providerSubCategories(provider);
      final matches = categoryMatchFuzzy(
        order,
        providerCats,
        providerSubCats: providerSubCats,
        debugOrderId: '${doc.id} -> businessPage badge '
            '(${provider['providerId']})',
      );

      if (matches) {
        counts[orderServiceType] = (counts[orderServiceType] ?? 0) + 1;
      }
    }

    return counts;
  }

  // =====================================================
  // DYNAMIC ORDERING — UNCHANGED LOGIC
  // =====================================================
  List<int> _sortedIndices(
    Map<String, Map<String, dynamic>> providerMap,
    Map<String, int> orderCountMap,
  ) {
    final indices = List<int>.generate(businessCategories.length, (i) => i);

    int tierOf(int i) {
      final serviceType = _getServiceType(businessCategories[i].name);
      final hasOrders = (orderCountMap[serviceType] ?? 0) > 0;
      final isRegistered = providerMap.containsKey(serviceType);
      if (hasOrders) return 0; // top priority
      if (isRegistered) return 1; // registered, but quiet right now
      return 2; // untouched category
    }

    // Stable sort: within the same tier, original hardcoded order is
    // preserved (Dart's List.sort is not guaranteed stable, so we
    // decorate with the original index as a tiebreaker instead of
    // relying on sort stability).
    indices.sort((a, b) {
      final tierA = tierOf(a);
      final tierB = tierOf(b);
      if (tierA != tierB) return tierA.compareTo(tierB);

      if (tierA == 0) {
        // Within the "has active orders" tier, busiest first.
        final countA =
            orderCountMap[_getServiceType(businessCategories[a].name)] ?? 0;
        final countB =
            orderCountMap[_getServiceType(businessCategories[b].name)] ?? 0;
        if (countA != countB) return countB.compareTo(countA);
      }

      return a.compareTo(b); // tiebreaker — keeps original relative order
    });

    return indices;
  }

  // ── Tap handler (UNCHANGED LOGIC) ─────────────────
  void _handleTap(
      ServiceCategoryStyle service, Map<String, dynamic>? provider) {
    if (user == null) {
      _showSnack("Please login first to continue", isError: true);
      return;
    }
    if (provider == null) {
      _showProviderTypeSelector(service);
      return;
    }
    final status = provider['status'] ?? "pending";
    if (status == "pending") {
      _showSnack("⏳ Your application is under review. Please wait.");
      return;
    }
    if (status == "rejected") {
      _showRejectedDialog(
          service, provider['rejectReason'] ?? "No reason provided.");
      return;
    }
    if (status == "approved") {
      final serviceType = _getServiceType(service.name);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDashboardPage(
            providerId: provider['providerId'] ?? '',
            businessName:
                provider['business']?['businessName'] ?? "My Business",
            serviceType: serviceType,
          ),
        ),
      );
    }
  }

  // ── Rejected dialog (visual polish only — same behavior) ──
  void _showRejectedDialog(ServiceCategoryStyle service, String reason) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xFF232030) : Colors.white;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF212121);
    final Color bodyColor = isDark ? Colors.white70 : const Color(0xFF757575);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: dialogBg,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFD84315).withOpacity(0.18)
                      : const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.cancel_rounded,
                    color: Color(0xFFD84315), size: 30),
              ),
              const SizedBox(height: 16),
              Text("Application Rejected",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: titleColor)),
              const SizedBox(height: 8),
              Text(reason,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: bodyColor, height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text("Cancel",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF424242))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showProviderTypeSelector(service);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C6BC0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text("Reapply"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Provider type bottom sheet (visual polish only) ──
  void _showProviderTypeSelector(ServiceCategoryStyle service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF232030) : Colors.white;
    final Color handleColor =
        isDark ? Colors.white24 : const Color(0xFFE0E0E0);
    final Color eyebrowColor = isDark ? Colors.white54 : Colors.grey[500]!;
    final Color titleColor = isDark ? Colors.white : const Color(0xFF212121);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: sheetBg,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 40 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: service.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(service.icon, color: service.iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Register as",
                        style: TextStyle(
                            fontSize: 11,
                            color: eyebrowColor,
                            fontWeight: FontWeight.w500)),
                    Text(service.name,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: titleColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 28, color: isDark ? Colors.white12 : null),
            _typeTile(service, "Individual", Icons.person_rounded,
                const Color(0xFF5C6BC0), isDark),
            const SizedBox(height: 8),
            _typeTile(service, "Agency", Icons.groups_rounded,
                const Color(0xFF00897B), isDark),
            const SizedBox(height: 8),
            _typeTile(service, "Business", Icons.business_rounded,
                const Color(0xFFF57C00), isDark),
          ],
        ),
      ),
    );
  }

  Widget _typeTile(ServiceCategoryStyle service, String type, IconData icon,
      Color color, bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF2B2740) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceProviderForm(
                type: _getServiceType(service.name),
                providerType: type,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFF0F0F0)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Text(type,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF212121))),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : const Color(0xFFBDBDBD),
                  size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final r = _Responsive(size.width);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Real-device adaptivity: clamp the text scale so a phone with a
    // large system font/accessibility setting doesn't break the fixed
    // card layout below. Grid columns / aspect ratio are untouched —
    // this only protects text from overflowing inside them.
    final mq = MediaQuery.of(context);
    final clampedScaler =
        mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15);

    final Color pageBg = Theme.of(context).scaffoldBackgroundColor;
    final Color sectionTitleColor =
        isDark ? Colors.white : const Color(0xFF212121);
    final Color countChipBg =
        isDark ? const Color(0xFF5C6BC0).withOpacity(0.22) : const Color(0xFFE8EAF6);
    final Color countChipText =
        isDark ? const Color(0xFFB6C0F0) : const Color(0xFF5C6BC0);

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedScaler),
      child: Scaffold(
        backgroundColor: pageBg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: r.headerExpandedHeight,
              pinned: true,
              backgroundColor:
                  isDark ? const Color(0xFF2A2338) : const Color(0xFFFFE3EC),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              foregroundColor:
                  isDark ? Colors.white : const Color(0xFF3B2A4A),
              title: Text(
                "Become a Provider",
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF3B2A4A),
                  fontWeight: FontWeight.w700,
                  fontSize: r.titleFontSize,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(r, isDark),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    r.horizontalPagePadding, 20, r.horizontalPagePadding, 12),
                child: Row(
                  children: [
                    Text(
                      "Service Categories",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: sectionTitleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: countChipBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${businessCategories.length}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: countChipText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── GRID — column count, aspect ratio, spacing, and the
            // priority-sort logic below are all EXACTLY as before. ──
            if (user == null)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    r.horizontalPagePadding, 0, r.horizontalPagePadding, 24),
                sliver: _buildGridSliver({}, {}, size, isDark),
              )
            else
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("providers")
                      .where("userId", isEqualTo: user!.uid)
                      .snapshots(),
                  builder: (context, providerSnap) {
                    final Map<String, Map<String, dynamic>> providerMap = {};
                    if (providerSnap.hasData) {
                      for (var doc in providerSnap.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final type = normalize(data['serviceType'] ?? "");
                        providerMap[type] = {...data, 'providerId': doc.id};
                      }
                    }
                    // FIX: query now only pulls in statuses that can ever
                    // be "unread / not-yet-accepted" — pending, enquiry,
                    // and cancelled (checked for reopenForOthers
                    // client-side). Accepted / in-progress / completed
                    // orders are intentionally never fetched here, since
                    // they must never light up this badge again.
                    return StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection("orders")
                          .where("status", whereIn: [
                            OrderStatus.pending,
                            OrderStatus.enquiry,
                            OrderStatus.cancelled,
                          ])
                          .snapshots(),
                      builder: (context, orderSnap) {
                        final orderCountMap = orderSnap.hasData
                            ? _computeOrderCounts(
                                orderSnap.data!.docs, providerMap)
                            : <String, int>{};

                        return Padding(
                          padding: EdgeInsets.fromLTRB(r.horizontalPagePadding,
                              0, r.horizontalPagePadding, 32),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: businessCategories.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: size.width < 600 ? 2 : 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.05,
                            ),
                            itemBuilder: (_, gridPosition) {
                              // `gridPosition` is where in the grid we are
                              // rendering; `i` is which category from
                              // businessCategories actually goes there,
                              // resolved via the dynamic priority order.
                              final sorted =
                                  _sortedIndices(providerMap, orderCountMap);
                              final i = sorted[gridPosition];
                              return _buildCard(i, gridPosition, providerMap,
                                  orderCountMap, isDark);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // HEADER — pastel in light mode, deepened/muted glass panel in
  // dark mode so it doesn't glow against a dark scaffold. Layout,
  // blob animation, and sparkle are all untouched — only colors flip.
  // =====================================================
  Widget _buildHeader(_Responsive r, bool isDark) {
    final Color headlineColor = isDark ? Colors.white : const Color(0xFF3B2A4A);
    final Color taglineColor = isDark
        ? Colors.white70
        : const Color(0xFF3B2A4A).withOpacity(0.65);
    final Color chipBg = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.55);
    final Color chipBorder = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.white.withOpacity(0.8);
    final Color pinColor = isDark ? const Color(0xFFE39CC2) : const Color(0xFFB05A8C);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base panel — soft pastel gradient in light mode, deepened
          // muted-purple gradient in dark mode (same hues, dropped
          // lightness), matching the pattern already used elsewhere
          // in the app (see AccountPage's _pastelPaletteDark).
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [
                        Color(0xFF3A2438), // muted blush
                        Color(0xFF2B2440), // muted lilac
                        Color(0xFF1E3A32), // muted mint
                      ]
                    : const [
                        Color(0xFFFFE3EC), // blush pink
                        Color(0xFFF1E6FF), // soft lilac
                        Color(0xFFE1F7EE), // pale mint
                      ],
              ),
            ),
          ),

          // Ambient drifting blobs — purely decorative, looped by
          // _headerController. Positions are computed from a simple
          // sine/cosine so they glide smoothly instead of teleporting.
          AnimatedBuilder(
            animation: _headerController,
            builder: (context, _) {
              final t = _headerController.value * 2 * math.pi;
              final opacityMul = isDark ? 0.6 : 1.0;
              return Stack(
                children: [
                  Positioned(
                    top: -50 + math.sin(t) * 14,
                    right: -30 + math.cos(t) * 10,
                    child: _blob(170, const Color(0xFFFFB6C1), 0.45 * opacityMul),
                  ),
                  Positioned(
                    bottom: -60 + math.cos(t) * 12,
                    left: -40 + math.sin(t) * 10,
                    child: _blob(190, const Color(0xFFB39DDB), 0.35 * opacityMul),
                  ),
                  Positioned(
                    top: 30 + math.sin(t + 1.2) * 8,
                    left: size_safe(r) * 0.55,
                    child: _blob(90, const Color(0xFFA5D6C6), 0.4 * opacityMul),
                  ),
                ],
              );
            },
          ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
                r.horizontalPagePadding, 0, r.horizontalPagePadding, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline row with a gently rotating/pulsing sparkle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Grow your business\nwith CallMe",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.taglineFontSize + 5,
                          fontWeight: FontWeight.w800,
                          color: headlineColor,
                          height: 1.18,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _headerController,
                      builder: (context, _) {
                        final t = _headerController.value * 2 * math.pi;
                        final pulse = 1.0 + 0.12 * math.sin(t * 2);
                        return Transform.rotate(
                          angle: math.sin(t) * 0.25,
                          child: Transform.scale(
                            scale: pulse,
                            child: const Text("✨", style: TextStyle(fontSize: 22)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Rotating catchy subtitle — smooth crossfade
                SizedBox(
                  height: 18,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _taglines[_taglineIndex],
                      key: ValueKey(_taglineIndex),
                      style: TextStyle(
                        fontSize: r.taglineFontSize,
                        color: taglineColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Location chip — frosted glass, adapts to light/dark panel
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: chipBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        loadingLocation
                            ? Icons.location_searching_rounded
                            : Icons.location_on_rounded,
                        color: pinColor,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loadingLocation
                            ? "Detecting location..."
                            : city.isNotEmpty
                                ? city
                                : "Location unavailable",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: headlineColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Small helper so the third blob's horizontal position can react to
  // the available header width without threading MediaQuery through
  // _buildHeader's signature.
  double size_safe(_Responsive r) {
    final width = MediaQuery.of(context).size.width;
    return width;
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  // Grid delegate values (crossAxisCount / spacing / aspect ratio) and
  // the priority-sort order are exactly as before — only used for the
  // guest (logged-out) view.
  SliverGrid _buildGridSliver(
    Map<String, Map<String, dynamic>> providerMap,
    Map<String, int> orderCountMap,
    Size size,
    bool isDark,
  ) {
    final sorted = _sortedIndices(providerMap, orderCountMap);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size.width < 600 ? 2 : 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, gridPosition) => _buildCard(sorted[gridPosition], gridPosition,
            providerMap, orderCountMap, isDark),
        childCount: businessCategories.length,
      ),
    );
  }

  Widget _buildCard(
    int i,
    int gridPosition,
    Map<String, Map<String, dynamic>> providerMap,
    Map<String, int> orderCountMap,
    bool isDark,
  ) {
    final category = businessCategories[i];
    final serviceType = _getServiceType(category.name);
    final provider = providerMap[serviceType];
    final count = orderCountMap[serviceType] ?? 0;
    final status = provider?['status'];

    final Color cardBg = isDark ? const Color(0xFF232030) : Colors.white;
    final Color cardBorder =
        isDark ? Colors.white12 : const Color(0xFFF0F0F0);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF212121);
    final Color registerColor = isDark ? Colors.white38 : const Color(0xFF9E9E9E);
    final Color registerIconColor = isDark ? Colors.white38 : const Color(0xFFBDBDBD);

    // NOTE: the stagger-in animation delay is keyed off `gridPosition`
    // (where the card actually lands on screen) instead of `i` (which
    // category it is), so cards still cascade in top-left-to-bottom-right
    // regardless of how _sortedIndices() reordered them.
    final delay = gridPosition * 0.05;
    final animation = CurvedAnimation(
      parent: _listController,
      curve: Interval(delay.clamp(0.0, 0.8), 1.0,
          curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - animation.value)),
          child: child,
        ),
      ),
      // Card now uses _PressableScale so tapping gives a light,
      // springy "shrink and bounce back" tactile response — the
      // actual onTap logic (_handleTap) is completely unchanged.
      child: _PressableScale(
        onTap: () => _handleTap(category, provider),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? category.iconColor.withOpacity(0.18)
                            : category.iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(category.icon,
                          color: category.iconColor, size: 26),
                    ),
                    const Spacer(),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (status != null)
                      _statusPill(status, isDark)
                    else
                      Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 12, color: registerIconColor),
                          const SizedBox(width: 4),
                          Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 11,
                              color: registerColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (count > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _PulsingBadge(
                    color: category.iconColor,
                    label: count > 99 ? "99+" : "$count",
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status, bool isDark) {
    late Color color;
    late Color bg;
    late String label;
    late IconData icon;

    switch (status) {
      case "approved":
        color = const Color(0xFF2E7D32);
        bg = isDark
            ? const Color(0xFF2E7D32).withOpacity(0.18)
            : const Color(0xFFE8F5E9);
        label = "Active";
        icon = Icons.check_circle_rounded;
        break;
      case "pending":
        color = const Color(0xFFE65100);
        bg = isDark
            ? const Color(0xFFE65100).withOpacity(0.18)
            : const Color(0xFFFFF3E0);
        label = "Pending";
        icon = Icons.hourglass_top_rounded;
        break;
      case "rejected":
        color = const Color(0xFFD84315);
        bg = isDark
            ? const Color(0xFFD84315).withOpacity(0.18)
            : const Color(0xFFFBE9E7);
        label = "Rejected";
        icon = Icons.cancel_rounded;
        break;
      default:
        color = isDark ? Colors.white60 : const Color(0xFF757575);
        bg = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF5F5F5);
        label = status;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// Small self-contained "new orders" badge that softly pulses
// so a fresh/unread count actually catches the eye instead of
// sitting there as a static number. Purely visual — the count
// value and when it appears/disappears are still driven entirely
// by _computeOrderCounts() in the page above. Badge color is the
// category accent, which already has good contrast in both themes.
// =====================================================
class _PulsingBadge extends StatefulWidget {
  final Color color;
  final String label;
  const _PulsingBadge({required this.color, required this.label});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.12);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 22),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}