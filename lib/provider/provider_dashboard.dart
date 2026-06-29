import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'provider_profile_page.dart';
import '../provider/order_service.dart';

// ═══════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
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
  static const amber     = Color(0xFFF59E0B);
  static const amberSft  = Color(0xFFFFFBEB);
  static const grey      = Color(0xFF6B7280);
  static const greySft   = Color(0xFFF3F4F6);
  static const teal      = Color(0xFF00695C);
  static const tealSft   = Color(0xFFE0F2F1);
  static const text      = Color(0xFF212121);
  static const sub       = Color(0xFF757575);
  static const divider   = Color(0xFFF0F0F0);
}

// ═══════════════════════════════════════════════════════════════
// TERMINOLOGY — maps serviceType → { singular, available, mine }
// ═══════════════════════════════════════════════════════════════
class _Terms {
  final String singular;
  final String availableTab;
  final String myTab;
  final String availableStat;
  final String myStat;

  const _Terms({
    required this.singular,
    required this.availableTab,
    required this.myTab,
    required this.availableStat,
    required this.myStat,
  });

  static _Terms forService(String serviceType) {
    final v = serviceType.toLowerCase().trim();

    if (v.contains('educ') || v.contains('civil')) {
      return const _Terms(
        singular:      'Enquiry',
        availableTab:  'Available Enquiries',
        myTab:         'My Enquiries',
        availableStat: 'Available',
        myStat:        'Active Enquiries',
      );
    }

    if (v.contains('hotel') || v.contains('resort')) {
      return const _Terms(
        singular:      'Booking',
        availableTab:  'Available Bookings',
        myTab:         'My Bookings',
        availableStat: 'Available',
        myStat:        'Active Bookings',
      );
    }

    return const _Terms(
      singular:      'Order',
      availableTab:  'Available Orders',
      myTab:         'My Orders',
      availableStat: 'Available',
      myStat:        'Active Orders',
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════
String _norm(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

bool _svcEq(String a, String b) => _norm(a) == _norm(b);

bool _categoryMatch(
  Map<String, dynamic> orderData,
  List<String> providerCats,
) {
  if (providerCats.isEmpty) return true;
  String orderCat = '';
  for (final k in ['category', 'serviceCategory', 'subCategory', 'jobCategory']) {
    final v = (orderData[k] ?? '').toString().trim();
    if (v.isNotEmpty) { orderCat = v; break; }
  }
  if (orderCat.isEmpty) return true;
  return providerCats.any((c) => _norm(c) == _norm(orderCat));
}

// ─────────────────────────────────────────────────────────────
// FIX: isAssigned can be null/missing in Firestore (treated as
// "not yet set" = unassigned).  We only block if it is
// explicitly true AND a real providerUserId is present.
// ─────────────────────────────────────────────────────────────
bool _isAvailable({
  required Map<String, dynamic> data,
  required String myUid,
  required String svcNorm,
  required List<String> providerCats,
}) {
  final dynamic assignedRaw = data['isAssigned'];
  // Treat null / missing as false (order not yet taken)
  final bool isAssigned = assignedRaw == true;

  final provUid =
      (data['providerUserId'] ?? '').toString().trim();
  final status  =
      (data['status'] ?? '').toString().toLowerCase().trim();
  final reopened = data['reopenForOthers'] == true;

  // Already firmly taken by someone else → skip
  if (isAssigned && provUid.isNotEmpty && provUid != myUid) {
    debugPrint('[avail] SKIP ${data['orderId'] ?? ''}: assigned to $provUid');
    return false;
  }

  // ── Open-status check ───────────────────────────────────────
  // An order is open if:
  //   • status is pending or enquiry (brand-new, not yet taken)
  //   • status is cancelled AND reopenForOthers == true
  //   • status is accepted BUT no provider yet (edge-case recovery)
  //   • isAssigned is null/false (Firestore field missing → open)
  final bool hasRealProvider = provUid.isNotEmpty && provUid != myUid;
  final bool isOpen = status == 'pending'
      || status == 'enquiry'
      || (status == 'cancelled' && reopened)
      || (status == 'accepted' && !hasRealProvider)
      || assignedRaw == null; // ← FIX: field missing means unassigned

  if (!isOpen) {
    debugPrint('[avail] SKIP status="$status" reopened=$reopened '
        'isAssigned=$assignedRaw provUid=$provUid');
    return false;
  }

  // Already declined by this provider → skip
  final declined = (data['declinedBy'] as List?) ?? [];
  if (myUid.isNotEmpty && declined.contains(myUid)) {
    debugPrint('[avail] SKIP: already declined by me');
    return false;
  }

  // Service-type match
  final orderSvc = (data['serviceType'] ?? '').toString().trim();
  if (orderSvc.isNotEmpty && !_svcEq(orderSvc, svcNorm)) {
    debugPrint('[avail] SKIP svc mismatch: "$orderSvc" vs "$svcNorm"');
    return false;
  }

  // Category match
  if (!_categoryMatch(data, providerCats)) {
    debugPrint('[avail] SKIP category mismatch');
    return false;
  }

  return true;
}

// ─────────────────────────────────────────────────────────────
// FIX: "My Jobs" must ONLY show orders that are explicitly and
// firmly assigned to this provider — not pending/open ones.
// ─────────────────────────────────────────────────────────────
bool _isMine({
  required Map<String, dynamic> data,
  required String myUid,
  required String svcNorm,
}) {
  final provUid  = (data['providerUserId'] ?? '').toString().trim();
  final status   = (data['status'] ?? '').toString().toLowerCase().trim();
  final dynamic assignedRaw = data['isAssigned'];

  // Must belong to this provider
  if (provUid != myUid) return false;

  // Service type must match (allow empty for legacy docs)
  final orderSvc = (data['serviceType'] ?? '').toString().trim();
  if (orderSvc.isNotEmpty && !_svcEq(orderSvc, svcNorm)) return false;

  // Only show statuses that mean "this job is mine"
  // 'pending' without assignment = available job, not mine
  const mineStatuses = {'accepted', 'completed', 'cancelled'};
  if (!mineStatuses.contains(status)) return false;

  // Extra guard: if isAssigned is explicitly false and status is
  // somehow 'accepted', treat as available (data inconsistency)
  if (assignedRaw == false && status == 'accepted') {
    debugPrint('[mine] SKIP: isAssigned=false but status=accepted, '
        'treating as available');
    return false;
  }

  return true;
}

Future<void> _launchCall(BuildContext context, String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (cleaned.isEmpty) return;
  final uri = Uri.parse('tel:$cleaned');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cannot launch dialer for $phone'),
        backgroundColor: _C.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// COUNT NOTIFIER
// ═══════════════════════════════════════════════════════════════
class _CountNotifier extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  void update(int v) {
    if (_value != v) {
      _value = v;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE
// ═══════════════════════════════════════════════════════════════
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
  State<BusinessDashboardPage> createState() => _BDPState();
}

class _BDPState extends State<BusinessDashboardPage> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  int    _tab       = 0;
  String _uid       = '';
  bool   _authReady = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _providerSnap;

  // ── Available: 3 streams to catch every case ─────────────────
  // Stream A: isAssigned == false  (standard new orders)
  // Stream B: status IN [pending, enquiry]  (legacy / no isAssigned field)
  // Stream C: isAssigned == null is NOT queryable directly in
  //           Firestore, so we fetch recent docs broadly and
  //           filter client-side via _isAvailable().
  Stream<QuerySnapshot<Map<String, dynamic>>> _availPrimaryStream =
      const Stream.empty();
  Stream<QuerySnapshot<Map<String, dynamic>>> _availLegacyStream =
      const Stream.empty();
  // Broad fallback: recent orders regardless of isAssigned field
  // (catches docs where the field is missing entirely)
  Stream<QuerySnapshot<Map<String, dynamic>>> _availFallbackStream =
      const Stream.empty();

  Stream<QuerySnapshot<Map<String, dynamic>>>? _myStream;

  final _availNotifier = _CountNotifier();
  final _myNotifier    = _CountNotifier();

  ScaffoldMessengerState? _messenger;

  String get _svcNorm => _norm(widget.serviceType);
  late final _Terms _terms = _Terms.forService(widget.serviceType);

  @override
  void initState() {
    super.initState();
    _availNotifier.addListener(_onCountChanged);
    _myNotifier.addListener(_onCountChanged);
    _resolveAuthThenInit();
  }

  Future<void> _resolveAuthThenInit() async {
    if (_auth.currentUser != null) {
      _uid = _auth.currentUser!.uid;
      if (mounted) setState(() => _authReady = true);
      _initStreams();
      return;
    }
    await for (final user in _auth.authStateChanges()) {
      if (user != null) {
        _uid = user.uid;
        if (mounted) {
          setState(() => _authReady = true);
          _initStreams();
        }
        return;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _availNotifier
      ..removeListener(_onCountChanged)
      ..dispose();
    _myNotifier
      ..removeListener(_onCountChanged)
      ..dispose();
    super.dispose();
  }

  void _onCountChanged() { if (mounted) setState(() {}); }

  void _initStreams() {
    _providerSnap = _db
        .collection('providers')
        .doc(widget.providerId)
        .snapshots();

    // ── Stream A: explicitly unassigned ──────────────────────
    _availPrimaryStream = _db
        .collection('orders')
        .where('isAssigned', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots();

    // ── Stream B: legacy / status-based ──────────────────────
    _availLegacyStream = _db
        .collection('orders')
        .where('status', whereIn: ['pending', 'enquiry'])
        .orderBy('createdAt', descending: true)
        .limit(150)
        .snapshots();

    // ── Stream C: broad fallback — catches docs where
    //    isAssigned field was never written (null/missing).
    //    We pull recent orders and filter client-side.
    _availFallbackStream = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

    // ── My Jobs: assigned to this provider ────────────────────
    // FIX: query by providerUserId so only truly assigned orders
    // come through. _isMine() then filters out any 'pending'
    // docs that slipped in due to data inconsistency.
    _myStream = _uid.isEmpty
        ? null
        : _db
            .collection('orders')
            .where('providerUserId', isEqualTo: _uid)
            .orderBy('createdAt', descending: true)
            .limit(200)
            .snapshots();

    if (mounted) setState(() {});
  }

  void _retry() {
    if (!mounted) return;
    setState(() {
      _availPrimaryStream  = const Stream.empty();
      _availLegacyStream   = const Stream.empty();
      _availFallbackStream = const Stream.empty();
      _myStream            = null;
      _authReady           = false;
    });
    _resolveAuthThenInit();
  }

  void _goTab(int i) {
    if (mounted && _tab != i) setState(() => _tab = i);
  }

  void _snack(String msg, Color color, IconData icon) {
    _messenger
      ?..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
              style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
  }

  // ─── Firestore actions ────────────────────────────────────────

  Future<void> _accept(String id, Map<String, dynamic> data) async {
    if (_uid.isEmpty) {
      _snack('Session error — please restart the app.', _C.red, Icons.error_outline);
      return;
    }
    final custId = (data['userId'] ?? '').toString();
    final ref    = _db.collection('orders').doc(id);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('not_found');
        final cur = snap.data()!;

        // Already taken by someone else
        final curProvider = (cur['providerUserId'] ?? '').toString().trim();
        if (cur['isAssigned'] == true &&
            curProvider.isNotEmpty &&
            curProvider != _uid) {
          throw Exception('taken');
        }

        final st       = (cur['status'] ?? '').toString().toLowerCase();
        final reopened = cur['reopenForOthers'] == true;
        final dynamic assignedRaw = cur['isAssigned'];
        final hasNoProvider = curProvider.isEmpty;

        final canAccept = st == 'pending'
            || st == 'enquiry'
            || (st == 'cancelled' && reopened)
            || (st == 'accepted' && hasNoProvider)
            || assignedRaw == null; // missing field = open

        if (!canAccept) throw Exception('taken');

        tx.update(ref, {
          'providerId':      widget.providerId,
          'providerUserId':  _uid,
          'providerName':    widget.businessName,
          'serviceType':     _svcNorm,
          'status':          'accepted',
          'isAssigned':      true,          // always written on accept
          'reopenForOthers': false,
          'acceptedAt':      FieldValue.serverTimestamp(),
          'updatedAt':       FieldValue.serverTimestamp(),
          'lastActionBy':    'provider',
        });
      });

      _notify(custId, id,
        '✅ Provider Found!',
        '${widget.businessName} accepted your ${widget.serviceType} booking.',
        NotificationType.bookingAccepted);

      if (!mounted) return;
      _goTab(1);
      _snack(
        '${_terms.singular} accepted! Moved to ${_terms.myTab}.',
        _C.green,
        Icons.check_circle_rounded,
      );
    } on Exception catch (e) {
      final m = e.toString();
      if (m.contains('taken')) {
        _snack('Already accepted by another provider.', _C.orange, Icons.info_outline_rounded);
      } else if (m.contains('not_found')) {
        _snack('${_terms.singular} no longer exists.', _C.red, Icons.error_outline);
      } else {
        debugPrint('[accept] $e');
        _snack('Accept failed — try again.', _C.red, Icons.error_outline);
      }
    } catch (e) {
      debugPrint('[accept] $e');
      _snack('Accept failed — try again.', _C.red, Icons.error_outline);
    }
  }

  Future<void> _decline(String id, String note, Map<String, dynamic> data) async {
    final custId = (data['userId'] ?? '').toString();
    try {
      await _db.collection('orders').doc(id).update({
        'declinedBy':      FieldValue.arrayUnion([_uid]),
        'declineNote':     note.isEmpty ? 'Provider declined' : note,
        'updatedAt':       FieldValue.serverTimestamp(),
        'providerUserId':  null,
        'providerId':      null,
        'providerName':    null,
        'isAssigned':      false,
        'reopenForOthers': true,
        'status':          'pending',
        'lastActionBy':    'provider',
      });
      _notify(custId, id,
        '🔄 Finding Another Provider',
        'A provider was unavailable. Finding another for you.',
        NotificationType.bookingRejected);
      _snack('Declined successfully.', _C.orange, Icons.thumb_down_rounded);
    } catch (e) {
      debugPrint('[decline] $e');
      _snack('Could not decline. Try again.', _C.red, Icons.error_rounded);
    }
  }

  Future<void> _complete(String id, Map<String, dynamic> data) async {
    final custId = (data['userId'] ?? '').toString();
    try {
      await _db.collection('orders').doc(id).update({
        'status':       'completed',
        'isCompleted':  true,
        'isAssigned':   false,
        'completedAt':  FieldValue.serverTimestamp(),
        'updatedAt':    FieldValue.serverTimestamp(),
        'lastActionBy': 'provider',
      });
      _notify(custId, id,
        '✅ Service Completed',
        'Your ${widget.serviceType} service by ${widget.businessName} is complete! '
        'Please rate your experience.',
        NotificationType.serviceCompleted);
      _snack('Marked as completed!', _C.green, Icons.verified_rounded);
    } catch (e) {
      debugPrint('[complete] $e');
      _snack('Could not complete. Try again.', _C.red, Icons.error_rounded);
    }
  }

  Future<void> _cancel(String id, String note, Map<String, dynamic> data) async {
    final custId = (data['userId'] ?? '').toString();
    try {
      await _db.collection('orders').doc(id).update({
        'status':             'cancelled',
        'isAssigned':         false,
        'reopenForOthers':    true,
        'providerCancelNote': note.isEmpty ? 'Provider cancelled' : note,
        'cancelledBy':        'provider',
        'cancelledAt':        FieldValue.serverTimestamp(),
        'updatedAt':          FieldValue.serverTimestamp(),
        'lastActionBy':       'provider',
        'declinedBy':         FieldValue.arrayUnion([_uid]),
        // Clear provider fields so it becomes truly unassigned
        'providerUserId':     null,
        'providerId':         null,
        'providerName':       null,
      });
      _notify(custId, id,
        '❌ Provider Cancelled',
        '${widget.businessName} cancelled. '
        'Reason: ${note.isEmpty ? "Not specified" : note}. '
        'Finding another provider.',
        NotificationType.bookingRejected);
      _snack(
        '${_terms.singular} cancelled — reopened for others.',
        _C.orange,
        Icons.cancel_rounded,
      );
    } catch (e) {
      debugPrint('[cancel] $e');
      _snack('Could not cancel. Try again.', _C.red, Icons.error_rounded);
    }
  }

  void _notify(String uid, String orderId, String title, String body, String type) {
    if (uid.isEmpty) return;
    OrderService.notifyUser(
      userId: uid, orderId: orderId,
      title: title, body: body, type: type,
    ).catchError((e) => debugPrint('[notify] $e'));
  }

  // ─── Dialogs ──────────────────────────────────────────────────

  Future<void> _showDecline(String id, Map<String, dynamic> data) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _Dialog(
        title:     'Decline ${_terms.singular}',
        subtitle:  '${_terms.singular} stays open for other providers.',
        hint:      'Reason (optional)...',
        btnLabel:  'Decline',
        btnColor:  _C.orange,
        keepLabel: 'Keep',
      ),
    );
    if (!mounted || reason == null) return;
    await _decline(id, reason, data);
  }

  Future<void> _showCancel(String id, Map<String, dynamic> data) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _Dialog(
        title:     'Cancel ${_terms.singular}',
        subtitle:  '${_terms.singular} will reopen for other providers.',
        hint:      'Reason (shown to customer)...',
        btnLabel:  'Cancel ${_terms.singular}',
        btnColor:  _C.red,
        keepLabel: 'Keep ${_terms.singular}',
      ),
    );
    if (!mounted || reason == null) return;
    await _cancel(id, reason, data);
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_authReady) {
      return const Scaffold(
        backgroundColor: _C.bg,
        body: Center(child: CircularProgressIndicator(color: _C.indigo)),
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _providerSnap,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return _ErrorRetry(
              message: 'Could not load your provider profile.\n'
                       'Check your connection and try again.',
              onRetry: _retry,
            );
          }
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _C.indigo));
          }

          final prov = snap.data?.data() ?? {};
          if (prov['status'] != 'approved') return const _PendingBody();

          final business           = (prov['business'] as Map?)?.cast<String, dynamic>() ?? {};
          final photoUrl           = (business['image'] ?? '').toString().trim();
          final rawCats            = (prov['categories'] as List?) ?? [];
          final providerCategories = rawCats.map((e) => e.toString()).toList();

          return Column(children: [
            _Header(
              businessName:     widget.businessName,
              serviceType:      widget.serviceType,
              providerId:       widget.providerId,
              tab:              _tab,
              availCount:       _availNotifier.value,
              myCount:          _myNotifier.value,
              photoUrl:         photoUrl,
              activeCategories: providerCategories,
              terms:            _terms,
              onTab:            _goTab,
              onProfile: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProviderProfilePage(providerId: widget.providerId))),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _AvailTab(
                    key:                const ValueKey('available'),
                    primaryStream:      _availPrimaryStream,
                    legacyStream:       _availLegacyStream,
                    fallbackStream:     _availFallbackStream,
                    myUid:              _uid,
                    svcNorm:            _svcNorm,
                    serviceType:        widget.serviceType,
                    providerCategories: providerCategories,
                    countNotifier:      _availNotifier,
                    terms:              _terms,
                    onAccept:           _accept,
                    onDecline:          _showDecline,
                    onRetry:            _retry,
                  ),
                  _MyTab(
                    key:           const ValueKey('myjobs'),
                    stream:        _myStream,
                    myUid:         _uid,
                    svcNorm:       _svcNorm,
                    serviceType:   widget.serviceType,
                    countNotifier: _myNotifier,
                    terms:         _terms,
                    onComplete:    _complete,
                    onCancel:      _showCancel,
                    onRetry:       _retry,
                  ),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AVAILABLE TAB
// ═══════════════════════════════════════════════════════════════
class _AvailTab extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> primaryStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>> legacyStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>> fallbackStream;
  final String         myUid, svcNorm, serviceType;
  final List<String>   providerCategories;
  final _CountNotifier countNotifier;
  final _Terms         terms;
  final Future<void> Function(String, Map<String, dynamic>) onAccept;
  final Future<void> Function(String, Map<String, dynamic>) onDecline;
  final VoidCallback   onRetry;

  const _AvailTab({
    super.key,
    required this.primaryStream,
    required this.legacyStream,
    required this.fallbackStream,
    required this.myUid,
    required this.svcNorm,
    required this.serviceType,
    required this.providerCategories,
    required this.countNotifier,
    required this.terms,
    required this.onAccept,
    required this.onDecline,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: primaryStream,
      builder: (_, primarySnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: legacyStream,
          builder: (_, legacySnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fallbackStream,
              builder: (_, fallbackSnap) {

                if (primarySnap.hasError) {
                  final err = primarySnap.error.toString();
                  final isIdx = err.contains('failed-precondition') ||
                      err.contains('requires an index');
                  return _ErrorRetry(
                    message: isIdx
                        ? 'Missing Firestore index.\n\n'
                          'Create in Firebase Console → Firestore → Indexes:\n'
                          'Collection: orders\n'
                          'Fields: isAssigned ASC, createdAt DESC'
                        : 'Could not load ${terms.availableTab.toLowerCase()}.\n$err',
                    onRetry: onRetry,
                  );
                }

                // Show spinner only if ALL streams are still loading
                final loading =
                    primarySnap.connectionState == ConnectionState.waiting &&
                    !primarySnap.hasData &&
                    legacySnap.connectionState == ConnectionState.waiting &&
                    !legacySnap.hasData &&
                    fallbackSnap.connectionState == ConnectionState.waiting &&
                    !fallbackSnap.hasData;

                if (loading) {
                  return const Center(
                      child: CircularProgressIndicator(color: _C.indigo));
                }

                // ── Merge all three streams, deduplicate by doc ID ──
                final seen    = <String>{};
                final allDocs =
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                for (final doc in (primarySnap.data?.docs ?? [])) {
                  if (seen.add(doc.id)) allDocs.add(doc);
                }
                for (final doc in (legacySnap.data?.docs ?? [])) {
                  if (seen.add(doc.id)) allDocs.add(doc);
                }
                // FIX: fallback catches docs with missing isAssigned field
                for (final doc in (fallbackSnap.data?.docs ?? [])) {
                  if (seen.add(doc.id)) allDocs.add(doc);
                }

                // ── Client-side filter: only truly available ────────
                final docs = allDocs.where((d) => _isAvailable(
                  data:         d.data(),
                  myUid:        myUid,
                  svcNorm:      svcNorm,
                  providerCats: providerCategories,
                )).toList();

                docs.sort((a, b) {
                  final at = (a.data()['createdAt'] as Timestamp?)
                      ?.millisecondsSinceEpoch ?? 0;
                  final bt = (b.data()['createdAt'] as Timestamp?)
                      ?.millisecondsSinceEpoch ?? 0;
                  return bt.compareTo(at);
                });

                countNotifier.update(docs.length);

                if (docs.isEmpty) {
                  final hint = allDocs.isEmpty
                      ? 'No $serviceType ${terms.singular.toLowerCase()}s have been '
                        'placed yet.\n\nNew ${terms.availableTab.toLowerCase()} will '
                        'appear here automatically.'
                      : '${terms.singular}s exist but do not match your profile.\n\n'
                        '${providerCategories.isNotEmpty ? "Your categories: ${providerCategories.join(', ')}" : "Check that your service type matches."}';
                  return _Empty(
                    icon:  Icons.work_outline_rounded,
                    title: 'No ${terms.availableTab}',
                    msg:   hint,
                  );
                }

                return ListView.builder(
                  padding:   const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc  = docs[i];
                    final data = doc.data();
                    return _Card(
                      key:         ValueKey(doc.id),
                      doc:         doc,
                      data:        data,
                      mode:        _Mode.avail,
                      serviceType: serviceType,
                      terms:       terms,
                      onAccept:    () => onAccept(doc.id, data),
                      onDecline:   () => onDecline(doc.id, data),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MY JOBS TAB
// ═══════════════════════════════════════════════════════════════
class _MyTab extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>>? stream;
  final String         myUid, svcNorm, serviceType;
  final _CountNotifier countNotifier;
  final _Terms         terms;
  final Future<void> Function(String, Map<String, dynamic>) onComplete;
  final Future<void> Function(String, Map<String, dynamic>) onCancel;
  final VoidCallback   onRetry;

  const _MyTab({
    super.key,
    required this.stream,
    required this.myUid,
    required this.svcNorm,
    required this.serviceType,
    required this.countNotifier,
    required this.terms,
    required this.onComplete,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (stream == null) {
      return _ErrorRetry(
        message: 'Your session could not be verified.\nPlease retry or sign in again.',
        onRetry: onRetry,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.hasError) {
          return _ErrorRetry(
              message: 'Could not load your ${terms.myTab.toLowerCase()}.\n${snap.error}',
              onRetry: onRetry);
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _C.indigo));
        }

        // FIX: use _isMine() to strictly filter — prevents pending/open
        // orders from leaking into My Jobs tab.
        final docs = (snap.data?.docs ?? []).where((d) => _isMine(
          data:    d.data(),
          myUid:   myUid,
          svcNorm: svcNorm,
        )).toList();

        const ord = {'accepted': 0, 'completed': 1, 'cancelled': 2, 'pending': 3};
        docs.sort((a, b) {
          final as_ = (a.data()['status'] ?? '').toString().toLowerCase();
          final bs  = (b.data()['status'] ?? '').toString().toLowerCase();
          final ap  = ord[as_] ?? 4;
          final bp  = ord[bs]  ?? 4;
          if (ap != bp) return ap.compareTo(bp);
          final at = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bt = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
        });

        final active = docs
            .where((d) =>
                (d.data()['status'] ?? '').toString().toLowerCase() == 'accepted')
            .length;
        countNotifier.update(active);

        if (docs.isEmpty) {
          return _Empty(
            icon:  Icons.assignment_outlined,
            title: 'No ${terms.myTab}',
            msg:   '${terms.singular}s you accept will appear here and update in real‑time.',
          );
        }

        return ListView.builder(
          padding:   const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc    = docs[i];
            final data   = doc.data();
            final status = (data['status'] ?? '').toString().toLowerCase();
            return _Card(
              key:         ValueKey(doc.id),
              doc:         doc,
              data:        data,
              mode:        _Mode.mine,
              serviceType: serviceType,
              terms:       terms,
              onComplete: status == 'accepted' ? () => onComplete(doc.id, data) : null,
              onCancel:   status == 'accepted' ? () => onCancel(doc.id, data)   : null,
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// JOB CARD
// ═══════════════════════════════════════════════════════════════
enum _Mode { avail, mine }
typedef _AsyncCb = Future<void> Function();

class _Card extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final Map<String, dynamic> data;
  final _Mode    mode;
  final String   serviceType;
  final _Terms   terms;
  final _AsyncCb? onAccept;
  final _AsyncCb? onDecline;
  final _AsyncCb? onComplete;
  final _AsyncCb? onCancel;

  const _Card({
    super.key,
    required this.doc,      required this.data,
    required this.mode,     required this.serviceType,
    required this.terms,
    this.onAccept, this.onDecline, this.onComplete, this.onCancel,
  });

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _busy = false;

  Future<void> _run(_AsyncCb? cb) async {
    if (_busy || cb == null) return;
    if (mounted) setState(() => _busy = true);
    try { await cb(); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  static const _col = {
    'pending':   _C.amber,  'enquiry':   _C.orange,
    'accepted':  _C.green,  'completed': _C.blue,
    'cancelled': _C.grey,
  };
  static const _bg = {
    'pending':   _C.amberSft,  'enquiry':   _C.orangeSft,
    'accepted':  _C.greenSft,  'completed': _C.blueSft,
    'cancelled': _C.greySft,
  };
  static const _ico = {
    'pending':   Icons.schedule_rounded,
    'enquiry':   Icons.help_rounded,
    'accepted':  Icons.check_circle_rounded,
    'completed': Icons.verified_rounded,
    'cancelled': Icons.cancel_rounded,
  };

  String _s(dynamic v, [String fb = '']) =>
      (v?.toString() ?? '').trim().isEmpty ? fb : v.toString().trim();

  String _name() {
    for (final k in ['userName','customerName','name','displayName','fullName']) {
      final v = _s(widget.data[k]); if (v.isNotEmpty) return v;
    }
    return 'Customer';
  }

  String _phone() {
    for (final k in ['phone','phoneNumber','mobile','contactPhone']) {
      final v = _s(widget.data[k]); if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _addr() {
    for (final k in ['address','fullAddress','customerAddress']) {
      final v = _s(widget.data[k]); if (v.isNotEmpty) return v;
    }
    final loc = widget.data['location'];
    if (loc is Map) {
      for (final k in ['address','fullAddress','formattedAddress','name']) {
        final v = _s(loc[k]); if (v.isNotEmpty) return v;
      }
      final pts = [loc['street'],loc['area'],loc['city'],loc['state']]
          .map((e) => _s(e)).where((e) => e.isNotEmpty).toList();
      if (pts.isNotEmpty) return pts.join(', ');
    }
    return '';
  }

  String _sched() {
    final sc = widget.data['schedule'];
    if (sc is Map) {
      final rawDate = sc['date'];
      final dateStr = rawDate is Timestamp
          ? DateFormat('dd MMM yyyy').format(rawDate.toDate())
          : _s(rawDate);
      final timeStr = _s(sc['time']);
      if (dateStr.isNotEmpty && timeStr.isNotEmpty) return '$dateStr • $timeStr';
      if (dateStr.isNotEmpty) return dateStr;
      if (timeStr.isNotEmpty) return timeStr;
    }
    for (final k in ['scheduledTime','scheduledDate','appointmentTime']) {
      final v = _s(widget.data[k]); if (v.isNotEmpty) return v;
    }
    return '';
  }

  double _amt() {
    for (final k in ['totalAmount','amount','price','total','cost']) {
      final v = widget.data[k]; if (v is num) return v.toDouble();
    }
    final pay = widget.data['payment'];
    if (pay is Map) {
      for (final k in ['totalAmount','amount','total','price']) {
        final v = pay[k]; if (v is num) return v.toDouble();
      }
    }
    return 0;
  }

  String _note() {
    for (final k in ['note','notes','description','specialRequest']) {
      final v = _s(widget.data[k]); if (v.isNotEmpty) return v;
    }
    return '';
  }

  List<String> _services() {
    final sv = widget.data['services'];
    return sv is List ? sv.map((e) => e.toString()).toList() : [];
  }

  String _category() {
    for (final k in ['category','serviceCategory','subCategory','jobCategory']) {
      final v = _s(widget.data[k]); if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _displayStatus(String raw) =>
      (raw == 'cancelled' && widget.data['reopenForOthers'] == true)
          ? 'reopened'
          : raw;

  bool get _isEnquiry =>
      (widget.data['status'] ?? '').toString().toLowerCase() == 'enquiry';

  @override
  Widget build(BuildContext context) {
    final rawStatus  = (widget.data['status'] ?? 'pending').toString().toLowerCase();
    final dispStatus = _displayStatus(rawStatus);

    final sc   = dispStatus == 'reopened' ? _C.orange : (_col[rawStatus] ?? _C.indigo);
    final soft = dispStatus == 'reopened' ? _C.orangeSft : (_bg[rawStatus] ?? _C.indigoSft);
    final icon = dispStatus == 'reopened'
        ? Icons.refresh_rounded
        : (_ico[rawStatus] ?? Icons.schedule_rounded);

    final ts         = widget.data['createdAt'] as Timestamp?;
    final dateLbl    = ts != null ? DateFormat('dd MMM • hh:mm a').format(ts.toDate()) : '';
    final cancelNote = _s(widget.data['providerCancelNote'] ?? widget.data['cancelReason']);
    final name       = _name();
    final phone      = _phone();
    final addr       = _addr();
    final sched      = _sched();
    final amt        = _amt();
    final note       = _note();
    final svcList    = _services();
    final category   = _category();
    final isEnquiry  = _isEnquiry;

    final acceptLabel  = 'Accept ${widget.terms.singular}';
    final declineLabel = 'Decline';

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: _C.divider),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status bar ──────────────────────────────────────────
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
              _Pill(icon: icon, color: sc),
              const SizedBox(width: 8),
              Text(dispStatus.toUpperCase(),
                  style: TextStyle(color: sc, fontWeight: FontWeight.w800,
                      fontSize: 11, letterSpacing: 1)),
              if (isEnquiry) ...[
                const SizedBox(width: 6),
                _TagBadge(label: 'ENQUIRY', color: _C.orange,
                    icon: Icons.help_outline_rounded),
              ],
              if (category.isNotEmpty) ...[
                const SizedBox(width: 6),
                _TagBadge(label: category, color: _C.indigo),
              ],
              const Spacer(),
              if (dateLbl.isNotEmpty) ...[
                const Icon(Icons.access_time_rounded, size: 11, color: _C.sub),
                const SizedBox(width: 4),
                Text(dateLbl, style: const TextStyle(color: _C.sub, fontSize: 11)),
              ],
            ]),
          ),

          // ── Body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Customer + amount
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Avatar(name: name),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
                  const SizedBox(height: 2),
                  Text(widget.serviceType,
                      style: const TextStyle(color: _C.sub, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                      color: _C.greenSft, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    amt == 0
                        ? 'TBD'
                        : '₹${amt % 1 == 0 ? amt.toInt() : amt.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: _C.green, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ]),

              // Enquiry notice
              if (isEnquiry) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.orangeSft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.orange.withOpacity(0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, color: _C.orange, size: 15),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                      'This is an enquiry. Call the customer to discuss details '
                      'before accepting.',
                      style: TextStyle(color: _C.orange, fontSize: 12, height: 1.4),
                    )),
                  ]),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: _C.divider),
              const SizedBox(height: 12),

              if (svcList.isNotEmpty)
                _InfoRow(icon: Icons.miscellaneous_services_rounded,
                    value: svcList.join(', '), ic: _C.indigo, bg: _C.indigoSft),
              if (addr.isNotEmpty)
                _InfoRow(icon: Icons.location_on_rounded,
                    value: addr, ic: _C.red, bg: _C.redSft),
              if (sched.isNotEmpty)
                _InfoRow(icon: Icons.schedule_rounded,
                    value: sched, ic: _C.green, bg: _C.greenSft),
              if (note.isNotEmpty)
                _InfoRow(icon: Icons.notes_rounded,
                    value: note, ic: _C.orange, bg: _C.orangeSft),

              // Phone + call button
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.tealSft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.teal.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _C.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone_rounded, color: _C.teal, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Customer Mobile',
                          style: TextStyle(color: _C.sub, fontSize: 10,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(phone, style: const TextStyle(
                          color: _C.teal, fontSize: 14,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ])),
                    GestureDetector(
                      onTap: () => _launchCall(context, phone),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: _C.teal,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(
                              color: _C.teal.withOpacity(0.3),
                              blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.call_rounded, color: Colors.white, size: 15),
                          SizedBox(width: 6),
                          Text('Call Now',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 12)),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
              ],

              // Cancel reason
              if (rawStatus == 'cancelled' && cancelNote.isNotEmpty &&
                  widget.mode == _Mode.mine) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.redSft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.red.withOpacity(.25)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, color: _C.red, size: 15),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Reason: $cancelNote',
                        style: const TextStyle(
                            color: _C.red, fontSize: 12, height: 1.4))),
                  ]),
                ),
              ],

              const SizedBox(height: 14),

              // ── ACTION BUTTONS ──────────────────────────────────
              if (_busy)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _C.indigoSft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: _C.indigo)),
                      SizedBox(width: 12),
                      Text('Please wait…',
                          style: TextStyle(color: _C.indigo,
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                )

              else if (widget.mode == _Mode.avail)
                Row(children: [
                  Expanded(child: _ActionBtn(
                    label: acceptLabel,
                    icon:  Icons.check_circle_rounded,
                    bg:    _C.indigo, fg: Colors.white,
                    onTap: () => _run(widget.onAccept),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _ActionBtn(
                    label: declineLabel,
                    icon:  Icons.cancel_outlined,
                    bg:    _C.red, fg: Colors.white,
                    onTap: () => _run(widget.onDecline),
                  )),
                ])

              else ...[
                if (rawStatus == 'accepted')
                  Row(children: [
                    Expanded(child: _ActionBtn(
                      label: 'Mark Complete',
                      icon:  Icons.verified_rounded,
                      bg:    _C.green, fg: Colors.white,
                      onTap: () => _run(widget.onComplete),
                    )),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _run(widget.onCancel),
                      child: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                            color: _C.redSft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _C.red.withOpacity(0.3))),
                        child: const Icon(Icons.close_rounded,
                            color: _C.red, size: 22),
                      ),
                    ),
                  ]),
                if (rawStatus == 'completed')
                  _StatusBadge(Icons.verified_rounded,
                      '${widget.terms.singular} Completed Successfully',
                      _C.blue, _C.blueSft),
                if (rawStatus == 'cancelled')
                  _StatusBadge(Icons.refresh_rounded,
                      'Cancelled — Reopened for Other Providers',
                      _C.orange, _C.orangeSft),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL WIDGETS  (unchanged)
