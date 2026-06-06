import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'provider_profile_page.dart';
import '../provider/order_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ══════════════════════════════════════════════════════════════════════════════

class _C {
  static const bg        = Color(0xFFF7F8FC);
  static const indigo    = Color(0xFF5C6BC0);
  static const indigoSft = Color(0xFFE8EAF6);
  static const green     = Color(0xFF2E7D32);
  static const greenSft  = Color(0xFFE8F5E9);
  static const red       = Color(0xFFD84315);
  static const redSft    = Color(0xFFFBE9E7);
  static const orange    = Color(0xFFE65100);
  static const orangeSft = Color(0xFFFFF3E0);
  static const blue      = Color(0xFF1565C0);
  static const blueSft   = Color(0xFFE3F2FD);
  static const text      = Color(0xFF212121);
  static const textSub   = Color(0xFF757575);
  static const divider   = Color(0xFFF0F0F0);
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE
// ══════════════════════════════════════════════════════════════════════════════

class BusinessDashboardPage extends StatefulWidget {
  final String providerId;
  final String businessName;
  final String serviceType;

  const BusinessDashboardPage({
    super.key,
    required this.providerId,
    required this.businessName,
    required this.serviceType,
  });

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage>
    with SingleTickerProviderStateMixin {

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late final TabController _tab;

  // Streams cached once — never recreated on rebuild
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _providerStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>>    _availableStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>>    _myJobsStream;

  String get _svcNorm  => widget.serviceType.trim().toLowerCase();
  String get _myUid    => _auth.currentUser?.uid ?? '';

  int _availableCount = 0;
  int _myJobsCount    = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _initStreams();
  }

  void _initStreams() {
    _providerStream = _db
        .collection('providers')
        .doc(widget.providerId)
        .snapshots();

    // ── Available jobs ────────────────────────────────────────────────────
    // Fetch all pending/enquiry orders for this serviceType that are unassigned.
    // Client-side we additionally hide orders this provider already declined,
    // so multiple providers can all see and race to accept the same order.
    _availableStream = _db
        .collection('orders')
        .where('serviceType', isEqualTo: _svcNorm)
        .where('status',      whereIn: ['pending', 'enquiry'])
        .where('isAssigned',  isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();

    // ── My jobs ───────────────────────────────────────────────────────────
    // Orders where THIS provider's userId is stored as the winning acceptor.
    _myJobsStream = _db
        .collection('orders')
        .where('acceptedByUid', isEqualTo: _myUid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FIRESTORE ACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Accept an order — uses a transaction to guard against multiple providers
  /// trying to accept the same order simultaneously.
  Future<void> _acceptOrder(String orderId, Map<String, dynamic> data) async {
    // Capture notification fields BEFORE the transaction runs, so even if
    // Firestore updates first the notification still has valid data.
    final customerId = (data['userId'] ?? '').toString();
    final svcLabel   = widget.serviceType;

    try {
      final ref = _db.collection('orders').doc(orderId);

      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);

        if (!snap.exists) throw _AppErr('not_found');

        final d      = snap.data()!;
        final status = (d['status'] ?? '').toString().toLowerCase();

        // Guard: already taken by another provider
        if (d['isAssigned'] == true)
          throw _AppErr('already_assigned');

        // Guard: order is no longer in an acceptable state
        if (status != 'pending' && status != 'enquiry')
          throw _AppErr('not_available');

        tx.update(ref, {
          // Provider identity — stored in two shapes for backward compatibility
          'providerId':     widget.providerId,
          'providerUserId': _myUid,
          'acceptedByUid':  _myUid,         // used by _myJobsStream query
          'providerName':   widget.businessName,
          'provider': {
            'providerId':     widget.providerId,
            'providerUserId': _myUid,
            'providerName':   widget.businessName,
          },

          'status':       'accepted',
          'isAssigned':   true,
          'acceptedAt':   FieldValue.serverTimestamp(),
          'updatedAt':    FieldValue.serverTimestamp(),
          'lastActionBy': 'provider',

          // Remove this provider from any earlier decline list if present
          'declinedBy': FieldValue.arrayRemove([_myUid]),
        });
      });

      // Notify the customer — runs AFTER the transaction commits
      await OrderService.notifyUser(
        userId:  customerId,
        orderId: orderId,
        title:   '🎉 Booking Accepted!',
        body:    '${widget.businessName} accepted your $svcLabel booking.',
        type:    'booking_accepted',
      );

      _snack('Job accepted! Check "My Jobs" tab.', _C.green, Icons.check_circle_rounded);
    } on _AppErr catch (e) {
      switch (e.code) {
        case 'already_assigned':
          _snack('Another provider just accepted this job.', _C.orange, Icons.info_rounded);
          break;
        case 'not_available':
          _snack('This order is no longer available.', _C.red, Icons.warning_rounded);
          break;
        default:
          _snack('Order not found. It may have been removed.', _C.red, Icons.error_rounded);
      }
    } catch (_) {
      _snack('Could not accept job. Please try again.', _C.red, Icons.error_rounded);
    }
  }

