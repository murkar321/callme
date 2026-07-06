import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'provider_profile_page.dart';
import '../provider/order_service.dart';
// ⚠️ Adjust path if service_config.dart lives elsewhere.

// FIX: only import NotificationService from notification_service.dart —
// NOT the whole file. notification_service.dart also declares its own
// `class NotificationType`, and order_service.dart (imported above)
// already declares a DIFFERENT `class NotificationType`. Importing both
// files unqualified would make `NotificationType` ambiguous and fail to
// compile. `show NotificationService` sidesteps that entirely.
import '../profile/notification_service.dart' show NotificationService;
// ⚠️ Adjust path above if notification_service.dart lives elsewhere.

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
//
// FIX: _norm() used to keep its own private copy of the
// space/hyphen/underscore-stripping regex. order_service.dart
// already exposes the exact same logic as normalizeServiceType() —
// having two independent copies is exactly the kind of drift that
// caused the earlier category-matching bugs (one file's regex
// silently diverging from the other's). _norm() now just delegates,
// so there is only ever ONE definition of "normalized" in the app.
// ═══════════════════════════════════════════════════════════════
String _norm(String s) => normalizeServiceType(s);

bool _svcEq(String a, String b) => _norm(a) == _norm(b);

// ─────────────────────────────────────────────────────────────
// CATEGORY MATCH
//
// This also accepts `providerSubCats` and forwards it to
// categoryMatchFuzzy() exactly like order_service.dart's
// _notifyMatchingProviders() does. A provider who is registered
// ONLY under `subCategories[]` (no matching main category) will
// still see the order here — the same merged-pool pipeline is used
// on both the "who gets notified" side and the "what do I see" side.
//
// NOTE: categoryMatchFuzzy() itself is STRICT/EXACT ONLY (see
// order_service.dart) — it does not do fuzzy word-overlap matching
// across categories. "Hair Styling" will never match a provider
// registered only under "Hair Treatments". The only thing "fuzzy"
// about this pipeline is that it checks the provider's categories[]
// AND subCategories[] pool — both of which the provider explicitly
// selected themselves — not that it guesses based on shared words.
//
// FIX: categoryMatchFuzzy() / categoryMatch() (in order_service.dart)
// now FAILS CLOSED when a provider has NO categories/subCategories
// registered at all, instead of the old fail-OPEN behavior that
// silently matched such a provider against every order in their
// vertical. That single shared-function fix is what stops
// "providers who never selected this service still getting
// notified" — see the comment on categoryMatch() in
// order_service.dart for the full explanation. Nothing in THIS file
// needed to change for that part; it was already delegating to the
// shared function correctly.
// ─────────────────────────────────────────────────────────────
bool _categoryMatch(
  Map<String, dynamic> orderData,
  List<String> providerCats, {
  List<String> providerSubCats = const [],
}) {
  final orderId = (orderData['orderId'] ?? '').toString();
  return categoryMatchFuzzy(
    orderData,
    providerCats,
    providerSubCats: providerSubCats,
    debugOrderId: orderId,
  );
}