// ═══════════════════════════════════════════════════════════════

class _TagBadge extends StatelessWidget {
  final String label; final Color color; final IconData? icon;
  const _TagBadge({required this.label, required this.color, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 4),
      ],
      Text(label, style: TextStyle(
          color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon;
  final Color bg, fg; final VoidCallback? onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.bg, required this.fg, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: bg,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
              color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  final IconData icon; final Color color;
  const _Pill({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(8)),
    child: Icon(icon, color: color, size: 13),
  );
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    final l = name.isNotEmpty ? name.trimLeft()[0].toUpperCase() : 'C';
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
          color: _C.indigoSft, borderRadius: BorderRadius.circular(13)),
      child: Center(child: Text(l, style: const TextStyle(
          color: _C.indigo, fontWeight: FontWeight.bold, fontSize: 20))),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String value; final Color ic, bg;
  const _InfoRow({required this.icon, required this.value,
      required this.ic, required this.bg});
  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: ic, size: 13)),
        const SizedBox(width: 10),
        Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: _C.text, height: 1.4)))),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon; final String label; final Color color, bg;
  const _StatusBadge(this.icon, this.label, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Flexible(child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),
    ]),
  );
}

class _Empty extends StatelessWidget {
  final IconData icon; final String title, msg;
  const _Empty({required this.icon, required this.title, required this.msg});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(color: _C.indigoSft, shape: BoxShape.circle),
            child: Icon(icon, size: 48, color: _C.indigo)),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(
            fontSize: 21, fontWeight: FontWeight.w700, color: _C.text)),
        const SizedBox(height: 8),
        Text(msg, textAlign: TextAlign.center,
            style: const TextStyle(color: _C.sub, fontSize: 13, height: 1.6)),
      ]),
    ),
  );
}

