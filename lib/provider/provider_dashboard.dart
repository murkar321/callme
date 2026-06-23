import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

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
  static const text      = Color(0xFF212121);
  static const sub       = Color(0xFF757575);
  static const divider   = Color(0xFFF0F0F0);
}

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════
String _norm(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

bool _svcEq(String a, String b) => _norm(a) == _norm(b);

// ═══════════════════════════════════════════════════════════════
// COUNT NOTIFIER
//
// Replaces the Future.microtask(() => widget.onCount(c)) pattern
// which was the primary trigger of the '_dependents.isEmpty' assertion.
//
// Why that pattern was dangerous:
//   StreamBuilder calls build() synchronously during a frame.
//   Inside build() we scheduled a microtask to call setState() on
//   the *parent*. Microtasks run at the end of the current microtask
//   checkpoint — which can land in the middle of Flutter's own
//   frame pipeline (specifically during the "unmount" phase of an
//   InheritedElement). When setState fires while an InheritedElement
//   is unmounting its dependents, Flutter hits the
//   '_dependents.isEmpty' assertion because it's trying to add a
//   new dependent to an element that is already tearing down.
//
// Fix: use a ChangeNotifier. The parent _BDPState listens to it and
//   schedules its own setState via addPostFrameCallback — which is
//   always safe because post-frame callbacks run AFTER the entire
//   build/layout/paint pipeline for the current frame, never during
//   InheritedElement unmounting.
// ═══════════════════════════════════════════════════════════════
class _CountNotifier extends ChangeNotifier {
  int _value = 0;
  int get value => _value;

  void update(int newValue) {
    if (_value != newValue) {
      _value = newValue;
      // Don't call notifyListeners() synchronously inside a build()
      // call — defer to post-frame so we're never inside a frame pipeline.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // The notifier itself might have been disposed by the time
        // the callback fires (e.g. fast navigation). Guard with
        // hasListeners so we don't crash.
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

  int _tab = 0;
  String _uid = '';

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _providerSnap;
  Stream<QuerySnapshot<Map<String, dynamic>>>      _availStream =
      const Stream.empty();
  Stream<QuerySnapshot<Map<String, dynamic>>>?      _myStream;

  // ChangeNotifiers let child tabs report counts without calling
  // setState() synchronously from inside a StreamBuilder build(),
  // which was what triggered the '_dependents.isEmpty' assertion.
  final _availNotifier = _CountNotifier();
  final _myNotifier    = _CountNotifier();

  // Cached inherited state — looked up once in didChangeDependencies()
  // so we never touch `context` from inside async gaps.
  ScaffoldMessengerState? _messenger;

  String get _svcNorm => _norm(widget.serviceType);

  int get _availCount => _availNotifier.value;
  int get _myCount    => _myNotifier.value;

  @override
  void initState() {
    super.initState();
    // Listen to notifiers and rebuild the header counts safely.
    _availNotifier.addListener(_onCountChanged);
    _myNotifier.addListener(_onCountChanged);
    _initStreams();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache ScaffoldMessenger here — this is the only safe place to
    // call inherited lookups. Never do this inside async callbacks.
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _availNotifier.removeListener(_onCountChanged);
    _myNotifier.removeListener(_onCountChanged);
    _availNotifier.dispose();
    _myNotifier.dispose();
    super.dispose();
  }

  void _onCountChanged() {
    // Listeners fire from addPostFrameCallback (see _CountNotifier),
    // so this setState is always safe — never inside a build/unmount.
    if (mounted) setState(() {});
  }

  void _initStreams() {
    _uid = _auth.currentUser?.uid ?? '';

    _providerSnap = _db
        .collection('providers')
        .doc(widget.providerId)
        .snapshots();

    _availStream = _db
        .collection('orders')
        .where('isAssigned', isEqualTo: false)
        .limit(200)
        .snapshots();

    _myStream = _uid.isEmpty
        ? null
        : _db
            .collection('orders')
            .where('providerUserId', isEqualTo: _uid)
            .limit(200)
            .snapshots();
  }

  void _retry() {
    if (!mounted) return;
    setState(_initStreams);
  }

  void _goTab(int i) {
    if (mounted && _tab != i) setState(() => _tab = i);
  }

  // ─── Snack ────────────────────────────────────────────────────
  // Uses cached _messenger — never calls ScaffoldMessenger.of(context)
  // which would be unsafe inside async gaps.
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
        behavior:  SnackBarBehavior.floating,
        shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin:    const EdgeInsets.all(16),
        duration:  const Duration(seconds: 3),
      ));
  }

  // ─── Firestore actions ────────────────────────────────────────

  Future<void> _accept(String id, Map<String, dynamic> data) async {
    final custId = (data['userId'] ?? '').toString();
    final ref    = _db.collection('orders').doc(id);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('not_found');
        final cur      = snap.data()!;
        if (cur['isAssigned'] == true) throw Exception('taken');
        final st       = (cur['status'] ?? '').toString().toLowerCase();
        final reopened = cur['reopenForOthers'] == true;
        if (!(st == 'pending' || st == 'enquiry' || reopened)) {
          throw Exception('taken');
        }
        tx.update(ref, {
          'providerId':      widget.providerId,
          'providerUserId':  _uid,
          'providerName':    widget.businessName,
          'serviceType':     widget.serviceType,
          'status':          'accepted',
          'isAssigned':      true,
          'reopenForOthers': false,
          'acceptedAt':      FieldValue.serverTimestamp(),
          'updatedAt':       FieldValue.serverTimestamp(),
          'lastActionBy':    'provider',
        });
      });
      _notify(custId, id, '✅ Provider Found!',
          '${widget.businessName} accepted your ${widget.serviceType} booking.',
          'booking_accepted');
      if (!mounted) return;
      _goTab(1);
      _snack('Job accepted! Moved to My Jobs.', _C.green, Icons.check_circle_rounded);
    } on Exception catch (e) {
      final m = e.toString();
      if (m.contains('taken')) {
        _snack('Already accepted by another provider.', _C.orange, Icons.info_outline_rounded);
      } else if (m.contains('not_found')) {
        _snack('Order no longer exists.', _C.red, Icons.error_outline);
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
          'booking_declined');
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
      _notify(custId, id, '✅ Service Completed',
          'Your ${widget.serviceType} service by ${widget.businessName} is complete!',
          'booking_completed');
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
      });
      _notify(custId, id, '❌ Provider Cancelled',
          '${widget.businessName} cancelled. '
          'Reason: ${note.isEmpty ? "Not specified" : note}. '
          'Finding another provider.',
          'booking_cancelled');
      _snack('Job cancelled — order reopened for others.', _C.orange, Icons.cancel_rounded);
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
      builder: (_) => const _Dialog(
        title:     'Decline Job',
        subtitle:  'Order stays open for other providers.',
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
      builder: (_) => const _Dialog(
        title:     'Cancel Job',
        subtitle:  'Order will reopen for other providers.',
        hint:      'Reason (shown to customer)...',
        btnLabel:  'Cancel Job',
        btnColor:  _C.red,
        keepLabel: 'Keep Job',
      ),
    );
    if (!mounted || reason == null) return;
    await _cancel(id, reason, data);
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _providerSnap,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return _ErrorRetry(
              message: 'Could not load your provider profile.\nCheck your connection and try again.',
              onRetry: _retry,
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: _C.indigo));
          }
          final prov = snap.data?.data() ?? {};
          if (prov['status'] != 'approved') {
            return const _PendingBody();
          }
          return Column(children: [
            _Header(
              businessName: widget.businessName,
              serviceType:  widget.serviceType,
              providerId:   widget.providerId,
              tab:          _tab,
              availCount:   _availCount,
              myCount:      _myCount,
              onTab:        _goTab,
              onProfile: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      ProviderProfilePage(providerId: widget.providerId))),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _AvailTab(
                    key:         const ValueKey('available'),
                    stream:      _availStream,
                    myUid:       _uid,
                    svcNorm:     _svcNorm,
                    serviceType: widget.serviceType,
                    countNotifier: _availNotifier,
                    onAccept:    _accept,
                    onDecline:   _showDecline,
                    onRetry:     _retry,
                  ),
                  _MyTab(
                    key:         const ValueKey('myjobs'),
                    stream:      _myStream,
                    svcNorm:     _svcNorm,
                    serviceType: widget.serviceType,
                    countNotifier: _myNotifier,
                    onComplete:  _complete,
                    onCancel:    _showCancel,
                    onRetry:     _retry,
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
// AVAILABLE JOBS TAB
// ═══════════════════════════════════════════════════════════════
class _AvailTab extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String svcNorm, myUid, serviceType;
  final _CountNotifier countNotifier;
  final Future<void> Function(String, Map<String, dynamic>) onAccept;
  final Future<void> Function(String, Map<String, dynamic>) onDecline;
  final VoidCallback onRetry;

  const _AvailTab({
    super.key,
    required this.stream,
    required this.myUid,
    required this.svcNorm,
    required this.serviceType,
    required this.countNotifier,
    required this.onAccept,
    required this.onDecline,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (_, snap) {
        if (snap.hasError) {
          return _ErrorRetry(message: 'Could not load available jobs.', onRetry: onRetry);
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _C.indigo));
        }

        final raw  = snap.data?.docs ?? [];
        final docs = raw.where((d) {
          final m        = d.data();
          final st       = (m['status'] ?? '').toString().toLowerCase();
          final reopened = m['reopenForOthers'] == true;
          if (m['isAssigned'] == true) return false;
          final isOpen   = st == 'pending' || st == 'enquiry'
              || (st == 'cancelled' && reopened);
          if (!isOpen) return false;
          if (!_svcEq((m['serviceType'] ?? '').toString(), svcNorm)) return false;
          final declined = (m['declinedBy'] as List?) ?? [];
          return !declined.contains(myUid);
        }).toList();

        docs.sort((a, b) {
          final at = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bt = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return at.compareTo(bt);
        });

        // Safe count update — goes through _CountNotifier which defers
        // to addPostFrameCallback, so it never fires during a build.
        countNotifier.update(docs.length);

        if (docs.isEmpty) {
          return _Empty(
            icon:  Icons.work_outline_rounded,
            title: 'No Available Jobs',
            msg:   'New $serviceType orders will appear here in real-time.',
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
              onAccept:    () => onAccept(doc.id, data),
              onDecline:   () => onDecline(doc.id, data),
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
  final String svcNorm, serviceType;
  final _CountNotifier countNotifier;
  final Future<void> Function(String, Map<String, dynamic>) onComplete;
  final Future<void> Function(String, Map<String, dynamic>) onCancel;
  final VoidCallback onRetry;

  const _MyTab({
    super.key,
    required this.stream,
    required this.svcNorm,
    required this.serviceType,
    required this.countNotifier,
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
          return _ErrorRetry(message: 'Could not load your jobs.', onRetry: onRetry);
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _C.indigo));
        }

        final docs = (snap.data?.docs ?? []).where((d) {
          final svc = (d.data()['serviceType'] ?? '').toString();
          return svc.isEmpty || _svcEq(svc, svcNorm);
        }).toList();

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

        final active = docs.where((d) =>
            (d.data()['status'] ?? '').toString().toLowerCase() == 'accepted').length;

        // Safe — deferred through _CountNotifier / addPostFrameCallback.
        countNotifier.update(active);

        if (docs.isEmpty) {
          return _Empty(
            icon:  Icons.assignment_outlined,
            title: 'No Jobs Yet',
            msg:   'Jobs you accept will appear here and update in real-time.',
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

class _Card extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final Map<String, dynamic> data;
  final _Mode         mode;
  final String        serviceType;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const _Card({
    super.key,
    required this.doc,  required this.data,
    required this.mode, required this.serviceType,
    this.onAccept, this.onDecline, this.onComplete, this.onCancel,
  });

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
      final v = _s(data[k]); if (v.isNotEmpty) return v;
    }
    return 'Customer';
  }

  String _phone() {
    for (final k in ['phone','phoneNumber','mobile','contactPhone']) {
      final v = _s(data[k]); if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _addr() {
    for (final k in ['address','fullAddress','customerAddress']) {
      final v = _s(data[k]); if (v.isNotEmpty) return v;
    }
    final loc = data['location'];
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
    final sc = data['schedule'];
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
      final v = _s(data[k]); if (v.isNotEmpty) return v;
    }
    return '';
  }

  double _amt() {
    for (final k in ['totalAmount','amount','price','total','cost']) {
      final v = data[k]; if (v is num) return v.toDouble();
    }
    final pay = data['payment'];
    if (pay is Map) {
      for (final k in ['totalAmount','amount','total','price']) {
        final v = pay[k]; if (v is num) return v.toDouble();
      }
    }
    return 0;
  }

  String _note() {
    for (final k in ['note','notes','description','specialRequest']) {
      final v = _s(data[k]); if (v.isNotEmpty) return v;
    }
    return '';
  }

  List<String> _services() {
    final sv = data['services'];
    return sv is List ? sv.map((e) => e.toString()).toList() : [];
  }

  String _displayStatus(String raw) =>
      (raw == 'cancelled' && data['reopenForOthers'] == true) ? 'reopened' : raw;

  @override
  Widget build(BuildContext context) {
    final rawStatus  = (data['status'] ?? 'pending').toString().toLowerCase();
    final dispStatus = _displayStatus(rawStatus);

    final sc   = dispStatus == 'reopened' ? _C.orange    : (_col[rawStatus] ?? _C.indigo);
    final soft = dispStatus == 'reopened' ? _C.orangeSft : (_bg[rawStatus]  ?? _C.indigoSft);
    final icon = dispStatus == 'reopened'
        ? Icons.refresh_rounded
        : (_ico[rawStatus] ?? Icons.schedule_rounded);

    final ts         = data['createdAt'] as Timestamp?;
    final dateLbl    = ts != null ? DateFormat('dd MMM • hh:mm a').format(ts.toDate()) : '';
    final cancelNote = _s(data['providerCancelNote'] ?? data['cancelReason']);
    final name       = _name();
    final phone      = _phone();
    final addr       = _addr();
    final sched      = _sched();
    final amt        = _amt();
    final note       = _note();
    final svcList    = _services();

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: _C.divider),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Status stripe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20),
              ),
            ),
            child: Row(children: [
              _Pill(icon: icon, color: sc),
              const SizedBox(width: 8),
              Text(dispStatus.toUpperCase(), style: TextStyle(
                color: sc, fontWeight: FontWeight.w800,
                fontSize: 11, letterSpacing: 1,
              )),
              const Spacer(),
              if (dateLbl.isNotEmpty) ...[
                const Icon(Icons.access_time_rounded, size: 11, color: _C.sub),
                const SizedBox(width: 4),
                Text(dateLbl, style: const TextStyle(color: _C.sub, fontSize: 11)),
              ],
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Avatar(name: name),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _C.text)),
                  const SizedBox(height: 2),
                  Text(serviceType, style: const TextStyle(color: _C.sub, fontSize: 12)),
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

              const SizedBox(height: 12),
              const Divider(height: 1, color: _C.divider),
              const SizedBox(height: 12),

              if (svcList.isNotEmpty)
                _Row(icon: Icons.miscellaneous_services_rounded,
                    value: svcList.join(', '), ic: _C.indigo, bg: _C.indigoSft),
              if (phone.isNotEmpty)
                _Row(icon: Icons.phone_rounded, value: phone, ic: _C.indigo, bg: _C.indigoSft),
              if (addr.isNotEmpty)
                _Row(icon: Icons.location_on_rounded, value: addr, ic: _C.red, bg: _C.redSft),
              if (sched.isNotEmpty)
                _Row(icon: Icons.schedule_rounded, value: sched, ic: _C.green, bg: _C.greenSft),
              if (note.isNotEmpty)
                _Row(icon: Icons.notes_rounded, value: note, ic: _C.orange, bg: _C.orangeSft),

              if (rawStatus == 'cancelled' && cancelNote.isNotEmpty && mode == _Mode.mine) ...[
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
                        style: const TextStyle(color: _C.red, fontSize: 12, height: 1.4))),
                  ]),
                ),
              ],

              const SizedBox(height: 14),

              if (mode == _Mode.avail)
                Row(children: [
                  Expanded(child: _Btn(
                      label: 'Accept', icon: Icons.check_rounded,
                      bg: _C.indigo, fg: Colors.white, onTap: onAccept)),
                  const SizedBox(width: 10),
                  Expanded(child: _Btn(
                      label: 'Decline', icon: Icons.close_rounded,
                      bg: _C.redSft, fg: _C.red, outlined: true, onTap: onDecline)),
                ])
              else ...[
                if (rawStatus == 'accepted')
                  Row(children: [
                    Expanded(child: _Btn(
                        label: 'Mark Complete', icon: Icons.verified_rounded,
                        bg: _C.green, fg: Colors.white, onTap: onComplete)),
                    const SizedBox(width: 10),
                    _IcoBtn(icon: Icons.close_rounded,
                        color: _C.red, bg: _C.redSft, onTap: onCancel),
                  ]),
                if (rawStatus == 'completed')
                  _Badge(Icons.verified_rounded,
                      'Job Completed Successfully', _C.blue, _C.blueSft),
                if (rawStatus == 'cancelled')
                  _Badge(Icons.refresh_rounded,
                      'Cancelled — Reopened for Other Providers', _C.orange, _C.orangeSft),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════
class _Pill extends StatelessWidget {
  final IconData icon; final Color color;
  const _Pill({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
        color: color.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
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

class _Row extends StatelessWidget {
  final IconData icon; final String value; final Color ic, bg;
  const _Row({required this.icon, required this.value, required this.ic, required this.bg});
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
            child: Text(value, style: const TextStyle(fontSize: 13, color: _C.text, height: 1.4)))),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label; final IconData icon;
  final Color bg, fg; final bool outlined; final VoidCallback? onTap;
  const _Btn({required this.label, required this.icon,
      required this.bg, required this.fg,
      required this.onTap, this.outlined = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color:  outlined ? Colors.transparent : bg,
        border: outlined ? Border.all(color: bg, width: 1.5) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: fg, size: 15),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ),
  );
}

class _IcoBtn extends StatelessWidget {
  final IconData icon; final Color color, bg; final VoidCallback? onTap;
  const _IcoBtn({required this.icon, required this.color, required this.bg, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 46, height: 46,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
    ),
  );
}

class _Badge extends StatelessWidget {
  final IconData icon; final String label; final Color color, bg;
  const _Badge(this.icon, this.label, this.color, this.bg);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 7),
      Flexible(child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13))),
    ]),
  );
}