// ─────────────────────────────────────────────────────────────
// AVAILABILITY CHECK — single source of truth.
//
// Returns WHY an order is unavailable (or null if it's available).
// `_isAvailable()` below is a thin bool wrapper around it, and
// `_AvailTab._buildSkipSummary()` uses these reason strings to log a
// breakdown to the debug console only — the provider's dashboard UI
// itself just shows a clean "No Available X" message.
//
// This is also the ONE function that decides FCFS visibility: once
// any provider accepts an order (isAssigned=true, providerUserId set
// to someone else), every OTHER provider's live listener re-runs this
// check and the order disappears from their Available tab in
// real time — no polling, no manual refresh needed.
//
// ─────────────────────────────────────────────────────────────
// FIX (PRIOR REVISION): MULTI-PROFILE-PER-LOGIN ISOLATION.
//
// One Firebase Auth account (`userId`) can own MULTIPLE provider
// profiles across different verticals — e.g. the same login
// registered both a Salon business (providerId="SAL-118697") AND a
// Resort/Civil business (providerId="RES-457227"). Firestore's
// `providerUserId` field on an order only ever stores the Auth UID,
// which is IDENTICAL for both of that person's dashboards.
//
// Every ownership check in this file compares the order's
// `providerId` (the specific business profile) against
// `myProviderId` (this dashboard instance's own providerId) — NOT
// just `providerUserId` — so a login with multiple business
// profiles can never leak an order between them.
// ─────────────────────────────────────────────────────────────
String? _unavailableReason({
  required Map<String, dynamic> data,
  required String myUid,
  required String myProviderId,
  required String svcNorm,
  required List<String> providerCats,
  required List<String> providerSubCats,
}) {
  final dynamic assignedRaw = data['isAssigned'];
  // Treat null / missing as false (order not yet taken)
  final bool isAssigned = assignedRaw == true;

  final provUid =
      (data['providerUserId'] ?? '').toString().trim();
  final orderProviderId =
      (data['providerId'] ?? '').toString().trim();
  final status  =
      (data['status'] ?? '').toString().toLowerCase().trim();
  final reopened = data['reopenForOthers'] == true;

  // "Belongs to me" now requires BOTH the same login AND the same
  // exact provider profile. Legacy orders with no providerId saved
  // (orderProviderId.isEmpty) still fall back to UID-only matching
  // so old data doesn't suddenly become invisible.
  final bool assignedToMe = isAssigned &&
      provUid.isNotEmpty &&
      provUid == myUid &&
      (orderProviderId.isEmpty || orderProviderId == myProviderId);

  // Already firmly taken by someone else (different login), OR taken
  // by the SAME login but a DIFFERENT one of their business profiles
  // → skip on this dashboard either way.
  if (isAssigned && provUid.isNotEmpty && !assignedToMe) {
    return provUid == myUid
        ? 'Assigned to a different provider profile under this login (order providerId="$orderProviderId", this dashboard="$myProviderId")'
        : 'Already assigned to another provider';
  }

  // ── DIRECT-ASSIGNMENT BYPASS ─────────────────────────────────
  // Customer explicitly picked THIS exact provider profile at
  // booking time. Still "pending"/"enquiry" (not yet accepted) →
  // always show it to the assigned provider profile, skip
  // service-type/category checks entirely. Once they Accept, status
  // flips to "accepted" and it moves to the "My" tab via _isMine()
  // instead.
  //
  // FIX (CRITICAL): this used to only bypass when
  // `status == OrderStatus.pending`. But EnquiryPage submits with
  // `isEnquiry: true`, which makes placeOrder() write
  // `status: OrderStatus.enquiry` (NOT "pending"), while still
  // correctly setting isAssigned=true + providerId/providerUserId to
  // the exact provider that _findMatchingProvider() picked for the
  // enquiry. Because "enquiry" wasn't included in this check, every
  // direct-assigned ENQUIRY fell straight through to the
  // service-type/category checks further below — and if that
  // provider had been chosen as a same-service-type fallback (NOT an
  // exact category/subCategory match — see
  // EnquiryPage._findMatchingProvider()'s final
  // `return candidates.first.id;` fallback), the category check
  // failed CLOSED and the enquiry became invisible EVERYWHERE: not
  // "available" (category mismatch) and not "mine" either (status
  // isn't accepted/completed/cancelled yet, see _isMine() below). It
  // just silently vanished for the exact provider it was assigned
  // to, even though Firestore had it correctly assigned the whole
  // time. This is what produced dashboards showing "No Available
  // Enquiries" while dozens of enquiries sat unreachable in
  // Firestore.
  //
  // Fix: bypass for BOTH pending and enquiry status. A direct
  // assignment already represents an intentional routing decision —
  // it should never be re-litigated against category rules once the
  // order/enquiry has been targeted at this exact provider profile.
  final bool isDirectAssignmentToMe = assignedToMe &&
      (status == OrderStatus.pending || status == OrderStatus.enquiry);
  if (isDirectAssignmentToMe) {
    return null; // available — no further checks needed
  }

  // ── Open-status check ───────────────────────────────────────
  // Any order with a provider attached, whether that's this
  // provider or another one, is no longer "available" — the
  // 'accepted' branch below only reopens an order when it is
  // genuinely ORPHANED data (status says accepted but no provider
  // is actually attached — a data inconsistency, not a real
  // assignment).
  final bool isOrphanedAccept =
      status == OrderStatus.accepted && provUid.isEmpty;
  final bool isOpen = status == OrderStatus.pending
      || status == OrderStatus.enquiry
      || (status == OrderStatus.cancelled && reopened)
      || isOrphanedAccept
      || assignedRaw == null; // field missing means unassigned

  if (!isOpen) {
    return provUid == myUid && provUid.isNotEmpty
        ? 'You already accepted this — it now lives in your "My" tab'
        : 'Status "$status" is not open (isAssigned=$assignedRaw)';
  }

  // Already declined by this provider → skip
  final declined = (data['declinedBy'] as List?) ?? [];
  if (myUid.isNotEmpty && declined.contains(myUid)) {
    return 'You already declined this order';
  }

  // Service-type match
  final orderSvc = (data['serviceType'] ?? '').toString().trim();
  if (orderSvc.isNotEmpty && !_svcEq(orderSvc, svcNorm)) {
    return 'Service type mismatch: order="$orderSvc" vs your profile="$svcNorm"';
  }

  // ── Category match ───────────────────────────────────────────
  // EXACT ONLY (see categoryMatchFuzzy() / categoryMatch() in
  // order_service.dart), run against the MERGED categories +
  // subCategories pool. No fuzzy word-overlap: a provider under
  // "Hair Treatments" will never match an order categorized as
  // "Hair Styling" just because both contain the word "hair".
  //
  // FIX: as of the categoryMatch() patch in order_service.dart, a
  // provider with an EMPTY categories+subCategories pool now fails
  // this check (returns false) instead of auto-matching everything.
  // If you land here and providerCats/providerSubCats are both
  // empty, that IS the mismatch reason — the message below already
  // makes that visible via `mergedCats` being `[]`.
  if (!_categoryMatch(data, providerCats, providerSubCats: providerSubCats)) {
    final cands      = orderCategoryCandidates(data);
    final mergedCats = providerCategoryPool(providerCats, providerSubCats);
    if (mergedCats.isEmpty) {
      return 'You have no categories or subCategories selected in your '
             'profile yet — add at least one to start receiving matching '
             '${svcNorm.isEmpty ? "" : "$svcNorm "}orders. (Order categories: $cands)';
    }
    return 'Category mismatch: order categories=$cands vs your categories=$mergedCats';
  }

  return null; // available
}