class _ErrorRetry extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: _C.redSft, shape: BoxShape.circle),
          child: const Icon(Icons.wifi_off_rounded, size: 42, color: _C.red),
        ),
        const SizedBox(height: 20),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: _C.sub, fontSize: 14, height: 1.5)),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon:  const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.indigo, foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// PENDING BODY
// ═══════════════════════════════════════════════════════════════
class _PendingBody extends StatelessWidget {
  const _PendingBody();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            const BackButton(color: _C.text),
            const SizedBox(width: 4),
            const Text('Dashboard', style: TextStyle(
                color: _C.text, fontWeight: FontWeight.w700, fontSize: 18)),
          ]),
        ),
      ),
      const Divider(height: 1, color: _C.divider),
      Expanded(child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                    color: _C.indigoSft, shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 52, color: _C.indigo)),
            const SizedBox(height: 28),
            const Text('Pending Approval', style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: _C.text)),
            const SizedBox(height: 10),
            const Text("Your account is under review.\nYou'll be notified once approved.",
                textAlign: TextAlign.center,
                style: TextStyle(color: _C.sub, fontSize: 14, height: 1.6)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                  color: _C.orangeSft,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _C.orange.withOpacity(.3))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, color: _C.orange, size: 9),
                SizedBox(width: 10),
                Text('Status: Under Review', style: TextStyle(
                    color: _C.orange, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String        businessName, serviceType, providerId, photoUrl;
  final List<String>  activeCategories;
  final int           tab, availCount, myCount;
  final _Terms        terms;
  final void Function(int) onTab;
  final VoidCallback  onProfile;

  const _Header({
    required this.businessName,     required this.serviceType,
    required this.providerId,       required this.photoUrl,
    required this.activeCategories,
    required this.tab,              required this.availCount,
    required this.myCount,          required this.terms,
    required this.onTab,            required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _C.divider))),
      child: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                      color: _C.indigoSft, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.storefront_rounded,
                      color: _C.indigo, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(businessName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: _C.text)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: _C.green, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(serviceType,
                      style: const TextStyle(color: _C.sub, fontSize: 12)),
                ]),
              ])),
              GestureDetector(
                onTap: onProfile,
                child: _ProfileAvatar(photoUrl: photoUrl,
                    businessName: businessName, size: 44),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          if (activeCategories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Receiving jobs for:',
                    style: TextStyle(color: _C.sub, fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6,
                    children: activeCategories.map((cat) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.indigoSft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.indigo.withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 5, height: 5,
                            decoration: const BoxDecoration(
                                color: _C.indigo, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        Text(cat, style: const TextStyle(
                            color: _C.indigo, fontSize: 11,
                            fontWeight: FontWeight.w600)),
                      ]),
                    )).toList()),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _StatChip(
                label: terms.availableStat,
                count: availCount,
                color: _C.indigo,
                bg:    _C.indigoSft,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: terms.myStat,
                count: myCount,
                color: _C.green,
                bg:    _C.greenSft,
              ),
            ]),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F8),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                _TabBtn(
                  label:  terms.availableTab,
                  active: tab == 0,
                  onTap:  () => onTab(0),
                ),
                _TabBtn(
                  label:  terms.myTab,
                  active: tab == 1,
                  onTap:  () => onTab(1),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String photoUrl, businessName;
  final double size;
  const _ProfileAvatar({required this.photoUrl,
      required this.businessName, required this.size});

  String get _initial =>
      businessName.trim().isNotEmpty ? businessName.trim()[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.indigo.withOpacity(0.25), width: 1.5),
        color: _C.indigoSft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: photoUrl.isNotEmpty
            ? Image.network(photoUrl, fit: BoxFit.cover,
                loadingBuilder: (_, child, p) =>
                    p == null ? child : _InitialsFallback(initial: _initial, size: size),
                errorBuilder: (_, __, ___) =>
                    _InitialsFallback(initial: _initial, size: size))
            : _InitialsFallback(initial: _initial, size: size),
      ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  final String initial; final double size;
  const _InitialsFallback({required this.initial, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    color: _C.indigoSft,
    child: Center(child: Text(initial,
        style: TextStyle(color: _C.indigo, fontWeight: FontWeight.w700,
            fontSize: size * 0.38))),
  );
}

class _TabBtn extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.07),
                  blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(child: Text(label,
            style: TextStyle(
              color:      active ? _C.indigo : _C.sub,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize:   13,
            ))),
      ),
    ),
  );
}

