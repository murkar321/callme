import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Brings in OrderService.adminDeclineOrder() — the single source of
// truth for updating order status + notifying the customer. This page
// never writes 'status'/'declineReason' directly to Firestore itself
// for DECLINES, so admin declines stay consistent with provider/user
// cancellations.
//
// NOTE (accept flow): as of this file, order_service.dart does not
// expose an adminAcceptOrder() equivalent, so _acceptOrder() below
// writes the status update directly to Firestore instead of going
// through OrderService. This means an admin Accept currently does
// NOT send a customer/provider notification the way Decline does.
// If/when you add an OrderService.adminAcceptOrder() method, swap the
// body of _acceptOrder() to call it so both actions stay consistent.
import 'package:callme/provider/order_service.dart';

class AdminOrdersPage extends StatefulWidget {
  /// Optional query to pre-fill the search box with — used when arriving
  /// here from the dashboard's header search so the two feel connected
  /// instead of the search box being decorative.
  final String initialSearch;

  const AdminOrdersPage({super.key, this.initialSearch = ''});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // The stream is created exactly once and held here — NOT inside build().
  // Creating a fresh `.snapshots()` call inside build() (as StreamBuilder's
  // `stream:` argument often ends up being written) makes Firestore tear
  // down and re-establish a brand new listener on every rebuild, which
  // includes every keystroke typed into the search box. That's what made
  // the page feel laggy/flickery and re-fetch the whole collection
  // repeatedly. Holding a single stream instance fixes both.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream =
      _firestore.collection('orders').snapshots();

  // ── Search & Filter State ─────────────────────────────────────────────────
  String _search = '';
  String _statusFilter = 'all';
  String _serviceFilter = 'all';
  late final TextEditingController _searchController =
      TextEditingController(text: widget.initialSearch);
  final FocusNode _searchFocus = FocusNode();

  // ── Cached docs from stream (so filters don't require stream rebuild) ─────
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDocs = [];

  // ── Buffers the latest snapshot so no update is ever dropped even if
  //    several snapshots arrive before a frame has rendered. Previously the
  //    sync was skipped entirely while a callback was pending, which could
  //    leave the list showing a stale snapshot until the next Firestore
  //    event happened to arrive. ─────────────────────────────────────────────
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _pendingDocs;
  bool _syncScheduled = false;

  // ── Tracks which order IDs currently have a decline action in flight,
  // so the button/dialog can't be double-submitted for the same order
  // while awaiting Firestore.
  final Set<String> _decliningIds = {};

  // NEW: same pattern as _decliningIds, but for the accept action, kept
  // as a separate set so an in-flight accept and an in-flight decline on
  // two different orders never interfere with each other's loading state.
  final Set<String> _acceptingIds = {};

