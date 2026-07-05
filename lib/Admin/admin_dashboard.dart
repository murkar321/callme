import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final User? _adminUser = FirebaseAuth.instance.currentUser;

  // ── Loading state — each source has its own flag so we know exactly
  //    what's still pending, and a hard timeout guarantees we never spin
  //    forever even if one source never responds (offline, rules issue, etc).
  bool _loadingUsers = true;
  bool _loadingProviders = true;
  bool _loadingOrders = true;
  bool get isLoading => _loadingUsers || _loadingProviders || _loadingOrders;

  bool _timedOut = false;
  Timer? _timeoutGuard;

  Map<String, dynamic> dashboardData = {
    'users': 0,
    'providers': 0,
    'orders': 0,
    'approvals': 0,
    'pending': 0,
    'accepted': 0,
    'completed': 0,
    'rejected': 0,
  };

  String? _newProviderBanner;

  // Timestamp of the last successful data refresh — shown in the header so
  // it's obvious the dashboard is actually live, not just static numbers.
  DateTime? _lastUpdated;

  StreamSubscription<QuerySnapshot>? _usersSub;
  StreamSubscription<QuerySnapshot>? _providersSub;
  StreamSubscription<QuerySnapshot>? _ordersSub;

  // Pre-populated via get() before the providers stream attaches — avoids
  // false "new provider" notifications firing on every cold start.
  final Set<String> _seenProviderIds = {};
  bool _providersSeedDone = false;

  // ── Header search — a real, working search box. Submitting a query jumps
  //    straight into the Orders page pre-filtered, since "search everything"
  //    isn't a single Firestore query but orders is the most common lookup
  //    (by customer name, phone, email, or order id).
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // =====================================================
  // INIT / DISPOSE
  // =====================================================

  @override
  void initState() {
    super.initState();
    _saveAdminFcmToken();
    _startTimeoutGuard();
    _attachAllListeners();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _providersSub?.cancel();
    _ordersSub?.cancel();
    _timeoutGuard?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _attachAllListeners() {
    _seedThenListenProviders();
    _listenUsers();
    _listenOrders();
  }

  /// Guarantees the loading spinner can never hang indefinitely. If any
  /// stream hasn't delivered its first snapshot within 15s (bad connection,
  /// rules issue, etc.) we stop blocking the UI and show a retry banner
  /// instead of buffering forever.
  void _startTimeoutGuard() {
    _timeoutGuard?.cancel();
    _timeoutGuard = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      if (isLoading) {
        setState(() {
          _loadingUsers = false;
          _loadingProviders = false;
          _loadingOrders = false;
          _timedOut = true;
        });
      }
    });
  }

  Future<void> _retryLoad() async {
    setState(() {
      _timedOut = false;
      _loadingUsers = true;
      _loadingProviders = true;
      _loadingOrders = true;
      _providersSeedDone = false;
    });
    await _usersSub?.cancel();
    await _providersSub?.cancel();
    await _ordersSub?.cancel();
    _startTimeoutGuard();
    _attachAllListeners();
  }

  // =====================================================
  // SAVE ADMIN FCM TOKEN
  // =====================================================

  Future<void> _saveAdminFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _db.doc('admin_config/fcm').set({
        'token': token,
        'adminUid': _adminUser?.uid ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _db.doc('admin_config/fcm').set({
          'token': newToken,
          'adminUid': _adminUser?.uid ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('[Admin] FCM token save error: $e');
    }
  }

  // =====================================================
  // LIVE USERS COUNT
  // Mirrors UsersPage's _isValidUser filter (uid field present) so the
  // dashboard number always matches what UsersPage actually lists.
  // =====================================================

  void _listenUsers() {
    _usersSub = _db.collection('users').snapshots().listen((snapshot) {
      if (!mounted) return;
      final validCount = snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['uid'] ?? '').toString().trim().isNotEmpty;
      }).length;

      setState(() {
        dashboardData['users'] = validCount;
        _loadingUsers = false;
        _timedOut = false;
        _lastUpdated = DateTime.now();
      });
    }, onError: (e) {
      debugPrint('[Admin] users listener error: $e');
      if (mounted) setState(() => _loadingUsers = false);
    });
  }

  // =====================================================
  // LIVE PROVIDERS + APPROVALS COUNT, PLUS "NEW PROVIDER" ALERTS
  // One single stream drives all three, instead of separate queries —
  // fewer moving parts, fewer places for something to silently fail.
  // =====================================================

  /// Provider documents aren't consistently shaped: some store the
  /// service category as a top-level `serviceType` field, others nest it
  /// under `service.serviceType`. Every place that needs this value goes
  /// through this helper so notifications/banners never show "service"
  /// as a fallback just because the schema shape differs for that doc.
  String _providerServiceType(Map<String, dynamic> data) {
    final top = (data['serviceType'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    final nested = (data['service'] as Map?)?['serviceType'];
    final nestedStr = (nested ?? '').toString().trim();
    return nestedStr.isNotEmpty ? nestedStr : 'service';
  }

  Future<void> _seedThenListenProviders() async {
    try {
      final existingPending = await _db
          .collection('providers')
          .where('status', isEqualTo: 'pending')
          .get();
      for (final doc in existingPending.docs) {
        _seenProviderIds.add(doc.id);
      }
    } catch (e) {
      debugPrint('[Admin] provider seed error: $e');
    }
    _providersSeedDone = true;

    _providersSub =
        _db.collection('providers').snapshots().listen((snapshot) async {
      if (!mounted) return;

      int approvals = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        if (status == 'pending') approvals++;
      }

      setState(() {
        dashboardData['providers'] = snapshot.docs.length;
        dashboardData['approvals'] = approvals;
        _loadingProviders = false;
        _timedOut = false;
        _lastUpdated = DateTime.now();
      });

      // Only fire "new provider" alerts once the seed pass has completed,
      // so cold starts don't re-notify about providers already pending.
      if (!_providersSeedDone) return;

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final doc = change.doc;
        final id = doc.id;
        final data = doc.data() ?? {};
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        if (status != 'pending') continue;
        if (_seenProviderIds.contains(id)) continue;
        _seenProviderIds.add(id);

        final business = (data['business'] as Map<String, dynamic>?) ?? {};
        final businessName =
            (business['businessName'] ?? data['providerName'] ?? 'A provider')
                .toString();
        final ownerName =
            (business['ownerName'] ?? data['ownerName'] ?? '').toString();
        final serviceType = _providerServiceType(data);
        final phone = (business['phone'] ?? data['phone'] ?? '').toString();

        const title = 'New Provider Registration';
        final body = '$businessName by $ownerName registered as a '
            '$serviceType provider and is awaiting approval.';

        if (mounted) {
          setState(() => _newProviderBanner =
              '$businessName registered — tap Approvals to review');
          Future.delayed(const Duration(seconds: 6), () {
            if (mounted) setState(() => _newProviderBanner = null);
          });
        }

        await _writeNotification(
          receiverId: _adminUser?.uid ?? '',
          role: 'admin',
          title: title,
          body: body,
          type: 'provider_registered',
          extraData: {
            'providerId': id,
            'businessName': businessName,
            'ownerName': ownerName,
            'serviceType': serviceType,
            'phone': phone,
          },
        );

        await _queueAdminFcm(
          title: title,
          body: body,
          type: 'provider_registered',
          providerId: id,
          businessName: businessName,
          ownerName: ownerName,
          serviceType: serviceType,
          phone: phone,
        );
      }
    }, onError: (e) {
      debugPrint('[Admin] providers listener error: $e');
      if (mounted) setState(() => _loadingProviders = false);
    });
  }

  Future<void> _writeNotification({
    required String receiverId,
    required String role,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> extraData = const {},
  }) async {
    if (receiverId.isEmpty) return;
    try {
      await _db.collection('notifications').add({
        'receiverId': receiverId,
        'role': role,
        'title': title,
        'body': body,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        ...extraData,
      });
    } catch (e) {
      debugPrint('[Admin] _writeNotification error: $e');
    }
  }

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
      final configDoc = await _db.doc('admin_config/fcm').get();
      final adminToken = (configDoc.data()?['token'] ?? '').toString().trim();
      if (adminToken.isEmpty) return;

      await _db.collection('fcm_queue').add({
        'token': adminToken,
        'receiverId': _adminUser?.uid ?? '',
        'title': title,
        'body': body,
        'type': type,
        'providerId': providerId,
        'businessName': businessName,
        'ownerName': ownerName,
        'serviceType': serviceType,
        'phone': phone,
        'data': {'type': type, 'providerId': providerId},
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Admin] FCM queue error: $e');
    }
  }

  // =====================================================
  // LIVE ORDERS STREAM
  //
  // Status is read tolerantly (a few possible field names/locations,
  // case/whitespace-insensitive) and bucketed into the same four buckets
  // AdminOrdersPage uses: pending / accepted / completed / rejected.
  // =====================================================

  void _listenOrders() {
    _ordersSub = _db.collection('orders').snapshots().listen((snapshot) {
      if (!mounted) return;

      int pending = 0, accepted = 0, completed = 0, rejected = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawStatus = _statusOf(data);

        switch (_bucketFor(rawStatus)) {
          case _OrderBucket.accepted:
            accepted++;
            break;
          case _OrderBucket.completed:
            completed++;
            break;
          case _OrderBucket.rejected:
            rejected++;
            break;
          case _OrderBucket.pending:
            pending++;
            break;
        }
      }

      setState(() {
        dashboardData['orders'] = snapshot.docs.length;
        dashboardData['pending'] = pending;
        dashboardData['accepted'] = accepted;
        dashboardData['completed'] = completed;
        dashboardData['rejected'] = rejected;
        _loadingOrders = false;
        _timedOut = false;
        _lastUpdated = DateTime.now();
      });
    }, onError: (e) {
      debugPrint('[Admin] orders listener error: $e');
      if (mounted) setState(() => _loadingOrders = false);
    });
  }

  String _statusOf(Map<String, dynamic> data) {
    final candidates = <dynamic>[
      data['status'],
      data['orderStatus'],
      data['order_status'],
      data['bookingStatus'],
      (data['order'] is Map) ? (data['order'] as Map)['status'] : null,
    ];
    for (final c in candidates) {
      final s = c?.toString().trim();
      if (s != null && s.isNotEmpty) return s.toLowerCase();
    }
    return 'pending';
  }

  _OrderBucket _bucketFor(String status) {
    switch (status) {
      case 'accepted':
      case 'confirmed':
      case 'assigned':
      case 'ongoing':
      case 'in_progress':
        return _OrderBucket.accepted;
      case 'completed':
      case 'complete':
      case 'done':
      case 'delivered':
        return _OrderBucket.completed;
      case 'rejected':
      case 'cancelled':
      case 'canceled':
      case 'declined':
        return _OrderBucket.rejected;
      default:
        return _OrderBucket.pending;
    }
  }

  // ── Header search: jump into Orders pre-filtered by whatever was typed.
  void _submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminOrdersPage(initialSearch: query),
      ),
    );
  }

  String _lastUpdatedLabel() {
    final t = _lastUpdated;
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 10) return 'Updated just now';
    if (diff.inMinutes < 1) return 'Updated ${diff.inSeconds}s ago';
    if (diff.inHours < 1) return 'Updated ${diff.inMinutes}m ago';
    return 'Updated ${diff.inHours}h ago';
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _ScreenMetrics.of(constraints.maxWidth);

            final int pending = dashboardData['pending'];
            final int accepted = dashboardData['accepted'];
            final int completed = dashboardData['completed'];
            final int rejected = dashboardData['rejected'];
            final int maxValue = [pending, accepted, completed, rejected]
                .reduce((a, b) => a > b ? a : b);

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: _retryLoad,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(metrics, pending),

                    if (_timedOut) _buildTimeoutBanner(metrics),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      child: _newProviderBanner != null
                          ? _buildNewProviderBanner(metrics)
                          : const SizedBox.shrink(),
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          metrics.pagePadding, 28, metrics.pagePadding, 0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _sectionLabel('Overview'),
                                const Spacer(),
                                if (_lastUpdated != null)
                                  Text(
                                    _lastUpdatedLabel(),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildStatsGrid(context, metrics),
                            const SizedBox(height: 30),
                            _sectionLabel('Order Status Breakdown'),
                            const SizedBox(height: 14),
                            _buildStatusPills(
                                metrics, pending, accepted, completed, rejected),
                            const SizedBox(height: 28),
                            _buildChart(metrics, maxValue, pending, accepted,
                                completed, rejected),
                            const SizedBox(height: 30),
                            _sectionLabel('Quick Actions'),
                            const SizedBox(height: 14),
                            _buildQuickActions(context, metrics),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Timeout banner ───────────────────────────────────────────────────

  Widget _buildTimeoutBanner(_ScreenMetrics m) {
    return Container(
      margin: EdgeInsets.fromLTRB(m.pagePadding, 14, m.pagePadding, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFB45309), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Some data took too long to load — showing what's available.",
              style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: _retryLoad,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────

  Widget _buildNewProviderBanner(_ScreenMetrics m) {
    return Container(
      margin: EdgeInsets.fromLTRB(m.pagePadding, 14, m.pagePadding, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.12),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
                color: Color(0xFF4ADE80), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.person_add_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Provider Registered',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _newProviderBanner ?? '',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              setState(() => _newProviderBanner = null);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApproveProvidersPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Review',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(_ScreenMetrics m, int pending) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending > 0)
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(
                  m.pagePadding - 4, 16, m.pagePadding - 4, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Colors.orange, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$pending pending order${pending == 1 ? '' : 's'} require your attention',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pending',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Title row — icon buttons sized down on mobile, and the title
          // shrinks-to-fit on one line instead of wrapping onto 2-3 lines.
          Padding(
            padding: EdgeInsets.fromLTRB(m.pagePadding, 20, m.pagePadding, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(m.iconButtonPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: m.headerIconSize),
                ),
                SizedBox(width: m.isMobile ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Admin Dashboard',
                          maxLines: 1,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: m.titleFontSize,
                              fontWeight: FontWeight.bold,
                              height: 1.1),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your platform',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white60, fontSize: m.subtitleFontSize),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: m.isMobile ? 6 : 10),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ApproveProvidersPage()),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(m.iconButtonPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.notifications_rounded,
                            color: Colors.white, size: m.headerIconSize),
                      ),
                    ),
                    if ((dashboardData['approvals'] ?? 0) > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                              color: Colors.orange, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '${dashboardData['approvals']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: m.isMobile ? 6 : 10),
                GestureDetector(
                  onTap: _retryLoad,
                  child: Container(
                    padding: EdgeInsets.all(m.iconButtonPadding),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.refresh_rounded,
                        color: Colors.white, size: m.headerIconSize),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(m.pagePadding, 20, m.pagePadding, 28),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                decoration: InputDecoration(
                  hintText: 'Search orders by name, phone, email, ID…',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Color(0xFF6D28D9)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF6D28D9)),
                    onPressed: () => _submitSearch(_searchController.text),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF6D28D9),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  // ─── Stats grid (responsive) ────────────────────────────────────────

  Widget _buildStatsGrid(BuildContext context, _ScreenMetrics m) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: m.statsColumns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: m.statsAspectRatio,
      ),
      children: [
        _statCard(context,
            title: 'Users',
            icon: Icons.people_alt_rounded,
            count: dashboardData['users'],
            color: const Color(0xFF3B82F6),
            page: UsersPage()),
        _statCard(context,
            title: 'Providers',
            icon: Icons.storefront_rounded,
            count: dashboardData['providers'],
            color: const Color(0xFF10B981),
            page: ProvidersPage()),
        _statCard(context,
            title: 'Orders',
            icon: Icons.receipt_long_rounded,
            count: dashboardData['orders'],
            color: const Color(0xFFF59E0B),
            page: const AdminOrdersPage()),
        _statCard(context,
            title: 'Approvals',
            icon: Icons.pending_actions_rounded,
            count: dashboardData['approvals'],
            color: const Color(0xFFEF4444),
            page: const ApproveProvidersPage(),
            highlight: (dashboardData['approvals'] ?? 0) > 0),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int count,
    required Color color,
    required Widget page,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: highlight ? Border.all(color: color.withOpacity(0.4), width: 1.5) : null,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$count',
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Status pills ─────────────────────────────────────────────────────

  Widget _buildStatusPills(
      _ScreenMetrics m, int pending, int accepted, int completed, int rejected) {
    final pills = [
      _statusPill('Pending', pending, const Color(0xFFF59E0B)),
      _statusPill('Accepted', accepted, const Color(0xFF10B981)),
      _statusPill('Done', completed, const Color(0xFF3B82F6)),
      _statusPill('Rejected', rejected, const Color(0xFFEF4444)),
    ];

    if (m.isMobile) {
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
        ),
        children: pills,
      );
    }

    return Row(
      children: [
        for (int i = 0; i < pills.length; i++) ...[
          Expanded(child: pills[i]),
          if (i != pills.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _statusPill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$count',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  // ─── Chart ────────────────────────────────────────────────────────────

  Widget _buildChart(_ScreenMetrics m, int maxValue, int pending, int accepted,
      int completed, int rejected) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6)),
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
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                      'Orders Analytics',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Live breakdown of all order statuses',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 5),
                    Text('Live',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: m.isMobile ? 220 : 300,
            child: maxValue == 0
                ? const Center(
                    child: Text('No orders yet',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (maxValue + 2).toDouble(),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (v) =>
                            FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, mm) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, mm) {
                              const labels = ['Pending', 'Accepted', 'Completed', 'Rejected'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  labels[v.toInt()],
                                  style: TextStyle(
                                    fontSize: m.isMobile ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        _bar(0, pending, const Color(0xFFF59E0B)),
                        _bar(1, accepted, const Color(0xFF10B981)),
                        _bar(2, completed, const Color(0xFF3B82F6)),
                        _bar(3, rejected, const Color(0xFFEF4444)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _legend(const Color(0xFFF59E0B), 'Pending'),
              _legend(const Color(0xFF10B981), 'Accepted'),
              _legend(const Color(0xFF3B82F6), 'Completed'),
              _legend(const Color(0xFFEF4444), 'Rejected'),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 22,
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.6), color],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── Quick actions ────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, _ScreenMetrics m) {
    final actions = [
      (
        label: 'Manage Users',
        icon: Icons.manage_accounts_rounded,
        color: const Color(0xFF3B82F6),
        page: UsersPage(),
      ),
      (
        label: 'View Orders',
        icon: Icons.list_alt_rounded,
        color: const Color(0xFFF59E0B),
        page: const AdminOrdersPage(),
      ),
      (
        label: 'Approvals',
        icon: Icons.verified_rounded,
        color: const Color(0xFFEF4444),
        page: const ApproveProvidersPage(),
      ),
    ];

    if (m.isMobile) {
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        children: actions
            .map((a) => _actionButton(context,
                label: a.label, icon: a.icon, color: a.color, page: a.page))
            .toList(),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Expanded(
            child: _actionButton(context,
                label: actions[i].label,
                icon: actions[i].icon,
                color: actions[i].color,
                page: actions[i].page),
          ),
          if (i != actions.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OrderBucket { pending, accepted, completed, rejected }

/// Centralized responsive sizing so every section of the dashboard reads
/// off the same breakpoint logic instead of each widget guessing its own
/// numbers. Covers phone / tablet / desktop consistently.
class _ScreenMetrics {
  final double width;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  final double pagePadding;
  final double titleFontSize;
  final double subtitleFontSize;
  final double headerIconSize;
  final double iconButtonPadding;
  final int statsColumns;
  final double statsAspectRatio;

  _ScreenMetrics._({
    required this.width,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.pagePadding,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.headerIconSize,
    required this.iconButtonPadding,
    required this.statsColumns,
    required this.statsAspectRatio,
  });

  factory _ScreenMetrics.of(double width) {
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1000;
    final isDesktop = width >= 1000;

    // Extra-narrow phones (e.g. small Android devices, ~340-360px) get a
    // slightly smaller title and tighter icon buttons so "Admin Dashboard"
    // still comfortably fits on one line without needing to shrink too far.
    final isNarrowPhone = width < 380;

    return _ScreenMetrics._(
      width: width,
      isMobile: isMobile,
      isTablet: isTablet,
      isDesktop: isDesktop,
      pagePadding: isMobile ? 16 : (isTablet ? 24 : 28),
      titleFontSize: isNarrowPhone ? 20 : (isMobile ? 22 : 24),
      subtitleFontSize: isMobile ? 12 : 13,
      headerIconSize: isMobile ? 20 : 24,
      iconButtonPadding: isNarrowPhone ? 9 : (isMobile ? 10 : 12),
      statsColumns: isMobile ? 2 : (isTablet ? 3 : 4),
      statsAspectRatio: isMobile ? 1.05 : (isTablet ? 1.15 : 1.25),
    );
  }
}