  /// Decline an available order — marks this provider as having declined it
  /// without removing it from the pool so other providers can still accept.
  Future<void> _declineAvailable(
      String orderId, String note, Map<String, dynamic> data) async {
    final customerId = (data['userId'] ?? '').toString();
    try {
      await _db.collection('orders').doc(orderId).update({
        // Track which providers declined so we can hide from them client-side
        'declinedBy':         FieldValue.arrayUnion([_myUid]),
        'providerCancelNote': note.isEmpty ? 'Provider declined' : note,
        'lastActionBy':       'provider',
        'updatedAt':          FieldValue.serverTimestamp(),
        // status stays 'pending' / 'enquiry' — order stays visible to others
      });

      await OrderService.notifyUser(
        userId:  customerId,
        orderId: orderId,
        title:   '🔄 Finding Another Provider',
        body:    "A provider was unavailable. We're finding another for you.",
        type:    'booking_rejected',
      );

      _snack('Order declined.', _C.orange, Icons.thumb_down_rounded);
    } catch (_) {
      _snack('Could not decline. Try again.', _C.red, Icons.error_rounded);
    }
  }

  /// Mark an accepted job as complete.
  Future<void> _completeOrder(String orderId, Map<String, dynamic> data) async {
    final customerId = (data['userId'] ?? '').toString();
    try {
      await _db.collection('orders').doc(orderId).update({
        'status':       'completed',
        'isCompleted':  true,
        'completedAt':  FieldValue.serverTimestamp(),
        'updatedAt':    FieldValue.serverTimestamp(),
        'lastActionBy': 'provider',
      });

      await OrderService.notifyUser(
        userId:  customerId,
        orderId: orderId,
        title:   '✅ Service Completed',
        body:    'Your ${widget.serviceType} service by ${widget.businessName} is complete.',
        type:    'booking_completed',
      );

      _snack('Marked as completed!', _C.green, Icons.verified_rounded);
    } catch (_) {
      _snack('Could not complete. Try again.', _C.red, Icons.error_rounded);
    }
  }

  /// Cancel an already-accepted job.
  Future<void> _cancelAccepted(
      String orderId, String note, Map<String, dynamic> data) async {
    final customerId = (data['userId'] ?? '').toString();
    try {
      await _db.collection('orders').doc(orderId).update({
        'status':             'cancelled',
        'providerCancelNote': note.isEmpty ? 'Provider cancelled' : note,
        'cancelledBy':        'provider',
        'cancelledAt':        FieldValue.serverTimestamp(),

        // Release the order so another provider can potentially pick it up
        'isAssigned':         false,
        'acceptedByUid':      FieldValue.delete(),
        'providerId':         FieldValue.delete(),
        'providerUserId':     FieldValue.delete(),
        'providerName':       FieldValue.delete(),
        'provider':           FieldValue.delete(),

        'updatedAt':          FieldValue.serverTimestamp(),
        'lastActionBy':       'provider',
      });

      await OrderService.notifyUser(
        userId:  customerId,
        orderId: orderId,
        title:   '❌ Booking Cancelled',
        body:    '${widget.businessName} cancelled your booking. '
                 'Reason: ${note.isEmpty ? "Not specified" : note}',
        type:    'booking_cancelled',
      );

      _snack('Order cancelled.', _C.orange, Icons.cancel_rounded);
    } catch (_) {
      _snack('Could not cancel. Try again.', _C.red, Icons.error_rounded);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _showDeclineDialog(String id, Map<String, dynamic> data) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => _ReasonDialog(
        title:     'Decline Job',
        subtitle:  'Optionally tell the customer why.',
        hint:      'Reason for declining...',
        btnLabel:  'Decline',
        btnColor:  _C.orange,
        keepLabel: 'Keep',
        ctrl:      ctrl,
        onConfirm: () async {
          Navigator.pop(ctx);
          await _declineAvailable(id, ctrl.text.trim(), data);
        },
      ),
    );
    ctrl.dispose();
  }

