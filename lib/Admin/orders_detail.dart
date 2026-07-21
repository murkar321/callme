import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Brings in OrderService.adminDeclineOrder() — the single source of
// truth for updating order status + notifying the customer. This page
// never writes 'status'/'declineReason' directly to Firestore itself,
// so admin declines stay consistent with provider/user cancellations.
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

  // ─── Admin decline flow ────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
      ),
    );
  }

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
    final mq = MediaQuery.of(context);
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
                _buildHeader(filtered.length, svcCounts),
                Expanded(
                  child: filtered.isEmpty
                      ? _noMatch()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _orderCard(filtered[i].data(), filtered[i].id),
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
  Widget _buildHeader(int count, Map<String, int> svcCounts) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top; // respect status bar

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: topPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Orders Dashboard',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: .2,
                          ),
                        ),
                        Text(
                          '$count ${count == 1 ? 'order' : 'orders'} shown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                        SizedBox(width: 5),
                        Text('Live',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Search bar ── lives outside the StreamBuilder's rebuild path
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 0,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  // Use onChanged — setState only touches _search, not stream
                  onChanged: (v) => setState(() => _search = v),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    hintText: 'Search name, phone, email, order ID…',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF6B7280)),
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

            const SizedBox(height: 12),

            // ── Service filter chips ──
            // FIX: bumped height 76 -> 84 and wrapped inner Column in a
            // FittedBox so content scales down instead of overflowing the
            // fixed-height box on large-font devices.
            SizedBox(
              height: 84,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      width: 64,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(16),
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
                              size: 20,
                              color: selected ? const Color(0xFF4F46E5) : Colors.white70,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              svc['label'] as String,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: selected ? const Color(0xFF4F46E5) : Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (k != 'all') ...[
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF4F46E5) : Colors.white.withOpacity(.22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$cnt',
                                  style: TextStyle(
                                    fontSize: 8,
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

            const SizedBox(height: 10),

            // ── Status filter chips ──
            // FIX: bumped height 38 -> 42 and wrapped label in FittedBox for
            // the same large-font-overflow protection as the service chips.
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _kStatuses.length,
                itemBuilder: (_, i) {
                  final s = _kStatuses[i];
                  final selected = _statusFilter == s;
                  return GestureDetector(
                    onTap: () => setState(() => _statusFilter = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withOpacity(.14),
                        borderRadius: BorderRadius.circular(40),
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
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Order Card ────────────────────────────────────────────────────────────
  Widget _orderCard(Map<String, dynamic> d, String docId) {
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

    // Admin can only decline orders that haven't already reached a
    // terminal state — no point declining a completed/cancelled/rejected
    // order a second time.
    final canDecline = status == 'pending' || status == 'accepted';
    final isDeclining = _decliningIds.contains(docId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [svcColor, svcColor.withOpacity(.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_serviceIcon(service), color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          _badge(_statusIcon(status), status.toUpperCase(),
                              Colors.white, Colors.white.withOpacity(.2)),
                          _badge(
                            paid ? Icons.check_circle_outline : Icons.unpublished_outlined,
                            paid ? 'PAID' : 'UNPAID',
                            Colors.white, Colors.white.withOpacity(.2),
                          ),
                          if (isAssigned)
                            _badge(Icons.engineering_rounded, 'ASSIGNED',
                                Colors.white, Colors.white.withOpacity(.2)),
                          if (isCompleted)
                            _badge(Icons.task_alt_rounded, 'DONE',
                                Colors.white, Colors.white.withOpacity(.2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Card body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '₹$amount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: svcColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: svcColor.withOpacity(.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          payMethod,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: svcColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Timeline
                _sectionTitle('Timeline'),
                const SizedBox(height: 10),
                _timelineRow([
                  ('Created',   _fmt(createdAt,   pattern: 'dd MMM yy\nhh:mm a')),
                  ('Accepted',  _fmt(acceptedAt,  pattern: 'dd MMM yy\nhh:mm a')),
                  ('Completed', _fmt(completedAt, pattern: 'dd MMM yy\nhh:mm a')),
                ], svcColor),

                const SizedBox(height: 16),

                // Customer
                _sectionTitle('Customer'),
                const SizedBox(height: 8),
                _infoGrid([
                  (Icons.person_rounded,         'Name',       userName),
                  (Icons.phone_rounded,           'Phone',      phone),
                  (Icons.email_rounded,           'Email',      email),
                  (Icons.location_on_rounded,     'Address',    address),
                  if (note.isNotEmpty)
                    (Icons.note_rounded,          'Note',       note),
                  if (visitType.isNotEmpty && visitType != '-')
                    (Icons.directions_walk_rounded, 'Visit Type', visitType),
                ]),

                const SizedBox(height: 16),

                // Provider
                _sectionTitle('Provider'),
                const SizedBox(height: 8),
                _infoGrid([
                  (Icons.engineering_rounded,        'Provider',    providerName),
                  (Icons.badge_rounded,              'Provider ID', providerId),
                  (Icons.schedule_rounded,           'Visit Time',  '${_fmt(schedDate)} • $time'),
                  (Icons.update_rounded,             'Updated',     _fmt(updatedAt, pattern: 'dd MMM yy • hh:mm a')),
                  (Icons.person_pin_circle_rounded,  'Last Action', lastActionBy.toUpperCase()),
                ]),

                const SizedBox(height: 16),

                // Order meta
                _sectionTitle('Order Details'),
                const SizedBox(height: 8),
                _infoGrid([
                  (Icons.receipt_long_rounded,   'Order ID', orderId),
                  (Icons.calendar_month_rounded,  'Created',  _fmt(createdAt, pattern: 'dd MMM yyyy • hh:mm a')),
                ]),

                // Services list
                if (services.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Selected Services'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: services.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: svcColor.withOpacity(.07),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: svcColor.withOpacity(.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 12, color: svcColor),
                            const SizedBox(width: 5),
                            Text(
                              item.toString(),
                              style: TextStyle(
                                color: svcColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
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
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
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
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                declineReason,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF7F1D1D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Admin action bar — decline order (provider not
                // available, etc). Only shown while the order is still
                // pending/accepted, i.e. before it's already terminal.
                if (canDecline) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isDeclining ? null : () => _declineOrder(d, docId),
                      icon: isDeclining
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.gpp_bad_outlined, size: 18),
                      label: Text(isDeclining ? 'Declining…' : 'Decline Order'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline Row ──────────────────────────────────────────────────────────
  Widget _timelineRow(List<(String, String)> items, Color color) {
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
                      width: 34,
                      height: 34,
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
                            fontSize: 13,
                            color: hasValue ? color : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
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
                    margin: const EdgeInsets.only(bottom: 44),
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
  Widget _infoGrid(List<(IconData, String, String)> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.$1, size: 15, color: const Color(0xFF4F46E5)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.$3.isEmpty ? '-' : item.$3,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          color: Color(0xFF111827),
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
  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  // ─── Badge ─────────────────────────────────────────────────────────────────
  Widget _badge(IconData icon, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 9),
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