class _StatChip extends StatelessWidget {
  final String label; final int count; final Color color, bg;
  const _StatChip({required this.label, required this.count,
      required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withOpacity(.15),
                borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text('$count',
                style: TextStyle(color: color,
                    fontWeight: FontWeight.w800, fontSize: 14)))),
        const SizedBox(width: 10),
        Flexible(
          child: Text(label, style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// REASON DIALOG
// ═══════════════════════════════════════════════════════════════
class _Dialog extends StatefulWidget {
  final String title, subtitle, hint, btnLabel, keepLabel;
  final Color  btnColor;
  const _Dialog({required this.title, required this.subtitle,
      required this.hint, required this.btnLabel,
      required this.keepLabel, required this.btnColor});
  @override
  State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> {
  late final TextEditingController _ctrl;
  @override void initState() { super.initState(); _ctrl = TextEditingController(); }
  @override void dispose()   { _ctrl.dispose(); super.dispose(); }

  void _unfocus() {
    if (!mounted) return;
    try { FocusScope.of(context).unfocus(); } catch (_) {}
  }

  void _confirm() {
    final text = _ctrl.text.trim();
    _unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(text);
    });
  }

  void _keep() {
    _unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) { if (didPop) return; _keep(); },
    child: Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: widget.btnColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.info_outline_rounded,
                      color: widget.btnColor, size: 26)),
              const SizedBox(height: 14),
              Text(widget.title, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _C.text)),
              const SizedBox(height: 4),
              Text(widget.subtitle, textAlign: TextAlign.center,
                  style: const TextStyle(color: _C.sub, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl, maxLines: 3,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(color: _C.sub, fontSize: 13),
                  filled: true, fillColor: const Color(0xFFF7F8FC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: _keep,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: _C.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(widget.keepLabel,
                      style: const TextStyle(color: _C.sub)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: widget.btnColor, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(widget.btnLabel,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    ),
  );
}