bool _isAvailable({
  required Map<String, dynamic> data,
  required String myUid,
  required String myProviderId,
  required String svcNorm,
  required List<String> providerCats,
  required List<String> providerSubCats,
}) {
  final reason = _unavailableReason(
    data:            data,
    myUid:           myUid,
    myProviderId:    myProviderId,
    svcNorm:         svcNorm,
    providerCats:    providerCats,
    providerSubCats: providerSubCats,
  );
  if (reason != null) {
    debugPrint('[avail] SKIP ${data['orderId'] ?? ''}: $reason');
  }
  return reason == null;
}

// ─────────────────────────────────────────────────────────────
// "My Jobs" must ONLY show orders that are explicitly and firmly
// assigned to this provider — not pending/open ones.
//
// FIX: also scoped to the exact provider profile (myProviderId), not
// just the login (myUid) — for the same multi-profile-per-login
// reason documented above _unavailableReason(). Without this, a
// resort booking accepted under RES-457227 could also show up in the
// "My Jobs" tab of the Salon dashboard (SAL-118697) opened from the
// same login.
// ─────────────────────────────────────────────────────────────
bool _isMine({
  required Map<String, dynamic> data,
  required String myUid,
  required String myProviderId,
  required String svcNorm,
}) {
  final provUid  = (data['providerUserId'] ?? '').toString().trim();
  final orderProviderId = (data['providerId'] ?? '').toString().trim();
  final status   = (data['status'] ?? '').toString().toLowerCase().trim();
  final dynamic assignedRaw = data['isAssigned'];

  // Must belong to this login
  if (provUid != myUid) return false;

  // Must belong to THIS exact business profile — unless the order has
  // no providerId saved at all (legacy data), in which case fall back
  // to UID-only matching so old orders don't vanish.
  if (orderProviderId.isNotEmpty && orderProviderId != myProviderId) {
    return false;
  }

  // Service type must match (allow empty for legacy docs)
  final orderSvc = (data['serviceType'] ?? '').toString().trim();
  if (orderSvc.isNotEmpty && !_svcEq(orderSvc, svcNorm)) return false;

  // Only show statuses that mean "this job is mine"
  // 'pending' without assignment = available job, not mine
  const mineStatuses = {
    OrderStatus.accepted,
    OrderStatus.completed,
    OrderStatus.cancelled,
  };
  if (!mineStatuses.contains(status)) return false;

  // Extra guard: if isAssigned is explicitly false and status is
  // somehow 'accepted', treat as available (data inconsistency)
  if (assignedRaw == false && status == OrderStatus.accepted) {
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

  // ─────────────────────────────────────────────────────────────
  // ORDERS STREAM — SINGLE SOURCE OF TRUTH
  //
  // One query, single orderBy field (`createdAt`) → no composite
  // index required, ever. Everything else (isAssigned, status,
  // service type, category, AND provider profile) is filtered
  // client-side. Both tabs share this one stream/result set, and any
  // error is surfaced immediately instead of being swallowed.
  //
  // NOTE: because this query reads the WHOLE `orders` collection
  // (filtering happens client-side), your Firestore Security Rules
  // must allow an authenticated user to READ the `orders` collection
  // with NO per-document field conditions. Real access control lives
  // in the app instead: the accept() transaction below guards
  // isAssigned/providerUserId/providerId, and category/service-type/
  // provider-profile matching decides what's ever shown.
  // ─────────────────────────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream =
      const Stream.empty();

  final _availNotifier = _CountNotifier();
  final _myNotifier    = _CountNotifier();

  ScaffoldMessengerState? _messenger;

  // ─────────────────────────────────────────────────────────────
  // FIX: INSTANT NEW-ORDER ALERT.
  //
  // This is a SECOND, best-effort delivery path on top of the
  // server-side push: while THIS dashboard instance is open and
  // listening to the live `orders` stream, the instant a NEW order
  // shows up that matches this provider (and wasn't already known
  // from the first load), we fire a local sound+vibration alert
  // directly — no round trip needed.
  //
  // IMPORTANT: this is purely a local, on-device heads-up. It does
  // NOT write anything to Firestore. The actual `notifications`
  // collection doc (the one NotificationPage reads, and the one that
  // triggers a real push via `fcm_queue`) is written once, at order
  // creation time, by OrderService._notifyMatchingProviders() in
  // order_service.dart — using the exact same categoryMatchFuzzy()
  // pipeline as `_isAvailable()` below. As long as both stay in sync
  // (see the note on categoryMatchFuzzy() in order_service.dart),
  // "shows up locally" and "has a saved notification" will always
  // agree. Do NOT add a second Firestore write here — that would
  // create duplicate notification docs for orders that already got
  // one at creation time.
  //
  // `_isFirstOrdersLoad` prevents falsely "alerting" on every order
  // that already existed when the dashboard was opened; only orders
  // that arrive AFTER that first snapshot trigger a notification.
  // ─────────────────────────────────────────────────────────────
  final Set<String> _knownAvailableOrderIds = {};
  bool _isFirstOrdersLoad = true;

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

    // Single query, single orderBy field → no composite index needed.
    // Bump the limit here if your order volume regularly exceeds it.
    _ordersStream = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots();

    if (mounted) setState(() {});
  }

  void _retry() {
    if (!mounted) return;
    setState(() {
      _ordersStream = const Stream.empty();
      _authReady    = false;
      // Reset the new-order tracker too — otherwise a retry could
      // treat every already-existing order as "new" and spam alerts.
      _knownAvailableOrderIds.clear();
      _isFirstOrdersLoad = true;
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

  // ─────────────────────────────────────────────────────────────
  // FIX: called once per orders-stream emission with the set of
  // orders that are currently AVAILABLE to this provider (already
  // category/service/status/profile filtered via _isAvailable()).
  // Diffs against what we saw last time and fires a local alert for
  // anything genuinely new.
  //
  // Safe to call on every rebuild: if nothing changed since last
  // time, `newIds` is empty and this is a no-op.
  // ─────────────────────────────────────────────────────────────
  void _checkForNewOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> availableDocs,
  ) {
    final currentIds = availableDocs.map((d) => d.id).toSet();

    if (_isFirstOrdersLoad) {
      // Baseline only — don't alert for orders that already existed
      // before this dashboard session started.
      _knownAvailableOrderIds
        ..clear()
        ..addAll(currentIds);
      _isFirstOrdersLoad = false;
      return;
    }

    final newIds = currentIds.difference(_knownAvailableOrderIds);
    if (newIds.isNotEmpty) {
      for (final doc in availableDocs) {
        if (!newIds.contains(doc.id)) continue;
        final data = doc.data();
        final custName = (data['userName'] ?? '').toString().trim();
        final label = _terms.singular;
        NotificationService.showLocalAlert(
          title: '📦 New $label Available',
          body: '${custName.isEmpty ? "A customer" : custName} has a new '
              '${widget.serviceType} $label waiting — first to accept gets it.',
          payload: jsonEncode({'type': 'new_booking', 'orderId': doc.id}),
        );
      }
    }

    _knownAvailableOrderIds
      ..clear()
      ..addAll(currentIds);
  }

  // ─── Firestore actions ────────────────────────────────────────

  // FIX: the accept transaction now also checks that an order which
  // is already assigned to "me" (by UID) is assigned to THIS exact
  // provider profile too — so a Salon dashboard can never be used to
  // accidentally accept an order that a Resort profile under the same
  // login was directly assigned.
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

        final curProvider   = (cur['providerUserId'] ?? '').toString().trim();
        final curProviderId = (cur['providerId'] ?? '').toString().trim();

        // Already taken by someone else — either a different login,
        // OR the same login but a DIFFERENT one of their own business
        // profiles (e.g. this order was direct-assigned to the Resort
        // profile, but we're accepting from the Salon dashboard).
        final belongsToDifferentProfile = curProvider.isNotEmpty &&
            curProvider == _uid &&
            curProviderId.isNotEmpty &&
            curProviderId != widget.providerId;

        if (cur['isAssigned'] == true &&
            curProvider.isNotEmpty &&
            (curProvider != _uid || belongsToDifferentProfile)) {
          throw Exception('taken');
        }

        final st       = (cur['status'] ?? '').toString().toLowerCase();
        final reopened = cur['reopenForOthers'] == true;
        final dynamic assignedRaw = cur['isAssigned'];
        final hasNoProvider = curProvider.isEmpty;

        final canAccept = st == OrderStatus.pending
            || st == OrderStatus.enquiry
            || (st == OrderStatus.cancelled && reopened)
            || (st == OrderStatus.accepted && hasNoProvider)
            || assignedRaw == null; // missing field = open

        if (!canAccept) throw Exception('taken');

        tx.update(ref, {
          'providerId':      widget.providerId,
          'providerUserId':  _uid,
          'providerName':    widget.businessName,
          'serviceType':     _svcNorm,
          'status':          OrderStatus.accepted,
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

      // FIX: NEW — tell every OTHER matching provider this job is gone.
      // Runs the same categoryMatchFuzzy() candidate pool used everywhere
      // else in order_service.dart, excludes THIS provider, and sends a
      // real push (fcm_queue + notifications doc) so it rings on/off-
      // screen instead of the order just silently disappearing from
      // their Available tab while the old "new order" notification
      // stays in their list looking still-open — the exact confusion
      // reported ("message stays and provider get confuse").
      OrderService.notifyOthersOrderTaken(
        orderId:                id,
        serviceType:            _svcNorm,
        category:               (data['category'] ?? '').toString(),
        subCategory:            (data['subCategory'] ?? '').toString(),
        acceptedProviderId:     widget.providerId,
        acceptedByBusinessName: widget.businessName,
      ).catchError((e) => debugPrint('[notifyOthersOrderTaken] $e'));

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
        'status':          OrderStatus.pending,
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
        'status':       OrderStatus.completed,
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
        'status':             OrderStatus.cancelled,
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

  // FIX: now forwards `businessName` / `serviceType` / `providerId`
  // into OrderService.notifyUser() so the saved notification doc
  // carries this as STRUCTURED data — not just baked into `body` text.
  // NotificationPage already renders a chip for `businessName` /
  // `serviceType` when present on the doc; before this fix those
  // fields were never written, so the chip never showed and there was
  // no reliable way to tell "which order got completed by which
  // provider" from the Notifications screen alone.
  void _notify(String uid, String orderId, String title, String body, String type) {
    if (uid.isEmpty) return;
    OrderService.notifyUser(
      userId: uid, orderId: orderId,
      title: title, body: body, type: type,
      businessName: widget.businessName,
      serviceType:  widget.serviceType,
      providerId:   widget.providerId,
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
            final err = snap.error.toString();
            final isPerm = err.contains('permission-denied') ||
                err.contains('PERMISSION_DENIED') ||
                err.contains('insufficient permissions');
            return _ErrorRetry(
              message: isPerm
                  ? 'Firestore security rules are blocking this provider from '
                    'reading their own profile document.\n\n'
                    'Check that your rules allow: providers/{providerId} to be '
                    'read by the signed-in user that owns it.'
                  : 'Could not load your provider profile.\n'
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

          final business = (prov['business'] as Map?)?.cast<String, dynamic>() ?? {};
          final photoUrl = (business['image'] ?? '').toString().trim();

          // ── Read BOTH `categories` (main) and `subCategories`
          // (specific) off the provider doc via order_service.dart's
          // shared helpers — the exact same helpers
          // _notifyMatchingProviders() uses for push notifications.
          //
          // Because this comes from a live `snapshots()` listener on
          // the provider's own doc, editing categories in
          // ProviderProfilePage / registration-edit flow updates
          // `mainCats` / `subCats` here IMMEDIATELY — no re-login or
          // manual refresh needed — and every order in `_ordersStream`
          // is re-filtered against the new list on the next rebuild.
          final mainCats    = providerCategories(prov);
          final subCats     = providerSubCategories(prov);
          final displayCats = providerCategoryPool(mainCats, subCats);

          // ── NEW — surfaced directly in the header when a provider
          // has registered zero categories. Since categoryMatch() now
          // fails closed on an empty pool (see order_service.dart),
          // such a provider will see NOTHING in Available until they
          // fix this — so tell them plainly instead of a silent
          // empty list.
          final hasNoCategoriesRegistered = displayCats.isEmpty;

          return Column(children: [
            _Header(
              businessName:     widget.businessName,
              serviceType:      widget.serviceType,
              providerId:       widget.providerId,
              tab:              _tab,
              availCount:       _availNotifier.value,
              myCount:          _myNotifier.value,
              photoUrl:         photoUrl,
              activeCategories: displayCats,
              noCategoriesWarning: hasNoCategoriesRegistered,
              terms:            _terms,
              onTab:            _goTab,
              onProfile: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProviderProfilePage(providerId: widget.providerId))),
            ),
            Expanded(
              // ── SINGLE shared orders stream for both tabs ──────
              // Any error here is always surfaced — nothing is
              // silently swallowed.
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ordersStream,
                builder: (_, ordersSnap) {
                  if (ordersSnap.hasError) {
                    final err = ordersSnap.error.toString();
                    final isIdx = err.contains('failed-precondition') ||
                        err.contains('requires an index');
                    final isPerm = err.contains('permission-denied') ||
                        err.contains('PERMISSION_DENIED') ||
                        err.contains('insufficient permissions');
                    return _ErrorRetry(
                      message: isIdx
                          ? 'Missing Firestore index for the orders query.\n\n'
                            'Create in Firebase Console → Firestore → Indexes:\n'
                            'Collection: orders\n'
                            'Field: createdAt DESC'
                          : isPerm
                              ? 'Firestore security rules are blocking providers '
                                'from reading the "orders" collection.\n\n'
                                'This dashboard reads all recent orders and '
                                'filters them on-device, so your rules must '
                                'allow a signed-in user to READ the "orders" '
                                'collection with NO per-document field '
                                'conditions — Firestore rejects a query '
                                'wholesale if any rule branch depends on '
                                'resource.data for a field this query doesn\'t '
                                'filter by. The rule needs to simply be:\n\n'
                                'match /orders/{orderId} {\n'
                                '  allow read: if request.auth != null;\n'
                                '}\n\n'
                                'Until this is fixed, providers will NEVER see '
                                'any orders here, even ones that match them '
                                'perfectly.'
                              : 'Could not load orders.\n$err',
                      onRetry: _retry,
                    );
                  }

                  if (ordersSnap.connectionState == ConnectionState.waiting &&
                      !ordersSnap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: _C.indigo));
                  }

                  final allDocs = ordersSnap.data?.docs ?? [];

                  // ── FIX: instant local alert for newly-arrived orders.
                  // Computed with the exact same _isAvailable() filter the
                  // Available tab itself uses (now including the
                  // per-provider-profile check), so "got an alert" and
                  // "shows up in Available" can never disagree.
                  final availableForAlert = allDocs.where((d) => _isAvailable(
                    data:            d.data(),
                    myUid:           _uid,
                    myProviderId:    widget.providerId,
                    svcNorm:         _svcNorm,
                    providerCats:    mainCats,
                    providerSubCats: subCats,
                  )).toList();
                  _checkForNewOrders(availableForAlert);

                  return IndexedStack(
                    index: _tab,
                    children: [
                      _AvailTab(
                        key:             const ValueKey('available'),
                        allDocs:         allDocs,
                        myUid:           _uid,
                        myProviderId:    widget.providerId,
                        svcNorm:         _svcNorm,
                        serviceType:     widget.serviceType,
                        providerCats:    mainCats,
                        providerSubCats: subCats,
                        countNotifier:   _availNotifier,
                        terms:           _terms,
                        onAccept:        _accept,
                        onDecline:       _showDecline,
                      ),
                      _MyTab(
                        key:           const ValueKey('myjobs'),
                        allDocs:       allDocs,
                        myUid:         _uid,
                        myProviderId:  widget.providerId,
                        svcNorm:       _svcNorm,
                        serviceType:   widget.serviceType,
                        countNotifier: _myNotifier,
                        terms:         _terms,
                        onComplete:    _complete,
                        onCancel:      _showCancel,
                      ),
                    ],
                  );
                },
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
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs;
  final String         myUid, myProviderId, svcNorm, serviceType;
  final List<String>   providerCats;
  final List<String>   providerSubCats;
  final _CountNotifier countNotifier;
  final _Terms         terms;
  final Future<void> Function(String, Map<String, dynamic>) onAccept;
  final Future<void> Function(String, Map<String, dynamic>) onDecline;

  const _AvailTab({
    super.key,
    required this.allDocs,
    required this.myUid,
    required this.myProviderId,
    required this.svcNorm,
    required this.serviceType,
    required this.providerCats,
    required this.providerSubCats,
    required this.countNotifier,
    required this.terms,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    // ── Client-side filter: only truly available (scoped to THIS
    // exact provider profile, not just this login) ────────────────
    final docs = allDocs.where((d) => _isAvailable(
      data:            d.data(),
      myUid:           myUid,
      myProviderId:    myProviderId,
      svcNorm:         svcNorm,
      providerCats:    providerCats,
      providerSubCats: providerSubCats,
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
      // Skip-reason breakdown is still computed and logged to the
      // debug console for troubleshooting, but it is never rendered
      // on screen — providers just see a clean, simple empty state.
      _buildSkipSummary();
      return _Empty(
        icon:  Icons.work_outline_rounded,
        title: 'No ${terms.availableTab}',
        msg:   'New ${terms.availableTab.toLowerCase()} matching your '
               'categories will appear here automatically.',
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
  }

  // ── Builds a grouped, frequency-sorted diagnostic summary of why
  // every order currently in `allDocs` is being skipped for this
  // provider. Sent ONLY to debugPrint() — never shown to the user.
  //
  // FIX: reworded the summary line. It used to always say "0 match
  // your categories" even when the actual skip reasons had nothing to
  // do with categories at all (e.g. "already accepted", "assigned to
  // another provider", "completed") — which made this actively
  // misleading when the real bug was elsewhere (see the direct-
  // assignment bypass fix above). Now it just states the plain fact —
  // none are currently available — and lets the itemized reasons
  // below speak for themselves.
  void _buildSkipSummary() {
    if (allDocs.isEmpty) {
      debugPrint('[avail] No $serviceType ${terms.singular.toLowerCase()}s exist yet.');
      return;
    }
    final reasonCounts = <String, int>{};
    for (final d in allDocs) {
      final reason = _unavailableReason(
        data:            d.data(),
        myUid:           myUid,
        myProviderId:    myProviderId,
        svcNorm:         svcNorm,
        providerCats:    providerCats,
        providerSubCats: providerSubCats,
      );
      if (reason == null) continue;
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }
    final entries = reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final lines = entries.map((e) => '${e.value}x — ${e.key}').join('\n');
    final mergedCats = providerCategoryPool(providerCats, providerSubCats);
    final summary = '${allDocs.length} ${terms.singular.toLowerCase()}(s) exist, '
        'none are currently available. Your categories: $mergedCats\n$lines';
    debugPrint('[avail] $summary');
  }
}

// ═══════════════════════════════════════════════════════════════
// MY JOBS TAB
// ═══════════════════════════════════════════════════════════════
class _MyTab extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs;
  final String         myUid, myProviderId, svcNorm, serviceType;
  final _CountNotifier countNotifier;
  final _Terms         terms;
  final Future<void> Function(String, Map<String, dynamic>) onComplete;
  final Future<void> Function(String, Map<String, dynamic>) onCancel;

  const _MyTab({
    super.key,
    required this.allDocs,
    required this.myUid,
    required this.myProviderId,
    required this.svcNorm,
    required this.serviceType,
    required this.countNotifier,
    required this.terms,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Use _isMine() to strictly filter — prevents pending/open
    // orders (and orders belonging to a DIFFERENT provider profile
    // under the same login) from leaking into My Jobs tab.
    final docs = allDocs.where((d) => _isMine(
      data:         d.data(),
      myUid:        myUid,
      myProviderId: myProviderId,
      svcNorm:      svcNorm,
    )).toList();

    const ord = {
      OrderStatus.accepted:  0,
      OrderStatus.completed: 1,
      OrderStatus.cancelled: 2,
      OrderStatus.pending:   3,
    };
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
        .where((d) => (d.data()['status'] ?? '').toString().toLowerCase() ==
            OrderStatus.accepted)
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
          onComplete: status == OrderStatus.accepted ? () => onComplete(doc.id, data) : null,
          onCancel:   status == OrderStatus.accepted ? () => onCancel(doc.id, data)   : null,
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
    OrderStatus.pending:   _C.amber,
    OrderStatus.enquiry:   _C.orange,
    OrderStatus.accepted:  _C.green,
    OrderStatus.completed: _C.blue,
    OrderStatus.cancelled: _C.grey,
  };
  static const _bg = {
    OrderStatus.pending:   _C.amberSft,
    OrderStatus.enquiry:   _C.orangeSft,
    OrderStatus.accepted:  _C.greenSft,
    OrderStatus.completed: _C.blueSft,
    OrderStatus.cancelled: _C.greySft,
  };
  static const _ico = {
    OrderStatus.pending:   Icons.schedule_rounded,
    OrderStatus.enquiry:   Icons.help_rounded,
    OrderStatus.accepted:  Icons.check_circle_rounded,
    OrderStatus.completed: Icons.verified_rounded,
    OrderStatus.cancelled: Icons.cancel_rounded,
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

  // ── FIX: payment method + paid/unpaid status — now reads from
  // several possible field shapes (not just `payment.method`), and
  // recognizes offline/COD-style methods as a DISTINCT state instead
  // of lumping them in with "payment pending", since being unpaid at
  // booking time is expected/normal for those, not a warning sign.
  Map<String, dynamic> _payment() {
    final p = widget.data['payment'];
    return p is Map ? p.cast<String, dynamic>() : <String, dynamic>{};
  }

  String _paymentMethodRaw() {
    final candidates = <String>[
      (_payment()['method'] ?? '').toString(),
      (_payment()['paymentMethod'] ?? '').toString(),
      (widget.data['paymentMethod'] ?? '').toString(),
      (widget.data['method'] ?? '').toString(),
    ];
    for (final c in candidates) {
      final v = c.trim().toLowerCase();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static const Map<String, String> _methodLabels = {
    'upi':               'UPI',
    'cash':              'Cash',
    'card':              'Card',
    'wallet':            'Wallet',
    'enquiry':           'Enquiry',
    'cod':               'Cash on Delivery',
    'cash_on_delivery':  'Cash on Delivery',
    'offline':           'Pay Offline',
    'pay_offline':       'Pay Offline',
    'netbanking':        'Net Banking',
    'net_banking':       'Net Banking',
    'banktransfer':      'Bank Transfer',
    'bank_transfer':     'Bank Transfer',
    'online':            'Online Payment',
  };

  String _paymentMethodLabel() {
    final raw = _paymentMethodRaw();
    if (raw.isEmpty) return '';
    final key = raw.replaceAll(RegExp(r'[\s\-]+'), '_');
    final known = _methodLabels[key] ?? _methodLabels[raw];
    if (known != null) return known;
    return raw
        .split(RegExp(r'[\s_\-]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  bool get _isOfflineMethod {
    const offline = {'cash', 'cod', 'cash_on_delivery', 'offline', 'pay_offline'};
    return offline.contains(_paymentMethodRaw().replaceAll(RegExp(r'[\s\-]+'), '_'));
  }

  bool _isPaid() => _payment()['paid'] == true;

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
      (raw == OrderStatus.cancelled && widget.data['reopenForOthers'] == true)
          ? 'reopened'
          : raw;

  bool get _isEnquiry =>
      (widget.data['status'] ?? '').toString().toLowerCase() == OrderStatus.enquiry;

  Widget _paymentBadge() {
    final methodLabel = _paymentMethodLabel();
    if (methodLabel.isEmpty) return const SizedBox.shrink();

    final isEnquiryPayment = _paymentMethodRaw() == 'enquiry';
    final paid    = _isPaid();
    final offline = _isOfflineMethod;

    final Color color = isEnquiryPayment
        ? _C.grey
        : (paid ? _C.green : (offline ? _C.blue : _C.amber));
    final Color bg = isEnquiryPayment
        ? _C.greySft
        : (paid ? _C.greenSft : (offline ? _C.blueSft : _C.amberSft));
    final IconData icon = isEnquiryPayment
        ? Icons.info_outline_rounded
        : (paid
            ? Icons.verified_rounded
            : (offline
                ? Icons.payments_rounded
                : Icons.hourglass_bottom_rounded));
    final String label = isEnquiryPayment
        ? 'No payment required — enquiry only'
        : (paid
            ? 'Paid via $methodLabel'
            : (offline
                ? 'Collect payment in person • $methodLabel'
                : 'Payment pending • $methodLabel'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawStatus  = (widget.data['status'] ?? OrderStatus.pending).toString().toLowerCase();
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
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing:    8,
              runSpacing: 6,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _Pill(icon: icon, color: sc),
                  const SizedBox(width: 8),
                  Text(dispStatus.toUpperCase(),
                      style: TextStyle(color: sc, fontWeight: FontWeight.w800,
                          fontSize: 11, letterSpacing: 1)),
                ]),
                if (category.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: _TagBadge(label: category, color: _C.indigo),
                  ),
                if (dateLbl.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.access_time_rounded, size: 11, color: _C.sub),
                    const SizedBox(width: 4),
                    Text(dateLbl, style: const TextStyle(color: _C.sub, fontSize: 11)),
                  ]),
              ],
            ),
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

              // Payment status — how (and whether) the customer paid.
              _paymentBadge(),

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
              if (rawStatus == OrderStatus.cancelled && cancelNote.isNotEmpty &&
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
                if (rawStatus == OrderStatus.accepted)
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
                if (rawStatus == OrderStatus.completed)
                  _StatusBadge(Icons.verified_rounded,
                      '${widget.terms.singular} Completed Successfully',
                      _C.blue, _C.blueSft),
                if (rawStatus == OrderStatus.cancelled)
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
  const _TagBadge({required this.label, required this.color, IconData? icon}) : icon = icon;
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
      Flexible(
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      ),
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

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
//
// FIX: this now ALWAYS renders just the icon + title + message —
// the on-screen debug breakdown panel has been removed entirely.
// Skip-reason diagnostics are still written to debugPrint() (see
// _AvailTab._buildSkipSummary()) for anyone checking device logs,
// but the provider's own dashboard now only ever shows a clean,
// simple "No Available X" message, per request.
// ═══════════════════════════════════════════════════════════════
class _Empty extends StatelessWidget {
  final IconData icon; final String title, msg;
  const _Empty({
    required this.icon,
    required this.title,
    required this.msg,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minHeight: constraints.maxHeight),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(28),
                decoration: const BoxDecoration(color: _C.indigoSft, shape: BoxShape.circle),
                child: Icon(icon, size: 48, color: _C.indigo)),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(
                fontSize: 21, fontWeight: FontWeight.w700, color: _C.text)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: _C.sub, fontSize: 13, height: 1.6)),
          ]),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// ERROR RETRY
// ═══════════════════════════════════════════════════════════════
class _ErrorRetry extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 64),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                    color: _C.redSft, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded,
                    size: 42, color: _C.red),
              ),
              const SizedBox(height: 20),
              Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _C.sub, fontSize: 14, height: 1.5)),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon:  const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.indigo, foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ),
        ),
      ),
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
  // ── NEW — true when this provider has NO categories/subCategories
  // registered at all. Since categoryMatch() now fails closed on an
  // empty pool, such a provider will see zero orders until they fix
  // this — so it's surfaced directly instead of silently showing an
  // empty Available tab with no explanation.
  final bool noCategoriesWarning;

  const _Header({
    required this.businessName,     required this.serviceType,
    required this.providerId,       required this.photoUrl,
    required this.activeCategories,
    required this.tab,              required this.availCount,
    required this.myCount,          required this.terms,
    required this.onTab,            required this.onProfile,
    this.noCategoriesWarning = false,
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

          // ── NEW — plain-language warning banner instead of a
          // silently empty Available tab. Tapping it goes straight to
          // the profile page to fix it.
          if (noCategoriesWarning) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: onProfile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _C.redSft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.red.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: _C.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No categories selected yet — you won\'t receive any '
                        'orders until you add at least one. Tap to fix.',
                        style: const TextStyle(
                            color: _C.red, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _C.red, size: 18),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

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