  Future<void> _showCancelDialog(String id, Map<String, dynamic> data) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => _ReasonDialog(
        title:     'Cancel Job',
        subtitle:  "Tell the customer why you're cancelling.",
        hint:      'Cancellation reason...',
        btnLabel:  'Cancel Job',
        btnColor:  _C.red,
        keepLabel: 'Keep Job',
        ctrl:      ctrl,
        onConfirm: () async {
          Navigator.pop(ctx);
          await _cancelAccepted(id, ctrl.text.trim(), data);
        },
      ),
    );
    ctrl.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SNACK
  // ══════════════════════════════════════════════════════════════════════════

  void _snack(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin:          const EdgeInsets.all(16),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _providerStream,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: _C.bg,
            body: Center(child: CircularProgressIndicator(color: _C.indigo)),
          );
        }

        final provider = snap.data?.data() ?? {};
        if (provider['status'] != 'approved') return _PendingScaffold();

        return Scaffold(
          backgroundColor: _C.bg,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _DashHeader(
                businessName:   widget.businessName,
                serviceType:    widget.serviceType,
                providerId:     widget.providerId,
                tabController:  _tab,
                availableCount: _availableCount,
                myJobsCount:    _myJobsCount,
                onProfile:      () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>
                      ProviderProfilePage(providerId: widget.providerId)),
                ),
              )),
            ],
            body: TabBarView(
              controller: _tab,
              children: [
                _JobsList(
                  stream:       _availableStream,
                  isAvailable:  true,
                  myUid:        _myUid,
                  onCount: (c) {
                    if (_availableCount != c) setState(() => _availableCount = c);
                  },
                  onAccept:  _acceptOrder,
                  onDecline: _showDeclineDialog,
                  serviceType:  widget.serviceType,
                  businessName: widget.businessName,
                ),
                _JobsList(
                  stream:       _myJobsStream,
                  isAvailable:  false,
                  myUid:        _myUid,
                  onCount: (c) {
                    if (_myJobsCount != c) setState(() => _myJobsCount = c);
                  },
                  onComplete: _completeOrder,
                  onCancel:   _showCancelDialog,
                  serviceType:  widget.serviceType,
                  businessName: widget.businessName,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TYPED ERROR
// ══════════════════════════════════════════════════════════════════════════════

class _AppErr implements Exception {
  final String code;
  const _AppErr(this.code);
}

// ══════════════════════════════════════════════════════════════════════════════
// PENDING SCAFFOLD
// ══════════════════════════════════════════════════════════════════════════════

class _PendingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor:  Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation:        0,
        leading:  BackButton(color: _C.text),
        title: const Text('Dashboard',
            style: TextStyle(color: _C.text, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                  color: _C.indigoSft, shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 52, color: _C.indigo),
            ),
            const SizedBox(height: 28),
            const Text('Pending Approval',
                style: TextStyle(
                    fontSize:   24,
                    fontWeight: FontWeight.w700,
                    color:      _C.text)),
            const SizedBox(height: 10),
            const Text(
              "Your account is under review.\nYou'll be notified once approved.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.textSub, fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color:        _C.orangeSft,
                borderRadius: BorderRadius.circular(30),
                border:       Border.all(color: _C.orange.withOpacity(.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.circle, color: _C.orange, size: 9),
                SizedBox(width: 10),
                Text('Status: Under Review',
                    style: TextStyle(
                        color:      _C.orange,
                        fontWeight: FontWeight.w600,
                        fontSize:   13)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _DashHeader extends StatelessWidget {
  final String        businessName;
  final String        serviceType;
  final String        providerId;
  final TabController tabController;
  final int           availableCount;
  final int           myJobsCount;
  final VoidCallback  onProfile;

  const _DashHeader({
    required this.businessName,
    required this.serviceType,
    required this.providerId,
    required this.tabController,
    required this.availableCount,
    required this.myJobsCount,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  Colors.white,
        border: Border(bottom: BorderSide(color: _C.divider)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color:        _C.indigoSft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: _C.indigo, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.w700,
                        color:      _C.text)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: _C.green, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(serviceType,
                      style: const TextStyle(
                          color: _C.textSub, fontSize: 12)),
                ]),
              ],
            )),
            GestureDetector(
              onTap: onProfile,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color:        _C.indigoSft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded,
                    color: _C.indigo, size: 22),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _StatChip(
                label: 'Available',
                count: availableCount,
                color: _C.indigo,
                bg:    _C.indigoSft),
            const SizedBox(width: 10),
            _StatChip(
                label: 'My Jobs',
                count: myJobsCount,
                color: _C.green,
                bg:    _C.greenSft),
          ]),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color:        const Color(0xFFF0F2F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller:           tabController,
              indicator: BoxDecoration(
                color:        Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize:        TabBarIndicatorSize.tab,
              dividerColor:         Colors.transparent,
              labelColor:           _C.indigo,
              unselectedLabelColor: _C.textSub,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Available Jobs'),
                Tab(text: 'My Jobs'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int    count;
  final Color  color;
  final Color  bg;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:        color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text('$count',
                  style: TextStyle(
                      color:      color,
                      fontWeight: FontWeight.w800,
                      fontSize:   14)),
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color:      color,
                  fontSize:   12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// JOBS LIST
// ══════════════════════════════════════════════════════════════════════════════

class _JobsList extends StatefulWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final bool        isAvailable;
  final String      myUid;
  final String      serviceType;
  final String      businessName;
  final void Function(int) onCount;

  final Future<void> Function(String, Map<String, dynamic>)?  onAccept;
  final Future<void> Function(String, Map<String, dynamic>)?  onDecline;
  final Future<void> Function(String, Map<String, dynamic>)?  onComplete;
  final Future<void> Function(String, Map<String, dynamic>)?  onCancel;

  const _JobsList({
    required this.stream,
    required this.isAvailable,
    required this.myUid,
    required this.serviceType,
    required this.businessName,
    required this.onCount,
    this.onAccept,
    this.onDecline,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<_JobsList> createState() => _JobsListState();
}

class _JobsListState extends State<_JobsList>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: _C.indigo));
        }

        final allDocs = snap.data?.docs ?? [];

        // ── Client-side filter for Available tab ─────────────────────────
        // Hide orders that THIS provider already declined so they don't see
        // them again, while other providers still can.
        final docs = widget.isAvailable
            ? allDocs.where((d) {
                final declinedBy = (d.data()['declinedBy'] as List?) ?? [];
                return !declinedBy.contains(widget.myUid);
              }).toList()
            : allDocs;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onCount(docs.length);
        });

        if (docs.isEmpty) {
          return _EmptyState(
              isAvailable: widget.isAvailable,
              serviceType: widget.serviceType);
        }

        return ListView.builder(
          padding:               const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount:             docs.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries:  true,
          itemBuilder: (_, i) => _JobCard(
            doc:          docs[i] as DocumentSnapshot<Map<String, dynamic>>,
            isAvailable:  widget.isAvailable,
            serviceType:  widget.serviceType,
            businessName: widget.businessName,
            onAccept:     widget.onAccept,
            onDecline:    widget.onDecline,
            onComplete:   widget.onComplete,
            onCancel:     widget.onCancel,
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// JOB CARD
// ══════════════════════════════════════════════════════════════════════════════

class _JobCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final bool        isAvailable;
  final String      serviceType;
  final String      businessName;
  final Future<void> Function(String, Map<String, dynamic>)?  onAccept;
  final Future<void> Function(String, Map<String, dynamic>)?  onDecline;
  final Future<void> Function(String, Map<String, dynamic>)?  onComplete;
  final Future<void> Function(String, Map<String, dynamic>)?  onCancel;

  const _JobCard({
    required this.doc,
    required this.isAvailable,
    required this.serviceType,
    required this.businessName,
    this.onAccept,
    this.onDecline,
    this.onComplete,
    this.onCancel,
  });

  Color    _sc(String s) => const {
    'accepted':  _C.green,
    'completed': _C.blue,
    'cancelled': _C.red,
    'enquiry':   _C.orange,
  }[s] ?? _C.indigo;

  Color    _sf(String s) => const {
    'accepted':  _C.greenSft,
    'completed': _C.blueSft,
    'cancelled': _C.redSft,
    'enquiry':   _C.orangeSft,
  }[s] ?? _C.indigoSft;

  IconData _si(String s) => {
    'accepted':  Icons.check_circle_rounded,
    'completed': Icons.verified_rounded,
    'cancelled': Icons.cancel_rounded,
    'enquiry':   Icons.help_rounded,
  }[s] ?? Icons.schedule_rounded;

  String _safeStr(dynamic v, [String fallback = '-']) =>
      (v?.toString() ?? '').isEmpty ? fallback : v.toString();

  @override
  Widget build(BuildContext context) {
    final data     = doc.data()!;
    final status   = (data['status'] ?? 'pending').toString().toLowerCase();

    // ── Safely read nested maps ──────────────────────────────────────────
    final payment  = (data['payment']  is Map) ? data['payment']  as Map : {};
    final location = (data['location'] is Map) ? data['location'] as Map : {};
    final schedule = (data['schedule'] is Map) ? data['schedule'] as Map : {};

    final ts      = data['createdAt'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('dd MMM • hh:mm a').format(ts.toDate()) : '-';

    final rawAmt = payment['totalAmount'];
    final amount = rawAmt is num ? rawAmt.toDouble() : 0.0;

    // address can live at location.address OR location.fullAddress
    final address = _safeStr(location['address'] ?? location['fullAddress']);
    // schedule time can be a string or nested
    final schedTime = _safeStr(
      schedule['time'] ?? schedule['scheduledTime'] ?? schedule['date']);

    final sc   = _sc(status);
    final soft = _sf(status);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: _C.divider),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status stripe ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color:        sc.withOpacity(.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_si(status), color: sc, size: 13),
              ),
              const SizedBox(width: 8),
              Text(status.toUpperCase(),
                  style: TextStyle(
                      color:         sc,
                      fontWeight:    FontWeight.w700,
                      fontSize:      11,
                      letterSpacing: 1)),
              const Spacer(),
              Icon(Icons.access_time_rounded, size: 11, color: _C.textSub),
              const SizedBox(width: 4),
              Text(dateStr,
                  style: const TextStyle(color: _C.textSub, fontSize: 11)),
            ]),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              // Customer row
              Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: _C.indigoSft,
                      borderRadius: BorderRadius.circular(13)),
                  child: Center(
                    child: Text(
                      (_safeStr(data['userName'], 'U'))
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                          color:      _C.indigo,
                          fontWeight: FontWeight.bold,
                          fontSize:   20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_safeStr(data['userName'], 'Customer'),
                        style: const TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                            color:      _C.text)),
                    const SizedBox(height: 2),
                    Text(serviceType,
                        style: const TextStyle(
                            color: _C.textSub, fontSize: 12)),
                  ],
                )),
                // Amount badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color:        _C.greenSft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    amount == 0
                        ? 'TBD'
                        : '₹${amount % 1 == 0 ? amount.toInt() : amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color:      _C.green,
                        fontWeight: FontWeight.w700,
                        fontSize:   13),
                  ),
                ),
              ]),

              const SizedBox(height: 12),
              const Divider(height: 1, color: _C.divider),
              const SizedBox(height: 12),

              _InfoRow(Icons.phone_rounded,
                  _safeStr(data['phone']), _C.indigo, _C.indigoSft),
              const SizedBox(height: 8),
              _InfoRow(Icons.location_on_rounded,
                  address, _C.red, _C.redSft),
              const SizedBox(height: 8),
              _InfoRow(Icons.schedule_rounded,
                  schedTime, _C.green, _C.greenSft),

              if (_safeStr(data['note']).isNotEmpty &&
                  _safeStr(data['note']) != '-') ...[
                const SizedBox(height: 8),
                _InfoRow(Icons.notes_rounded,
                    _safeStr(data['note']), _C.orange, _C.orangeSft),
              ],

              const SizedBox(height: 14),

              // ── Actions ────────────────────────────────────────────
              if (status == 'pending' || status == 'enquiry')
                Row(children: [
                  Expanded(child: _ActionBtn(
                    label: 'Accept',
                    icon:  Icons.check_rounded,
                    bg:    _C.indigo,
                    fg:    Colors.white,
                    onTap: () => onAccept?.call(doc.id, data),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionBtn(
                    label:    'Decline',
                    icon:     Icons.close_rounded,
                    bg:       _C.redSft,
                    fg:       _C.red,
                    outlined: true,
                    onTap: () => onDecline?.call(doc.id, data),
                  )),
                ]),

              if (status == 'accepted')
                Row(children: [
                  Expanded(child: _ActionBtn(
                    label: 'Mark Complete',
                    icon:  Icons.verified_rounded,
                    bg:    _C.green,
                    fg:    Colors.white,
                    onTap: () => onComplete?.call(doc.id, data),
                  )),
                  const SizedBox(width: 10),
                  _ActionIconBtn(
                    icon:  Icons.close_rounded,
                    color: _C.red,
                    bg:    _C.redSft,
                    onTap: () => onCancel?.call(doc.id, data),
                  ),
                ]),

              if (status == 'completed')
                _StatusBadge(Icons.verified_rounded,
                    'Job Completed', _C.blue, _C.blueSft),

              if (status == 'cancelled')
                _StatusBadge(Icons.cancel_rounded,
                    'Job Cancelled', _C.red, _C.redSft),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL STATELESS WIDGETS (unchanged)
// ══════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   value;
  final Color    ic;
  final Color    bg;

  const _InfoRow(this.icon, this.value, this.ic, this.bg);

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: ic, size: 13),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
                fontSize: 13, color: _C.text, height: 1.4),
          ),
        ),
      ),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        bg;
  final Color        fg;
  final bool         outlined;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:        outlined ? Colors.transparent : bg,
          border:       outlined ? Border.all(color: bg, width: 1.5) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: fg, size: 15),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color:      fg,
                  fontWeight: FontWeight.w700,
                  fontSize:   13)),
        ]),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final Color        bg;
  final VoidCallback? onTap;

  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final Color    bg;

  const _StatusBadge(this.icon, this.label, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 7),
        Text(label,
            style: TextStyle(
                color:      color,
                fontWeight: FontWeight.w700,
                fontSize:   13)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool   isAvailable;
  final String serviceType;

  const _EmptyState({
    required this.isAvailable,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
                color: _C.indigoSft, shape: BoxShape.circle),
            child: Icon(
              isAvailable
                  ? Icons.work_outline_rounded
                  : Icons.assignment_outlined,
              size:  48,
              color: _C.indigo,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isAvailable ? 'No Available Jobs' : 'No Jobs Yet',
            style: const TextStyle(
                fontSize:   21,
                fontWeight: FontWeight.w700,
                color:      _C.text),
          ),
          const SizedBox(height: 8),
          Text(
            isAvailable
                ? 'New $serviceType orders will appear here.'
                : 'Jobs you accept will show here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _C.textSub, fontSize: 13, height: 1.6),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REASON DIALOG
// ══════════════════════════════════════════════════════════════════════════════

class _ReasonDialog extends StatelessWidget {
  final String               title;
  final String               subtitle;
  final String               hint;
  final String               btnLabel;
  final Color                btnColor;
  final String               keepLabel;
  final TextEditingController ctrl;
  final VoidCallback         onConfirm;

  const _ReasonDialog({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.btnLabel,
    required this.btnColor,
    required this.keepLabel,
    required this.ctrl,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        btnColor.withOpacity(.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.info_outline_rounded,
                color: btnColor, size: 26),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w700,
                  color:      _C.text)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _C.textSub, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines:   3,
            decoration: InputDecoration(
              hintText:  hint,
              hintStyle: const TextStyle(color: _C.textSub, fontSize: 13),
              filled:    true,
              fillColor: const Color(0xFFF7F8FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide:   BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side:  const BorderSide(color: _C.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(keepLabel,
                    style: const TextStyle(color: _C.textSub)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  elevation:       0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(btnLabel,
                    style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}