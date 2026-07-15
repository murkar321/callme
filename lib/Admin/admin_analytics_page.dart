import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// =====================================================================
/// ADMIN ANALYTICS PAGE
///
/// Fully real-time analytics screen driven by three Firestore streams
/// (orders, users, providers) — no polling, no pull-to-refresh needed,
/// every card/graph recomputes the instant a doc changes.
///
/// Field reading follows the SAME tolerant pattern already used in
/// admin_dashboard.dart (_statusOf / _providerServiceType): several
/// possible field names/shapes are tried in priority order so this page
/// doesn't break if different parts of the app wrote slightly different
/// schemas for price/city/rating/etc. If your real field names differ,
/// just add them to the candidate list in the relevant `_xOf()` helper
/// below — nothing else needs to change.
///
/// UI is mobile-first (built for Android phones) but scales cleanly up
/// to tablets via LayoutBuilder breakpoints, matching the responsive
/// approach in AdminDashboard's _ScreenMetrics.
/// =====================================================================

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _usersSub;
  StreamSubscription<QuerySnapshot>? _providersSub;

  bool _loadingOrders = true;
  bool _loadingUsers = true;
  bool _loadingProviders = true;
  bool get isLoading => _loadingOrders || _loadingUsers || _loadingProviders;

  // Raw parsed docs — kept in memory so every metric can be recomputed
  // cheaply on any single stream update without re-reading Firestore.
  List<_OrderRecord> _orders = [];
  List<_JoinRecord> _users = [];
  List<_JoinRecord> _providers = [];
  Map<String, _ProviderMeta> _providerMeta = {}; // providerId -> name/rating

  Timer? _rangeTicker;
  final int _trendDays = 7; // window for the line/bar trend graphs

  @override
  void initState() {
    super.initState();
    _listenProviders();
    _listenUsers();
    _listenOrders();
    // Cheap once-a-minute tick so "Today" boundaries / relative labels
    // stay correct if the screen is left open across midnight, etc.
    _rangeTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _usersSub?.cancel();
    _providersSub?.cancel();
    _rangeTicker?.cancel();
    super.dispose();
  }

  // =====================================================================
  // STREAMS
  // =====================================================================

  void _listenProviders() {
    _providersSub = _db.collection('providers').snapshots().listen((snap) {
      if (!mounted) return;
      final joins = <_JoinRecord>[];
      final meta = <String, _ProviderMeta>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final joinedAt = _dateOf(data, [
          'createdAt',
          'registeredAt',
          'timestamp',
          'joinedAt',
        ]);
        joins.add(_JoinRecord(id: doc.id, joinedAt: joinedAt));

        final business = (data['business'] as Map<String, dynamic>?) ?? {};
        final name = (business['businessName'] ??
                data['businessName'] ??
                data['providerName'] ??
                'Unnamed Provider')
            .toString();
        final city = _stringOf(data, [
          'city',
        ]) ??
            _stringOf(business, ['city']) ??
            _nestedStringOf(data, 'address', 'city') ??
            _nestedStringOf(business, 'address', 'city');
        final rating = _doubleOf(data, ['rating', 'avgRating', 'averageRating']);

        meta[doc.id] = _ProviderMeta(name: name, city: city, rating: rating);
      }

      setState(() {
        _providers = joins;
        _providerMeta = meta;
        _loadingProviders = false;
      });
    }, onError: (e) {
      debugPrint('[Analytics] providers stream error: $e');
      if (mounted) setState(() => _loadingProviders = false);
    });
  }

  void _listenUsers() {
    _usersSub = _db.collection('users').snapshots().listen((snap) {
      if (!mounted) return;
      final joins = <_JoinRecord>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        // Only count actual customer/user accounts, mirroring the
        // AdminDashboard 'users' count filter (skip malformed/admin-only
        // docs that have no uid).
        final uid = (data['uid'] ?? '').toString().trim();
        if (uid.isEmpty) continue;
        final role = (data['role'] ?? 'customer').toString().toLowerCase();
        if (role == 'admin') continue;

        final joinedAt = _dateOf(data, ['createdAt', 'registeredAt', 'timestamp']);
        joins.add(_JoinRecord(id: doc.id, joinedAt: joinedAt));
      }
      setState(() {
        _users = joins;
        _loadingUsers = false;
      });
    }, onError: (e) {
      debugPrint('[Analytics] users stream error: $e');
      if (mounted) setState(() => _loadingUsers = false);
    });
  }

  void _listenOrders() {
    _ordersSub = _db.collection('orders').snapshots().listen((snap) {
      if (!mounted) return;
      final records = <_OrderRecord>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        records.add(_OrderRecord(
          id: doc.id,
          status: _bucketFor(_statusOf(data)),
          amount: _amountOf(data),
          createdAt: _dateOf(data, [
            'createdAt',
            'timestamp',
            'orderDate',
            'bookingDate',
          ]),
          serviceType: _serviceTypeOf(data),
          city: _cityOf(data),
          providerId: _stringOf(data, ['providerId', 'provider_id']),
          customerId: _stringOf(
              data, ['customerId', 'userId', 'uid', 'customerEmail']),
          rating: _doubleOf(data, ['rating', 'orderRating']),
        ));
      }

      setState(() {
        _orders = records;
        _loadingOrders = false;
      });
    }, onError: (e) {
      debugPrint('[Analytics] orders stream error: $e');
      if (mounted) setState(() => _loadingOrders = false);
    });
  }

  // =====================================================================
  // TOLERANT FIELD READERS
  // (Same philosophy as admin_dashboard.dart's _statusOf/_providerServiceType
  // — try every plausible field/shape, first non-empty wins.)
  // =====================================================================

  String? _stringOf(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  String? _nestedStringOf(Map<String, dynamic> data, String parentKey, String childKey) {
    final parent = data[parentKey];
    if (parent is Map) {
      final v = parent[childKey];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  double? _doubleOf(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      final parsed = double.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  double _amountOf(Map<String, dynamic> data) {
    final direct = _doubleOf(data, [
      'amount',
      'totalAmount',
      'price',
      'totalPrice',
      'orderAmount',
      'total',
      'grandTotal',
    ]);
    if (direct != null) return direct;

    // Nested under a `payment` / `order` map in some schemas.
    for (final parentKey in ['payment', 'order', 'billing']) {
      final parent = data[parentKey];
      if (parent is Map) {
        final nested = _doubleOf(Map<String, dynamic>.from(parent),
            ['amount', 'totalAmount', 'price', 'total']);
        if (nested != null) return nested;
      }
    }
    return 0.0;
  }

  DateTime? _dateOf(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v == null) continue;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
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
        return _OrderBucket.cancelled;
      default:
        return _OrderBucket.pending;
    }
  }

  String _serviceTypeOf(Map<String, dynamic> data) {
    final top = _stringOf(data, ['serviceType', 'category', 'service_type']);
    if (top != null) return top;
    final nested = _nestedStringOf(data, 'service', 'serviceType') ??
        _nestedStringOf(data, 'service', 'category');
    return nested ?? 'Other';
  }

  String _cityOf(Map<String, dynamic> data) {
    return _stringOf(data, ['city', 'customerCity']) ??
        _nestedStringOf(data, 'address', 'city') ??
        _nestedStringOf(data, 'location', 'city') ??
        'Unknown';
  }

  // =====================================================================
  // METRIC COMPUTATION
  // All pure functions over the cached lists — cheap enough to run on
  // every rebuild rather than caching separately, so nothing ever goes
  // stale relative to what's on screen.
  // =====================================================================

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  double get _todayRevenue => _orders
      .where((o) => _isToday(o.createdAt) && o.status == _OrderBucket.completed)
      .fold(0.0, (sum, o) => sum + o.amount);

  int get _todayBookings => _orders.where((o) => _isToday(o.createdAt)).length;

  int get _pendingCount =>
      _orders.where((o) => o.status == _OrderBucket.pending).length;

  int get _completedCount =>
      _orders.where((o) => o.status == _OrderBucket.completed).length;

  int get _cancelledCount =>
      _orders.where((o) => o.status == _OrderBucket.cancelled).length;

  double? get _averageRating {
    final rated = _orders.where((o) => o.rating != null).toList();
    if (rated.isNotEmpty) {
      return rated.fold(0.0, (s, o) => s + o.rating!) / rated.length;
    }
    // Fallback: average provider-level ratings if no order carries one.
    final providerRatings =
        _providerMeta.values.where((p) => p.rating != null).toList();
    if (providerRatings.isEmpty) return null;
    return providerRatings.fold(0.0, (s, p) => s + p.rating!) /
        providerRatings.length;
  }

  double get _cancellationRate {
    if (_orders.isEmpty) return 0;
    return (_cancelledCount / _orders.length) * 100;
  }

  /// Customers who placed more than one order, as a % of all customers
  /// who ever placed one.
  double get _repeatCustomerRate {
    final byCustomer = <String, int>{};
    for (final o in _orders) {
      final id = o.customerId;
      if (id == null || id.isEmpty) continue;
      byCustomer[id] = (byCustomer[id] ?? 0) + 1;
    }
    if (byCustomer.isEmpty) return 0;
    final repeat = byCustomer.values.where((c) => c > 1).length;
    return (repeat / byCustomer.length) * 100;
  }

  List<DateTime> get _trendDayBuckets {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: _trendDays - 1));
    return List.generate(_trendDays, (i) => start.add(Duration(days: i)));
  }

  /// Revenue per day for the trailing [_trendDays] window (completed
  /// orders only, since pending/cancelled orders don't represent
  /// realized revenue).
  List<double> get _revenueTrend {
    final buckets = _trendDayBuckets;
    return buckets.map((day) {
      return _orders
          .where((o) =>
              o.status == _OrderBucket.completed &&
              o.createdAt != null &&
              _sameDay(o.createdAt!, day))
          .fold(0.0, (s, o) => s + o.amount);
    }).toList();
  }

  List<int> get _bookingsTrend {
    final buckets = _trendDayBuckets;
    return buckets.map((day) {
      return _orders
          .where((o) => o.createdAt != null && _sameDay(o.createdAt!, day))
          .length;
    }).toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Top N services by booking count.
  List<MapEntry<String, int>> get _popularServices {
    final counts = <String, int>{};
    for (final o in _orders) {
      counts[o.serviceType] = (counts[o.serviceType] ?? 0) + 1;
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(5).toList();
  }

  /// Booking count bucketed by hour-of-day (0-23), for a "peak hours" bar.
  List<int> get _peakHours {
    final buckets = List<int>.filled(24, 0);
    for (final o in _orders) {
      final d = o.createdAt;
      if (d == null) continue;
      buckets[d.hour]++;
    }
    return buckets;
  }

  /// Top providers by number of completed orders, with total revenue.
  List<_ProviderRank> get _topProviders {
    final byProvider = <String, _ProviderRank>{};
    for (final o in _orders) {
      final pid = o.providerId;
      if (pid == null || pid.isEmpty) continue;
      final meta = _providerMeta[pid];
      final entry = byProvider.putIfAbsent(
        pid,
        () => _ProviderRank(id: pid, name: meta?.name ?? 'Unknown Provider'),
      );
      entry.totalOrders++;
      if (o.status == _OrderBucket.completed) {
        entry.completedOrders++;
        entry.revenue += o.amount;
      }
    }
    final list = byProvider.values.toList()
      ..sort((a, b) => b.completedOrders.compareTo(a.completedOrders));
    return list.take(5).toList();
  }

  /// Top cities by booking count.
  List<MapEntry<String, int>> get _topCities {
    final counts = <String, int>{};
    for (final o in _orders) {
      if (o.city == 'Unknown') continue;
      counts[o.city] = (counts[o.city] ?? 0) + 1;
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(5).toList();
  }

  List<int> get _customerGrowthTrend {
    final buckets = _trendDayBuckets;
    return buckets
        .map((day) => _users
            .where((u) => u.joinedAt != null && _sameDay(u.joinedAt!, day))
            .length)
        .toList();
  }

  List<int> get _providerGrowthTrend {
    final buckets = _trendDayBuckets;
    return buckets
        .map((day) => _providers
            .where((p) => p.joinedAt != null && _sameDay(p.joinedAt!, day))
            .length)
        .toList();
  }

  // =====================================================================
  // BUILD
  // =====================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text('Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(builder: (context, constraints) {
                final m = _AnalyticsMetrics.of(constraints.maxWidth);
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      m.pagePadding, 4, m.pagePadding, 30),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Today'),
                        const SizedBox(height: 12),
                        _buildTopStatsGrid(m),
                        const SizedBox(height: 26),
                        _sectionLabel('Revenue (Last 7 Days)'),
                        const SizedBox(height: 12),
                        _buildRevenueChart(m),
                        const SizedBox(height: 26),
                        _sectionLabel('Bookings (Last 7 Days)'),
                        const SizedBox(height: 12),
                        _buildBookingsChart(m),
                        const SizedBox(height: 26),
                        m.isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionLabel('Most Popular Services'),
                                  const SizedBox(height: 12),
                                  _buildPopularServices(m),
                                  const SizedBox(height: 26),
                                  _sectionLabel('Peak Booking Hours'),
                                  const SizedBox(height: 12),
                                  _buildPeakHoursChart(m),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Most Popular Services'),
                                        const SizedBox(height: 12),
                                        _buildPopularServices(m),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Peak Booking Hours'),
                                        const SizedBox(height: 12),
                                        _buildPeakHoursChart(m),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 26),
                        _sectionLabel('Top Providers'),
                        const SizedBox(height: 12),
                        _buildTopProviders(m),
                        const SizedBox(height: 26),
                        _sectionLabel('Top Cities'),
                        const SizedBox(height: 12),
                        _buildTopCities(m),
                        const SizedBox(height: 26),
                        _sectionLabel('Growth (Last 7 Days)'),
                        const SizedBox(height: 12),
                        _buildGrowthChart(m),
                        const SizedBox(height: 26),
                        _sectionLabel('Customer Insights'),
                        const SizedBox(height: 12),
                        _buildInsightPills(m),
                      ],
                    ),
                  ),
                );
              }),
      ),
    );
  }

  // ── Section label ────────────────────────────────────────────────────

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
              fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  // ── Top stats grid ───────────────────────────────────────────────────

  Widget _buildTopStatsGrid(_AnalyticsMetrics m) {
    final rating = _averageRating;
    final stats = [
      (
        title: "Today's Revenue",
        value: '₹${_todayRevenue.toStringAsFixed(0)}',
        icon: Icons.currency_rupee_rounded,
        color: const Color(0xFF10B981),
      ),
      (
        title: "Today's Bookings",
        value: '$_todayBookings',
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFF3B82F6),
      ),
      (
        title: 'Pending Requests',
        value: '$_pendingCount',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFF59E0B),
      ),
      (
        title: 'Completed Services',
        value: '$_completedCount',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF6366F1),
      ),
      (
        title: 'Cancelled Orders',
        value: '$_cancelledCount',
        icon: Icons.cancel_rounded,
        color: const Color(0xFFEF4444),
      ),
      (
        title: 'Average Rating',
        value: rating != null ? rating.toStringAsFixed(1) : '—',
        icon: Icons.star_rounded,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: m.statsColumns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: m.statsAspectRatio,
      ),
      children: stats
          .map((s) => _statCard(
              title: s.title, value: s.value, icon: s.icon, color: s.color))
          .toList(),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ── Revenue chart (line) ────────────────────────────────────────────

  Widget _buildRevenueChart(_AnalyticsMetrics m) {
    final trend = _revenueTrend;
    final days = _trendDayBuckets;
    final maxY = (trend.isEmpty ? 0.0 : trend.reduce(math.max));

    return _card(
      child: SizedBox(
        height: m.isMobile ? 200 : 260,
        child: maxY <= 0
            ? const Center(
                child: Text('No revenue yet',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)))
            : LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (v, mm) => Text('₹${v.toInt()}',
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (v, mm) {
                          final i = v.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_dayLabel(days[i]),
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF64748B))),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < trend.length; i++)
                          FlSpot(i.toDouble(), trend[i]),
                      ],
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF10B981).withOpacity(0.12),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Bookings chart (bar) ────────────────────────────────────────────

  Widget _buildBookingsChart(_AnalyticsMetrics m) {
    final trend = _bookingsTrend;
    final days = _trendDayBuckets;
    final maxY = trend.isEmpty ? 0 : trend.reduce(math.max);

    return _card(
      child: SizedBox(
        height: m.isMobile ? 190 : 240,
        child: maxY <= 0
            ? const Center(
                child: Text('No bookings yet',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)))
            : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxY + 2).toDouble(),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, mm) => Text(v.toInt().toString(),
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, mm) {
                          final i = v.toInt();
                          if (i < 0 || i >= days.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_dayLabel(days[i]),
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF64748B))),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < trend.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: trend[i].toDouble(),
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ]),
                  ],
                ),
              ),
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  }

  // ── Popular services (ranked list w/ bars) ──────────────────────────

  Widget _buildPopularServices(_AnalyticsMetrics m) {
    final services = _popularServices;
    if (services.isEmpty) {
      return _card(
        child: const Text('No service data yet',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      );
    }
    final maxCount = services.first.value;
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
    ];

    return _card(
      child: Column(
        children: [
          for (int i = 0; i < services.length; i++) ...[
            _rankedBarRow(
              label: services[i].key,
              value: services[i].value,
              maxValue: maxCount,
              color: colors[i % colors.length],
            ),
            if (i != services.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _rankedBarRow({
    required String label,
    required int value,
    required int maxValue,
    required Color color,
  }) {
    final fraction = maxValue == 0 ? 0.0 : value / maxValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155))),
            ),
            Text('$value',
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ── Peak booking hours (compact bar chart, 24 buckets) ──────────────

  Widget _buildPeakHoursChart(_AnalyticsMetrics m) {
    final hours = _peakHours;
    final maxY = hours.reduce(math.max);

    return _card(
      child: SizedBox(
        height: m.isMobile ? 190 : 240,
        child: maxY <= 0
            ? const Center(
                child: Text('No booking-time data yet',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)))
            : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: (maxY + 1).toDouble(),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, mm) => Text(v.toInt().toString(),
                            style: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 9)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        getTitlesWidget: (v, mm) {
                          final h = v.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(_hourLabel(h),
                                style: const TextStyle(
                                    fontSize: 9, color: Color(0xFF64748B))),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int h = 0; h < 24; h++)
                      BarChartGroupData(x: h, barRods: [
                        BarChartRodData(
                          toY: hours[h].toDouble(),
                          width: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: const Color(0xFF8B5CF6),
                        ),
                      ]),
                  ],
                ),
              ),
      ),
    );
  }

  String _hourLabel(int h) {
    final period = h < 12 ? 'AM' : 'PM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12$period';
  }

  // ── Top providers (ranked list) ─────────────────────────────────────

  Widget _buildTopProviders(_AnalyticsMetrics m) {
    final providers = _topProviders;
    if (providers.isEmpty) {
      return _card(
        child: const Text('No completed orders yet to rank providers',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      );
    }

    return _card(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < providers.length; i++)
            _rankedListTile(
              rank: i + 1,
              title: providers[i].name,
              subtitle:
                  '${providers[i].completedOrders} completed · ${providers[i].totalOrders} total',
              trailing: '₹${providers[i].revenue.toStringAsFixed(0)}',
              color: const Color(0xFF10B981),
              isLast: i == providers.length - 1,
            ),
        ],
      ),
    );
  }

  // ── Top cities (ranked list) ────────────────────────────────────────

  Widget _buildTopCities(_AnalyticsMetrics m) {
    final cities = _topCities;
    if (cities.isEmpty) {
      return _card(
        child: const Text('No city data yet',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      );
    }

    return _card(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < cities.length; i++)
            _rankedListTile(
              rank: i + 1,
              title: cities[i].key,
              subtitle: '${cities[i].value} bookings',
              trailing: '${cities[i].value}',
              color: const Color(0xFF3B82F6),
              isLast: i == cities.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _rankedListTile({
    required int rank,
    required String title,
    required String subtitle,
    required String trailing,
    required Color color,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Text('$rank',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(trailing,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ── Customer / provider growth (dual-line) ──────────────────────────

  Widget _buildGrowthChart(_AnalyticsMetrics m) {
    final customerTrend = _customerGrowthTrend;
    final providerTrend = _providerGrowthTrend;
    final days = _trendDayBuckets;
    final maxY = [
      ...customerTrend,
      ...providerTrend,
    ].fold<int>(0, (p, v) => v > p ? v : p);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(const Color(0xFF3B82F6), 'Customers'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF10B981), 'Providers'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: m.isMobile ? 180 : 220,
            child: maxY <= 0
                ? const Center(
                    child: Text('No new signups in this window',
                        style: TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 13)))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: (maxY + 1).toDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                            color: const Color(0xFFE2E8F0), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (v, mm) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 10)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (v, mm) {
                              final i = v.toInt();
                              if (i < 0 || i >= days.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_dayLabel(days[i]),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF64748B))),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < customerTrend.length; i++)
                              FlSpot(i.toDouble(), customerTrend[i].toDouble()),
                          ],
                          isCurved: true,
                          color: const Color(0xFF3B82F6),
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < providerTrend.length; i++)
                              FlSpot(i.toDouble(), providerTrend[i].toDouble()),
                          ],
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Repeat customers / cancellation rate pills ──────────────────────

  Widget _buildInsightPills(_AnalyticsMetrics m) {
    final repeatRate = _repeatCustomerRate;
    final cancelRate = _cancellationRate;

    final pills = [
      _insightPill(
        title: 'Repeat Customers',
        value: '${repeatRate.toStringAsFixed(1)}%',
        icon: Icons.repeat_rounded,
        color: const Color(0xFF6366F1),
        subtitle: 'of customers ordered more than once',
      ),
      _insightPill(
        title: 'Cancellation Rate',
        value: '${cancelRate.toStringAsFixed(1)}%',
        icon: Icons.cancel_outlined,
        color: const Color(0xFFEF4444),
        subtitle: 'of all orders were cancelled/rejected',
      ),
    ];

    if (m.isMobile) {
      return Column(
        children: [
          pills[0],
          const SizedBox(height: 12),
          pills[1],
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: pills[0]),
        const SizedBox(width: 16),
        Expanded(child: pills[1]),
      ],
    );
  }

  Widget _insightPill({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
                Text(subtitle,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// DATA MODELS
// ===========================================================================

enum _OrderBucket { pending, accepted, completed, cancelled }

class _OrderRecord {
  final String id;
  final _OrderBucket status;
  final double amount;
  final DateTime? createdAt;
  final String serviceType;
  final String city;
  final String? providerId;
  final String? customerId;
  final double? rating;

  _OrderRecord({
    required this.id,
    required this.status,
    required this.amount,
    required this.createdAt,
    required this.serviceType,
    required this.city,
    required this.providerId,
    required this.customerId,
    required this.rating,
  });
}

class _JoinRecord {
  final String id;
  final DateTime? joinedAt;
  _JoinRecord({required this.id, required this.joinedAt});
}

class _ProviderMeta {
  final String name;
  final String? city;
  final double? rating;
  _ProviderMeta({required this.name, this.city, this.rating});
}

class _ProviderRank {
  final String id;
  final String name;
  int totalOrders = 0;
  int completedOrders = 0;
  double revenue = 0;
  _ProviderRank({required this.id, required this.name});
}

// ===========================================================================
// RESPONSIVE METRICS — Android-first, scales to tablet.
// ===========================================================================

class _AnalyticsMetrics {
  final bool isMobile;
  final double pagePadding;
  final int statsColumns;
  final double statsAspectRatio;

  _AnalyticsMetrics._({
    required this.isMobile,
    required this.pagePadding,
    required this.statsColumns,
    required this.statsAspectRatio,
  });

  factory _AnalyticsMetrics.of(double width) {
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1000;
    return _AnalyticsMetrics._(
      isMobile: isMobile,
      pagePadding: isMobile ? 16 : (isTablet ? 24 : 28),
      // 2 columns on phones keeps every stat card readable at Android
      // widths (~360-420px) without cramming 6 cards into 3 columns.
      statsColumns: isMobile ? 2 : (isTablet ? 3 : 3),
      statsAspectRatio: isMobile ? 1.15 : 1.3,
    );
  }
}