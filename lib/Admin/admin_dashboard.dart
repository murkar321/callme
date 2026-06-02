import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'approve_providers_page.dart';
import 'orders_detail.dart';
import 'providers_details.dart';
import 'users_details.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = true;

  Map<String, dynamic> dashboardData = {
    "users":     0,
    "providers": 0,
    "orders":    0,
    "approvals": 0,
    "pending":   0,
    "accepted":  0,
    "completed": 0,
    "rejected":  0,
  };

  // In-app banner for new provider — shown at top
  String? _newProviderBanner;

  // Real-time stream subscription for new pending providers
  StreamSubscription<QuerySnapshot>? _providerSub;

  // Track seen provider IDs so we don't re-notify on hot restart
  final Set<String> _notifiedProviderIds = {};

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    _saveAdminFcmToken();
    loadDashboard();
    _listenForNewProviders();
  }

  @override
  void dispose() {
    _providerSub?.cancel();
    super.dispose();
  }

  // =====================================================
  // SAVE ADMIN FCM TOKEN
  // Run every time admin opens the dashboard so the token
  // stays fresh. Stored at admin_config/fcm → { token }.
  // =====================================================

  Future<void> _saveAdminFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _db.doc("admin_config/fcm").set({
        "token":     token,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("Admin FCM token saved: $token");

      // Also refresh when token rotates
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _db.doc("admin_config/fcm").set({
          "token":     newToken,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("FCM TOKEN SAVE ERROR: $e");
    }
  }

  // =====================================================
  // LISTEN FOR NEW PROVIDERS (real-time)
  // Watches "pending" providers. When a NEW doc appears
  // that we haven't notified about yet:
  //   1. Show in-app banner
  //   2. Queue FCM push to admin_config/fcm token
  //   3. Save in-app notification record
  //   4. Refresh dashboard counts
  // =====================================================

  void _listenForNewProviders() {
    _providerSub = _db
        .collection("providers")
        .where("status", isEqualTo: "pending")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .listen((snapshot) async {
      // Seed known IDs on first snapshot so we don't spam
      // on initial load — only react to genuinely new docs
      if (_notifiedProviderIds.isEmpty && snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          _notifiedProviderIds.add(doc.id);
        }
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final doc  = change.doc;
        final id   = doc.id;
        final data = doc.data() ?? {};

        if (_notifiedProviderIds.contains(id)) continue;
        _notifiedProviderIds.add(id);

        final business    = (data["business"]  as Map<String, dynamic>?) ?? {};
        final businessName = (business["businessName"] ?? "A provider").toString();
        final ownerName    = (business["ownerName"]    ?? "").toString();
        final serviceType  = (data["serviceType"]      ?? "service").toString();
        final phone        = (business["phone"]        ?? "").toString();

        const String title = "🆕 New Provider Registration";
        final String body  =
            "$businessName by $ownerName registered as a "
            "$serviceType provider and is awaiting approval.";

        // 1 — Show banner inside the app
        if (mounted) {
          setState(() => _newProviderBanner =
              "$businessName registered — tap Approvals to review");

          // Auto-dismiss after 6 seconds
          Future.delayed(const Duration(seconds: 6), () {
            if (mounted) setState(() => _newProviderBanner = null);
          });
        }

        // 2 — In-app notification record
        await _db.collection("notifications").add({
          "userType":     "admin",
          "providerId":   id,
          "businessName": businessName,
          "ownerName":    ownerName,
          "phone":        phone,
          "serviceType":  serviceType,
          "title":        title,
          "body":         body,
          "type":         "new_provider_registration",
          "read":         false,
          "createdAt":    FieldValue.serverTimestamp(),
        });

        // 3 — Queue FCM push to admin device
        await _queueAdminFcm(
          title:        title,
          body:         body,
          type:         "new_provider_registration",
          providerId:   id,
          businessName: businessName,
          ownerName:    ownerName,
          serviceType:  serviceType,
          phone:        phone,
        );

        // 4 — Refresh counts
        loadDashboard();
      }
    }, onError: (e) {
      debugPrint("PROVIDER LISTENER ERROR: $e");
    });
  }

  // =====================================================
  // QUEUE FCM TO ADMIN
  // Reads admin token from admin_config/fcm and writes
  // to fcm_queue. Cloud Function delivers the push.
  // =====================================================

  Future<void> _queueAdminFcm({
    required String title,
    required String body,
    required String type,
    required String providerId,
    required String businessName,
    required String ownerName,
    required String serviceType,
    required String phone,
  }) async {
    try {
      final configDoc = await _db.doc("admin_config/fcm").get();
      final adminToken =
          (configDoc.data()?["token"] ?? "").toString().trim();

      if (adminToken.isEmpty) {
        debugPrint("Admin FCM token not set — skipping push");
        return;
      }

      await _db.collection("fcm_queue").add({
        "token":        adminToken,
        "title":        title,
        "body":         body,
        "type":         type,
        "providerId":   providerId,
        "businessName": businessName,
        "ownerName":    ownerName,
        "serviceType":  serviceType,
        "phone":        phone,
        "sent":         false,
        "createdAt":    FieldValue.serverTimestamp(),
      });

      debugPrint("Admin FCM queued for: $businessName");
    } catch (e) {
      debugPrint("ADMIN FCM QUEUE ERROR: $e");
    }
  }

  // =====================================================
  // LOAD DASHBOARD
  // =====================================================

  Future<void> loadDashboard() async {
    try {
      if (mounted) setState(() => isLoading = true);

      final usersSnap = await _db.collection("users").count().get();
      final providersSnap = await _db.collection("providers").count().get();
      final approvalsSnap = await _db
          .collection("providers")
          .where("status", isEqualTo: "pending")
          .count()
          .get();

      final ordersSnap = await _db.collection("orders").get();

      int pending = 0, accepted = 0, completed = 0, rejected = 0;
      for (final doc in ordersSnap.docs) {
        final status =
            (doc.data()['status'] ?? "pending").toString().toLowerCase();
        switch (status) {
          case "accepted":  accepted++;  break;
          case "completed": completed++; break;
          case "rejected":  rejected++;  break;
          default:          pending++;
        }
      }

      if (mounted) {
        setState(() {
          dashboardData = {
            "users":     usersSnap.count     ?? 0,
            "providers": providersSnap.count ?? 0,
            "orders":    ordersSnap.docs.length,
            "approvals": approvalsSnap.count ?? 0,
            "pending":   pending,
            "accepted":  accepted,
            "completed": completed,
            "rejected":  rejected,
          };
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final size     = MediaQuery.of(context).size;
    final isMobile = size.width < 700;

    final int pending   = dashboardData['pending'];
    final int accepted  = dashboardData['accepted'];
    final int completed = dashboardData['completed'];
    final int rejected  = dashboardData['rejected'];
    final int maxValue  =
        [pending, accepted, completed, rejected]
            .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── HERO HEADER ──────────────────────────

                      _buildHeroHeader(isMobile, pending),

                      // ── NEW PROVIDER BANNER ──────────────────
                      // Appears below header when a provider registers

                      if (_newProviderBanner != null)
                        _buildNewProviderBanner(),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            _sectionLabel("Overview"),
                            const SizedBox(height: 14),

                            GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:   isMobile ? 2 : 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing:  12,
                                childAspectRatio: isMobile ? 1.1 : 1.2,
                              ),
                              children: [
                                _statCard(context,
                                    title: "Users",
                                    icon:  Icons.people_alt_rounded,
                                    count: dashboardData['users'],
                                    color: const Color(0xFF3B82F6),
                                    page:  UsersPage(),
                                    trend: "+12%",
                                    trendUp: true),
                                _statCard(context,
                                    title: "Providers",
                                    icon:  Icons.storefront_rounded,
                                    count: dashboardData['providers'],
                                    color: const Color(0xFF10B981),
                                    page:  ProvidersPage(),
                                    trend: "+5%",
                                    trendUp: true),
                                _statCard(context,
                                    title: "Orders",
                                    icon:  Icons.receipt_long_rounded,
                                    count: dashboardData['orders'],
                                    color: const Color(0xFFF59E0B),
                                    page:  const AdminOrdersPage(),
                                    trend: "+8%",
                                    trendUp: true),
                                _statCard(context,
                                    title:   "Approvals",
                                    icon:    Icons.pending_actions_rounded,
                                    count:   dashboardData['approvals'],
                                    color:   const Color(0xFFEF4444),
                                    page:    const ApproveProvidersPage(),
                                    trend:   "${dashboardData['approvals']} new",
                                    trendUp: false),
                              ],
                            ),

                            const SizedBox(height: 30),

                            _sectionLabel("Order Status Breakdown"),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                _statusPill("Pending",  pending,   const Color(0xFFF59E0B)),
                                const SizedBox(width: 10),
                                _statusPill("Accepted", accepted,  const Color(0xFF10B981)),
                                const SizedBox(width: 10),
                                _statusPill("Done",     completed, const Color(0xFF3B82F6)),
                                const SizedBox(width: 10),
                                _statusPill("Rejected", rejected,  const Color(0xFFEF4444)),
                              ],
                            ),

                            const SizedBox(height: 28),

                            _buildChart(isMobile, maxValue,
                                pending, accepted, completed, rejected),

                            const SizedBox(height: 30),

                            _sectionLabel("Quick Actions"),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(child: _actionButton(context,
                                    label: "Manage Users",
                                    icon:  Icons.manage_accounts_rounded,
                                    color: const Color(0xFF3B82F6),
                                    page:  UsersPage())),
                                const SizedBox(width: 12),
                                Expanded(child: _actionButton(context,
                                    label: "View Orders",
                                    icon:  Icons.list_alt_rounded,
                                    color: const Color(0xFFF59E0B),
                                    page:  const AdminOrdersPage())),
                                const SizedBox(width: 12),
                                Expanded(child: _actionButton(context,
                                    label: "Approvals",
                                    icon:  Icons.verified_rounded,
                                    color: const Color(0xFFEF4444),
                                    page:  const ApproveProvidersPage())),
                              ],
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // =====================================================
  // NEW PROVIDER BANNER (animated, auto-dismisses)
  // =====================================================

  Widget _buildNewProviderBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve:    Curves.easeOut,
      margin:   const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(.12),
            blurRadius: 16,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing dot
          Container(
            width:  10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          const Icon(Icons.person_add_rounded,
              color: Colors.white70, size: 20),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "New Provider Registered",
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize:   13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _newProviderBanner ?? "",
                  style: const TextStyle(
                    color:    Colors.white60,
                    fontSize: 12,
                  ),
                  maxLines:  1,
                  overflow:  TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Go to Approvals
          GestureDetector(
            onTap: () {
              setState(() => _newProviderBanner = null);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ApproveProvidersPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:        const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Review",
                style: TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize:   12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // HERO HEADER
  // =====================================================

  Widget _buildHeroHeader(bool isMobile, int pending) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF6D28D9)],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── PENDING ORDERS ALERT ───────────────────────

          if (pending > 0)
            Container(
              width:   double.infinity,
              margin:  const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:  Colors.orange.withOpacity(0.25),
                      shape:  BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.orange,
                      size:  18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "$pending pending order${pending == 1 ? '' : 's'} require your attention",
                      style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize:   13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$pending",
                      style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize:   12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── TITLE + REFRESH ───────────────────────────

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color:        Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size:  26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Admin Dashboard",
                        style: TextStyle(
                          color:      Colors.white,
                          fontSize:   22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Manage your platform",
                        style: TextStyle(
                            color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Notification bell with approval badge
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ApproveProvidersPage()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color:        Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Colors.white,
                          size:  20,
                        ),
                      ),
                    ),
                    if ((dashboardData['approvals'] ?? 0) > 0)
                      Positioned(
                        top:   0,
                        right: 0,
                        child: Container(
                          width:  14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "${dashboardData['approvals']}",
                              style: const TextStyle(
                                color:    Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: loadDashboard,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size:  20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── SEARCH ────────────────────────────────────

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Container(
              decoration: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset:     const Offset(0, 4),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText:   "Search users, orders, providers...",
                  hintStyle:  TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Color(0xFF6D28D9)),
                  border:          InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // SECTION LABEL
  // =====================================================

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width:  4,
          height: 20,
          decoration: BoxDecoration(
            color:        const Color(0xFF6D28D9),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize:   20,
            fontWeight: FontWeight.bold,
            color:      Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // STAT CARD
  // =====================================================

  Widget _statCard(BuildContext context, {
    required String   title,
    required IconData icon,
    required int      count,
    required Color    color,
    required Widget   page,
    required String   trend,
    required bool     trendUp,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:      color.withOpacity(0.08),
              blurRadius: 16,
              offset:     const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendUp
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_flat_rounded,
                        size:  12,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        trend,
                        style: TextStyle(
                          color:      trendUp ? Colors.green : Colors.red,
                          fontSize:   10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    "$count",
                    style: TextStyle(
                      fontSize:   30,
                      fontWeight: FontWeight.bold,
                      color:      color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                    color:      Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // STATUS PILL
  // =====================================================

  Widget _statusPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.bold,
                color:      color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize:   10,
                fontWeight: FontWeight.w600,
                color:      color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // BAR CHART
  // =====================================================

  Widget _buildChart(bool isMobile, int maxValue,
      int pending, int accepted, int completed, int rejected) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color:        const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF3B82F6), size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Orders Analytics",
                      style: TextStyle(
                        fontSize:   17,
                        fontWeight: FontWeight.bold,
                        color:      Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Visual breakdown of all order statuses",
                      style: TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: isMobile ? 240 : 300,
            child: BarChart(
              BarChartData(
                alignment:  BarChartAlignment.spaceAround,
                maxY:       (maxValue + 2).toDouble(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show:               true,
                  drawVerticalLine:   false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color:       const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles:   true,
                      reservedSize: 28,
                      getTitlesWidget: (v, m) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        const labels = [
                          "Pending", "Accepted",
                          "Completed", "Rejected"
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            labels[v.toInt()],
                            style: TextStyle(
                              fontSize:   isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600,
                              color:      const Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _bar(0, pending,   const Color(0xFFF59E0B)),
                  _bar(1, accepted,  const Color(0xFF10B981)),
                  _bar(2, completed, const Color(0xFF3B82F6)),
                  _bar(3, rejected,  const Color(0xFFEF4444)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing:    20,
            runSpacing: 10,
            children: [
              _legend(const Color(0xFFF59E0B), "Pending"),
              _legend(const Color(0xFF10B981), "Accepted"),
              _legend(const Color(0xFF3B82F6), "Completed"),
              _legend(const Color(0xFFEF4444), "Rejected"),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // QUICK ACTION
  // =====================================================

  Widget _actionButton(BuildContext context, {
    required String   label,
    required IconData icon,
    required Color    color,
    required Widget   page,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:      color.withOpacity(0.10),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // BAR + LEGEND
  // =====================================================

  BarChartGroupData _bar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY:          value.toDouble(),
          width:        22,
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.6), color],
            begin:  Alignment.bottomCenter,
            end:    Alignment.topCenter,
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width:  12,
          height: 12,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize:   13,
            color:      Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}