class _Empty extends StatelessWidget {
  final IconData icon; final String title, msg;
  const _Empty({required this.icon, required this.title, required this.msg});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(40),
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
          icon: const Icon(Icons.refresh_rounded, size: 18),
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
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(color: _C.indigoSft, shape: BoxShape.circle),
                  child: const Icon(Icons.hourglass_top_rounded, size: 52, color: _C.indigo)),
              const SizedBox(height: 28),
              const Text('Pending Approval', style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: _C.text)),
              const SizedBox(height: 10),
              const Text(
                  "Your account is under review.\nYou'll be notified once approved.",
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
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String businessName, serviceType, providerId;
  final int tab, availCount, myCount;
  final void Function(int) onTab;
  final VoidCallback onProfile;

  const _Header({
    required this.businessName, required this.serviceType,
    required this.providerId,   required this.tab,
    required this.availCount,   required this.myCount,
    required this.onTab,        required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _C.divider))),
      child: SafeArea(bottom: false, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: _C.indigoSft, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.storefront_rounded, color: _C.indigo, size: 26)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(businessName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _C.text)),
              const SizedBox(height: 3),
              Row(children: [
                Container(width: 7, height: 7,
                    decoration: const BoxDecoration(color: _C.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(serviceType, style: const TextStyle(color: _C.sub, fontSize: 12)),
              ]),
            ])),
            GestureDetector(
              onTap: onProfile,
              child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: _C.indigoSft, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.person_rounded, color: _C.indigo, size: 22)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _Chip(label: 'Available',   count: availCount, color: _C.indigo, bg: _C.indigoSft),
            const SizedBox(width: 10),
            _Chip(label: 'Active Jobs', count: myCount,    color: _C.green,  bg: _C.greenSft),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
                color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              _TabBtn(label: 'Available Jobs', active: tab == 0, onTap: () => onTab(0)),
              _TabBtn(label: 'My Jobs',        active: tab == 1, onTap: () => onTab(1)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
      ])),
    );
  }
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
        child: Center(child: Text(label, style: TextStyle(
          color:      active ? _C.indigo : _C.sub,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          fontSize:   13,
        ))),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label; final int count; final Color color, bg;
  const _Chip({required this.label, required this.count, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: color.withOpacity(.15), borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text('$count', style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 14)))),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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

  const _Dialog({
    required this.title,     required this.subtitle,
    required this.hint,      required this.btnLabel,
    required this.keepLabel, required this.btnColor,
  });

  @override
  State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      _keep();
    },
    child: Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: widget.btnColor.withOpacity(.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.info_outline_rounded, color: widget.btnColor, size: 26)),
              const SizedBox(height: 14),
              Text(widget.title, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _C.text)),
              const SizedBox(height: 4),
              Text(widget.subtitle, textAlign: TextAlign.center,
                  style: const TextStyle(color: _C.sub, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:  widget.hint,
                  hintStyle: const TextStyle(color: _C.sub, fontSize: 13),
                  filled:    true,
                  fillColor: const Color(0xFFF7F8FC),
                  border:    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide:   BorderSide.none),
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
                  child: Text(widget.keepLabel, style: const TextStyle(color: _C.sub)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: widget.btnColor, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text(widget.btnLabel, style: const TextStyle(
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