  // ─── Services ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _kServices = [
    {'key': 'all',       'label': 'All',       'icon': Icons.dashboard_rounded},
    {'key': 'cleaning',  'label': 'Cleaning',  'icon': Icons.cleaning_services},
    {'key': 'plumbing',  'label': 'Plumbing',  'icon': Icons.plumbing},
    {'key': 'education', 'label': 'Education', 'icon': Icons.school_rounded},
    {'key': 'hotel',     'label': 'Hotel',     'icon': Icons.hotel_rounded},
    {'key': 'resorts',   'label': 'Resorts',   'icon': Icons.beach_access_rounded},
    {'key': 'laundry',   'label': 'Laundry',   'icon': Icons.local_laundry_service},
    {'key': 'water',     'label': 'Water',     'icon': Icons.water_drop_rounded},
    {'key': 'salon',     'label': 'Salon',     'icon': Icons.content_cut},
    {'key': 'civil',     'label': 'Civil',     'icon': Icons.construction},
  ];

  static const List<String> _kStatuses = [
    'all', 'pending', 'accepted', 'completed', 'cancelled', 'rejected',
  ];

  // Quick-select reasons shown as chips in the decline dialog — "Provider
  // not available" first since that's the most common admin decline case.
  static const List<String> _kDeclineReasons = [
    'Provider not available',
    'No provider accepted in time',
    'Service not available in this area',
    'Duplicate booking',
    'Customer requested cancellation',
  ];

  // ─── Computed filtered list ────────────────────────────────────────────────
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filtered {
    final q = _search.toLowerCase().trim();
    return _allDocs.where((doc) {
      final d = doc.data();
      final svc    = (d['serviceType'] ?? d['serviceName'] ?? '').toString().toLowerCase();
      final status = _statusOf(d);
      final uname  = _userName(d).toLowerCase();
      final email  = (d['email']  ?? d['user']?['email']  ?? '').toString().toLowerCase();
      final phone  = (d['phone']  ?? d['user']?['phone']  ?? '').toString().toLowerCase();
      final prov   = _providerName(d).toLowerCase();
      final oid    = (d['orderId'] ?? doc.id).toString().toLowerCase();

      final matchSearch = q.isEmpty ||
          uname.contains(q)  ||
          email.contains(q)  ||
          phone.contains(q)  ||
          svc.contains(q)    ||
          prov.contains(q)   ||
          oid.contains(q);

      final matchStatus  = _statusFilter == 'all' || status == _statusFilter;
      final matchService = _serviceFilter == 'all' || svc.contains(_serviceFilter);

      return matchSearch && matchStatus && matchService;
    }).toList();
  }

  Map<String, int> get _svcCounts {
    final counts = <String, int>{'all': _allDocs.length};
    for (final svc in _kServices.skip(1)) {
      final k = svc['key'] as String;
      counts[k] = _allDocs.where((doc) {
        final t = (doc.data()['serviceType'] ?? doc.data()['serviceName'] ?? '')
            .toString().toLowerCase();
        return t.contains(k);
      }).length;
    }
    return counts;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Status read tolerantly — matches the same fallback chain used on the
  /// dashboard so a card's badge and the dashboard's counts never disagree.
  String _statusOf(Map<String, dynamic> d) {
    final candidates = <dynamic>[
      d['status'],
      d['orderStatus'],
      d['order_status'],
      d['bookingStatus'],
      (d['order'] is Map) ? (d['order'] as Map)['status'] : null,
    ];
    for (final c in candidates) {
      final s = c?.toString().trim().toLowerCase();
      if (s != null && s.isNotEmpty) return s;
    }
    return 'pending';
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'accepted':  return const Color(0xFF16A34A);
      case 'completed': return const Color(0xFF2563EB);
      case 'cancelled': return const Color(0xFFDC2626);
      case 'rejected':  return const Color(0xFFEF4444);
      default:          return const Color(0xFFF59E0B);
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'accepted':  return Icons.check_circle_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'rejected':  return Icons.remove_circle_rounded;
      default:          return Icons.pending_actions_rounded;
    }
  }

  IconData _serviceIcon(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean'))    return Icons.cleaning_services;
    if (v.contains('plumb'))    return Icons.plumbing;
    if (v.contains('educ'))     return Icons.school_rounded;
    if (v.contains('hotel'))    return Icons.hotel_rounded;
    if (v.contains('resort'))   return Icons.beach_access_rounded;
    if (v.contains('laundry'))  return Icons.local_laundry_service;
    if (v.contains('water'))    return Icons.water_drop_rounded;
    if (v.contains('salon'))    return Icons.content_cut;
    if (v.contains('electric')) return Icons.electrical_services;
    if (v.contains('civil'))    return Icons.construction;
    return Icons.miscellaneous_services;
  }

  Color _serviceColor(String s) {
    final v = s.toLowerCase();
    if (v.contains('clean'))    return const Color(0xFF0EA5E9);
    if (v.contains('plumb'))    return const Color(0xFF64748B);
    if (v.contains('educ'))     return const Color(0xFF8B5CF6);
    if (v.contains('hotel'))    return const Color(0xFFF59E0B);
    if (v.contains('resort'))   return const Color(0xFF10B981);
    if (v.contains('laundry'))  return const Color(0xFF3B82F6);
    if (v.contains('water'))    return const Color(0xFF06B6D4);
    if (v.contains('salon'))    return const Color(0xFFEC4899);
    if (v.contains('electric')) return const Color(0xFFEAB308);
    if (v.contains('civil'))    return const Color(0xFF78716C);
    return const Color(0xFF6366F1);
  }

  String _providerName(Map<String, dynamic> d) {
    final top = (d['providerName'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    final nested = (d['provider']?['providerName'] ?? '').toString().trim();
    return nested.isNotEmpty ? nested : 'Not Assigned';
  }

  String _userName(Map<String, dynamic> d) {
    final top = (d['userName'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    return (d['user']?['name'] ?? 'Unknown User').toString();
  }

  String _address(Map<String, dynamic> d) {
    final top = (d['address'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    return (d['location']?['address'] ?? '-').toString();
  }

  /// Reads the userId off an order doc tolerantly — some flows write it
  /// top-level, others nest it under `user`.
  String _userIdOf(Map<String, dynamic> d) {
    final top = (d['userId'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    return (d['user']?['id'] ?? '').toString().trim();
  }

  String _fmt(Timestamp? t, {String pattern = 'dd MMM yyyy'}) =>
      t == null ? '-' : DateFormat(pattern).format(t.toDate());

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Syncs `_allDocs` from a fresh snapshot on every emission — not just
  /// when the document count changes, and never silently drops a snapshot.
  /// Sorting happens up front so the cached list is always render-ready.
  void _syncDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    docs.sort((a, b) {
      final aT = a.data()['createdAt'];
      final bT = b.data()['createdAt'];
      if (aT is Timestamp && bT is Timestamp) {
        return bT.toDate().compareTo(aT.toDate());
      }
      return 0;
    });

    _pendingDocs = docs;
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      final latest = _pendingDocs;
      if (mounted && latest != null) {
        setState(() => _allDocs = latest);
      }
    });
  }

  // ─── Admin accept flow ─────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
      ),
    );
  }

  /// Quick confirm-then-accept — no reason needed for accepting (unlike
  /// decline, there's nothing to explain to the customer), so this stays
  /// a single tap + confirmation instead of a full dialog form.
  ///
  /// NOTE: writes directly to Firestore rather than going through
  /// OrderService, because no adminAcceptOrder() equivalent exists yet.
  /// This does NOT trigger a customer/provider notification the way
  /// OrderService.adminDeclineOrder() does for declines. Wire this into
  /// OrderService once an accept method is added there, so both actions
  /// notify consistently.
  Future<void> _acceptOrder(Map<String, dynamic> d, String docId) async {
    final userName = _userName(d);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
            SizedBox(width: 10),
            Expanded(child: Text('Accept Order', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Text(
          'Mark $userName\'s booking as accepted?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Accept Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _acceptingIds.add(docId));

    try {
      await _firestore.collection('orders').doc(docId).update({
        'status': 'accepted',
        'lastActionBy': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      _showSnack('Order accepted.');
    } catch (e) {
      debugPrint('[AdminOrdersPage] accept failed for $docId: $e');
      _showSnack('Failed to accept order: $e', isError: true);
    } finally {
      if (mounted) setState(() => _acceptingIds.remove(docId));
    }
  }

  // ─── Admin decline flow ────────────────────────────────────────────────────

  /// Opens the decline dialog for one order, then calls
  /// OrderService.adminDeclineOrder() so status update + customer
  /// notification stay in one place with every other order action.
  Future<void> _declineOrder(Map<String, dynamic> d, String docId) async {
    final userName   = _userName(d);
    final userId     = _userIdOf(d);
    final serviceType = (d['serviceType'] ?? d['serviceName'] ?? 'service').toString();

    if (userId.isEmpty) {
      _showSnack(
        'Cannot decline — this order has no userId on file, so the '
        'customer can\'t be notified.',
        isError: true,
      );
      return;
    }

    final reasonController = TextEditingController();
    String? selectedChip;

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.gpp_bad_outlined, color: Color(0xFFDC2626)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Decline Order', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Declining $userName\'s $serviceType booking. '
                      'The customer will be notified with this reason.',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Quick reasons',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kDeclineReasons.map((r) {
                        final selected = selectedChip == r;
                        return ChoiceChip(
                          label: Text(r, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedChip = r;
                              reasonController.text = r;
                              reasonController.selection = TextSelection.collapsed(
                                offset: reasonController.text.length,
                              );
                            });
                          },
                          selectedColor: const Color(0xFFDC2626).withOpacity(.15),
                          labelStyle: TextStyle(
                            color: selected ? const Color(0xFFDC2626) : const Color(0xFF374151),
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      onChanged: (_) => setDialogState(() => selectedChip = null),
                      decoration: InputDecoration(
                        labelText: 'Reason for customer',
                        hintText: 'e.g. Provider not available in your area',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  onPressed: () {
                    final r = reasonController.text.trim();
                    if (r.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please enter or select a reason')),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, r);
                  },
                  child: const Text('Decline Order'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.trim().isEmpty) return; // cancelled
    if (!mounted) return;

    setState(() => _decliningIds.add(docId));

    try {
      await OrderService.adminDeclineOrder(
        orderId:     docId,
        userId:      userId,
        serviceType: serviceType,
        reason:      reason.trim(),
        adminId:     FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      _showSnack('Order declined — $userName has been notified.');
    } catch (e) {
      debugPrint('[AdminOrdersPage] decline failed for $docId: $e');
      _showSnack('Failed to decline order: $e', isError: true);
    } finally {
      if (mounted) setState(() => _decliningIds.remove(docId));
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Apply status bar style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1E40AF),
      statusBarIconBrightness: Brightness.light,
    ));

    // ── ADAPTIVE SCALING ─────────────────────────────────────────────────
    // Same sw/390 pattern used elsewhere in the app (AccountPage,
    // business_page.dart etc): scale paddings/sizes off a 390-logical-px
    // baseline (a common phone width) and clamp so very small or very
    // large/tablet screens never look cramped or comically oversized.
    // Kept local to this page — doesn't touch any other screen.
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final scale = (screenWidth / 390).clamp(0.85, 1.25);

    // ── FIX: BOTTOM OVERFLOW ROOT CAUSE ──────────────────────────────────
    // The service-filter and status-filter chip rows below live inside
    // fixed-height SizedBoxes. On devices with a larger system font scale
    // (accessibility "Large text" setting, or certain OEM display-size
    // presets — the same class of device-specific quirk we saw with MIUI
    // notification channels), the text inside those chips renders taller
    // than the fixed box allows, and Flutter throws a
    // "RenderFlex overflowed by X pixels on the bottom" error/yellow strip.
    //
    // Fix: clamp the effective text scale for this whole page so chip
    // rows can never be pushed past their fixed height, regardless of the
    // user's OS font-size setting. This is a page-level fix that never
    // touches other screens.
    final clampedScale = mq.textScaler.scale(1.0).clamp(0.85, 1.15);

    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(clampedScale)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FB),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _ordersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _allDocs.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
            }
            if (snapshot.hasError) {
              return _errorState(snapshot.error.toString());
            }

            if (snapshot.hasData) {
              _syncDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data!.docs,
              ));
            }

            if (_allDocs.isEmpty) return _emptyState();

            final filtered = _filtered;
            final svcCounts = _svcCounts;

            return Column(
              children: [
                _buildHeader(filtered.length, svcCounts, scale),
                Expanded(
                  child: filtered.isEmpty
                      ? _noMatch()
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(14 * scale, 14 * scale, 14 * scale, 32 * scale),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _orderCard(filtered[i].data(), filtered[i].id, scale),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(int count, Map<String, int> svcCounts, double scale) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top; // respect status bar
    final isNarrow = mq.size.width < 360; // small-phone breakpoint

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28 * scale)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: EdgeInsets.fromLTRB(16 * scale, 14 * scale, 16 * scale, 0),
              child: Row(
                children: [
                  Container(
                    width: 46 * scale,
                    height: 46 * scale,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(14 * scale),
                    ),
                    child: Icon(Icons.shopping_bag_rounded,
                        color: Colors.white, size: 24 * scale),
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNarrow ? 'Orders' : 'Orders Dashboard',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20 * scale,
                            letterSpacing: .2,
                          ),
                        ),
                        Text(
                          '$count ${count == 1 ? 'order' : 'orders'} shown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white60, fontSize: 12 * scale),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20 * scale),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8 * scale, color: Colors.greenAccent),
                        SizedBox(width: 5 * scale),
                        Text('Live',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11 * scale,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14 * scale),

            // ── Search bar ── lives outside the StreamBuilder's rebuild path
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14 * scale),
                elevation: 0,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  // Use onChanged — setState only touches _search, not stream
                  onChanged: (v) => setState(() => _search = v),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(fontSize: 14 * scale, color: const Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: isNarrow ? 'Search orders…' : 'Search name, phone, email, order ID…',
                    hintStyle: TextStyle(fontSize: 13 * scale, color: const Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
                    prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF6B7280), size: 20 * scale),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded, size: 18 * scale, color: const Color(0xFF6B7280)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _searchFocus.requestFocus();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12 * scale),

            // ── Service filter chips ──
            // Height scales with `scale` and content stays inside a
            // FittedBox, so narrow phones and large-font settings both
            // shrink content instead of overflowing.
            SizedBox(
              height: 84 * scale,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                physics: const BouncingScrollPhysics(),
                itemCount: _kServices.length,
                itemBuilder: (_, i) {
                  final svc = _kServices[i];
                  final k = svc['key'] as String;
                  final selected = _serviceFilter == k;
                  final cnt = svcCounts[k] ?? 0;
                  return GestureDetector(
                    onTap: () => setState(() => _serviceFilter = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 64 * scale,
                      margin: EdgeInsets.only(right: 8 * scale),
                      padding: EdgeInsets.symmetric(vertical: 6 * scale),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: selected
                            ? Border.all(color: Colors.white, width: 1.5)
                            : null,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              svc['icon'] as IconData,
                              size: 20 * scale,
                              color: selected ? const Color(0xFF4F46E5) : Colors.white70,
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              svc['label'] as String,
                              style: TextStyle(
                                fontSize: 9 * scale,
                                fontWeight: FontWeight.w700,
                                color: selected ? const Color(0xFF4F46E5) : Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (k != 'all') ...[
                              SizedBox(height: 3 * scale),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 1 * scale),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF4F46E5) : Colors.white.withOpacity(.22),
                                  borderRadius: BorderRadius.circular(6 * scale),
                                ),
                                child: Text(
                                  '$cnt',
                                  style: TextStyle(
                                    fontSize: 8 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: selected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 10 * scale),

            // ── Status filter chips ──
            SizedBox(
              height: 42 * scale,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                physics: const BouncingScrollPhysics(),
                itemCount: _kStatuses.length,
                itemBuilder: (_, i) {
                  final s = _kStatuses[i];
                  final selected = _statusFilter == s;
                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(right: 8 * scale),
                      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 8 * scale),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(40 * scale),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          s.toUpperCase(),
                          maxLines: 1,
                          style: TextStyle(
                            color: selected
                                ? (s == 'all' ? const Color(0xFF4F46E5) : _statusColor(s))
                                : Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 11 * scale,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 16 * scale),
          ],
        ),
      ),
    );
  }

  // ─── Order Card ────────────────────────────────────────────────────────────
  Widget _orderCard(Map<String, dynamic> d, String docId, double scale) {
    final orderId      = (d['orderId'] ?? docId).toString();
    final userName     = _userName(d);
    final email        = (d['email']  ?? d['user']?['email'] ?? '-').toString();
    final phone        = (d['phone']  ?? d['user']?['phone'] ?? '-').toString();
    final service      = (d['serviceType'] ?? d['serviceName'] ?? 'Service').toString();
    final providerName = _providerName(d);
    final address      = _address(d);
    final status       = _statusOf(d);
    final paid         = d['payment']?['paid'] ?? false;
    final payMethod    = (d['payment']?['method'] ?? '-').toString().toUpperCase();
    final amount       = d['totalAmount'] ?? d['payment']?['totalAmount'] ?? 0;
    final services     = (d['services'] as List?)?.cast<dynamic>() ?? [];
    final time         = d['schedule']?['time'] ?? d['time'] ?? '-';
    final providerId   = (d['providerId'] ?? d['provider']?['providerId'] ?? '-').toString();
    final visitType    = (d['visitType'] ?? '-').toString();
    final note         = (d['note'] ?? d['location']?['note'] ?? '').toString().trim();
    final isCompleted  = d['isCompleted'] ?? false;
    final isAssigned   = d['isAssigned'] ?? false;
    final lastActionBy = (d['lastActionBy'] ?? '-').toString();
    final cancelledBy  = (d['cancelledBy'] ?? '').toString().trim().toLowerCase();
    final declineReason = (d['declineReason'] ?? d['adminDeclineNote'] ?? '').toString().trim();

    final Timestamp? schedDate   = d['schedule']?['date'] ?? d['date'];
    final Timestamp? createdAt   = d['createdAt'];
    final Timestamp? acceptedAt  = d['acceptedAt'];
    final Timestamp? completedAt = d['completedAt'];
    final Timestamp? updatedAt   = d['updatedAt'];

    final svcColor = _serviceColor(service);

    // Admin can only act on orders that haven't already reached a
    // terminal state — no point accepting/declining a
    // completed/cancelled/rejected order a second time.
    final canAct = status == 'pending' || status == 'accepted';
    // Accept only makes sense while still pending — an already-accepted
    // order has nothing left to "accept".
    final canAccept = status == 'pending';
    final isDeclining = _decliningIds.contains(docId);
    final isAccepting = _acceptingIds.contains(docId);

    return Container(
      margin: EdgeInsets.only(bottom: 14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Coloured top strip ──
          Container(
            padding: EdgeInsets.fromLTRB(16 * scale, 16 * scale, 16 * scale, 14 * scale),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [svcColor, svcColor.withOpacity(.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54 * scale,
                  height: 54 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.2),
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  child: Icon(_serviceIcon(service), color: Colors.white, size: 28 * scale),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16 * scale,
                          letterSpacing: .3,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 13 * scale),
                      ),
                      SizedBox(height: 8 * scale),
                      Wrap(
                        spacing: 6 * scale,
                        runSpacing: 5 * scale,
                        children: [
                          _badge(_statusIcon(status), status.toUpperCase(),
                              Colors.white, Colors.white.withOpacity(.2), scale),
                          _badge(
                            paid ? Icons.check_circle_outline : Icons.unpublished_outlined,
                            paid ? 'PAID' : 'UNPAID',
                            Colors.white, Colors.white.withOpacity(.2), scale,
                          ),
                          if (isAssigned)
                            _badge(Icons.engineering_rounded, 'ASSIGNED',
                                Colors.white, Colors.white.withOpacity(.2), scale),
                          if (isCompleted)
                            _badge(Icons.task_alt_rounded, 'DONE',
                                Colors.white, Colors.white.withOpacity(.2), scale),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── STICKY ACTION BAR — Accept / Decline, kept right at the top
          // of the card (immediately under the coloured strip) so an
          // admin triaging many orders never has to scroll down to act.
          // Only shown while the order is still actionable.
          if (canAct)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 12 * scale),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFEEF0F5))),
              ),
              child: Row(
                children: [
                  if (canAccept) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isAccepting || isDeclining ? null : () => _acceptOrder(d, docId),
                        icon: isAccepting
                            ? SizedBox(
                                width: 15 * scale,
                                height: 15 * scale,
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.check_circle_outline, size: 18 * scale),
                        label: Text(
                          isAccepting ? 'Accepting…' : 'Accept',
                          style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: EdgeInsets.symmetric(vertical: 11 * scale),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14 * scale)),
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * scale),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isDeclining || isAccepting ? null : () => _declineOrder(d, docId),
                      icon: isDeclining
                          ? SizedBox(
                              width: 15 * scale,
                              height: 15 * scale,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.gpp_bad_outlined, size: 18 * scale),
                      label: Text(
                        isDeclining ? 'Declining…' : 'Decline',
                        style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: EdgeInsets.symmetric(vertical: 11 * scale),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14 * scale)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Card body ──
          Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount banner
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(16 * scale),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(fontSize: 11 * scale, color: const Color(0xFF6B7280)),
                          ),
                          SizedBox(height: 3 * scale),
                          Text(
                            '₹$amount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: svcColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 24 * scale,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 11 * scale, vertical: 6 * scale),
                        decoration: BoxDecoration(
                          color: svcColor.withOpacity(.1),
                          borderRadius: BorderRadius.circular(10 * scale),
                        ),
                        child: Text(
                          payMethod,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: svcColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16 * scale),

                // Timeline
                _sectionTitle('Timeline', scale),
                SizedBox(height: 10 * scale),
                _timelineRow([
                  ('Created',   _fmt(createdAt,   pattern: 'dd MMM yy\nhh:mm a')),
                  ('Accepted',  _fmt(acceptedAt,  pattern: 'dd MMM yy\nhh:mm a')),
                  ('Completed', _fmt(completedAt, pattern: 'dd MMM yy\nhh:mm a')),
                ], svcColor, scale),

                SizedBox(height: 16 * scale),

                // Customer
                _sectionTitle('Customer', scale),
                SizedBox(height: 8 * scale),
                _infoGrid([
                  (Icons.person_rounded,         'Name',       userName),
                  (Icons.phone_rounded,           'Phone',      phone),
                  (Icons.email_rounded,           'Email',      email),
                  (Icons.location_on_rounded,     'Address',    address),
                  if (note.isNotEmpty)
                    (Icons.note_rounded,          'Note',       note),
                  if (visitType.isNotEmpty && visitType != '-')
                    (Icons.directions_walk_rounded, 'Visit Type', visitType),
                ], scale),

                SizedBox(height: 16 * scale),

                // Provider
                _sectionTitle('Provider', scale),
                SizedBox(height: 8 * scale),
                _infoGrid([
                  (Icons.engineering_rounded,        'Provider',    providerName),
                  (Icons.badge_rounded,              'Provider ID', providerId),
                  (Icons.schedule_rounded,           'Visit Time',  '${_fmt(schedDate)} • $time'),
                  (Icons.update_rounded,             'Updated',     _fmt(updatedAt, pattern: 'dd MMM yy • hh:mm a')),
                  (Icons.person_pin_circle_rounded,  'Last Action', lastActionBy.toUpperCase()),
                ], scale),

                SizedBox(height: 16 * scale),

                // Order meta
                _sectionTitle('Order Details', scale),
                SizedBox(height: 8 * scale),
                _infoGrid([
                  (Icons.receipt_long_rounded,   'Order ID', orderId),
                  (Icons.calendar_month_rounded,  'Created',  _fmt(createdAt, pattern: 'dd MMM yyyy • hh:mm a')),
                ], scale),

                // Services list
                if (services.isNotEmpty) ...[
                  SizedBox(height: 16 * scale),
                  _sectionTitle('Selected Services', scale),
                  SizedBox(height: 8 * scale),
                  Wrap(
                    spacing: 7 * scale,
                    runSpacing: 7 * scale,
                    children: services.map((item) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 7 * scale),
                        decoration: BoxDecoration(
                          color: svcColor.withOpacity(.07),
                          borderRadius: BorderRadius.circular(40 * scale),
                          border: Border.all(color: svcColor.withOpacity(.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12 * scale, color: svcColor),
                            SizedBox(width: 5 * scale),
                            Text(
                              item.toString(),
                              style: TextStyle(
                                color: svcColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11 * scale,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // ── Decline reason (shown once an order HAS been
                // declined/rejected/cancelled, by anyone) — surfaces the
                // reason customers were given, right on the admin card.
                if (declineReason.isNotEmpty) ...[
                  SizedBox(height: 16 * scale),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12 * scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14 * scale),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16 * scale, color: const Color(0xFFDC2626)),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cancelledBy == 'admin'
                                    ? 'Declined by Admin'
                                    : cancelledBy.isNotEmpty
                                        ? 'Declined by ${cancelledBy[0].toUpperCase()}${cancelledBy.substring(1)}'
                                        : 'Decline Reason',
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              SizedBox(height: 3 * scale),
                              Text(
                                declineReason,
                                style: TextStyle(fontSize: 12.5 * scale, color: const Color(0xFF7F1D1D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Note: the old bottom "Decline Order" button has been
                // replaced by the sticky action bar above the card body —
                // intentionally not duplicated down here.
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline Row ──────────────────────────────────────────────────────────
  Widget _timelineRow(List<(String, String)> items, Color color, double scale) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final hasValue = item.$2 != '-';
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34 * scale,
                      height: 34 * scale,
                      decoration: BoxDecoration(
                        color: hasValue ? color.withOpacity(.12) : const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasValue ? color.withOpacity(.4) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13 * scale,
                            color: hasValue ? color : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9 * scale,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      item.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9 * scale,
                        fontWeight: FontWeight.w700,
                        color: hasValue ? const Color(0xFF1F2937) : const Color(0xFFD1D5DB),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Expanded(
                  child: Container(
                    height: 1.5,
                    margin: EdgeInsets.only(bottom: 44 * scale),
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Info Grid ─────────────────────────────────────────────────────────────
  Widget _infoGrid(List<(IconData, String, String)> items, double scale) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(7 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Icon(item.$1, size: 15 * scale, color: const Color(0xFF4F46E5)),
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10 * scale,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 1 * scale),
                      Text(
                        item.$3.isEmpty ? '-' : item.$3,
                        style: TextStyle(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Section Title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, double scale) {
    return Row(
      children: [
        Container(
          width: 3 * scale,
          height: 14 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(2 * scale),
          ),
        ),
        SizedBox(width: 8 * scale),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13 * scale,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // ─── Badge ─────────────────────────────────────────────────────────────────
  Widget _badge(IconData icon, String label, Color fg, Color bg, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 4 * scale), 
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(40 * scale)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11 * scale, color: fg),
          SizedBox(width: 4 * scale),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 9 * scale),
          ),
        ],
      ),
    );
  }

  // ─── Empty / No Match / Error ──────────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 36, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Orders Yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _noMatch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No matching orders',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try adjusting filters or search term',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}