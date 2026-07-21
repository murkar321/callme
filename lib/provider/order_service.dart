import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ⚠️ Adjust this import path if service_config.dart lives somewhere else
// in your project — it must point to the file containing `serviceConfigs`.
import 'service_config.dart';

// ============================================================
// NOTIFICATION TYPE CONSTANTS
// ============================================================
class NotificationType {
  static const String newBooking       = 'new_booking';
  static const String accepted         = 'order_accepted';
  static const String rejected         = 'order_rejected';
  static const String cancelled        = 'order_cancelled';
  static const String completed        = 'order_completed';
  static const String userCancelled    = 'user_cancelled';
  static const String bookingAccepted  = 'booking_accepted';
  static const String bookingRejected  = 'booking_rejected';
  static const String serviceCompleted = 'service_completed';
  static const String providerRegistered   = 'provider_registered';
  static const String registrationApproved = 'registration_approved';
  static const String registrationRejected = 'registration_rejected';

  static const String orderTakenByOther = 'order_taken_by_other';

  // Added — business_dashboard_page.dart's _startWork()/_resendOtp()
  // this notification type. If these two ever diverge, OTP notifications
  // will silently fall back to the generic bell icon instead of the
  // dedicated one.
  static const String workStarted = 'work_started_otp';

  // Added — fired when an ADMIN manually declines/cancels an order
  // (typically because no provider is available / accepted it in
  // time). Kept distinct from `bookingRejected` (which is a
  // provider-initiated rejection) and `userCancelled` (customer
  // initiated) so the customer, the notification list, and any
  // future analytics can tell who actually made the call.
  static const String adminDeclined = 'admin_declined';
}

// ============================================================
// ORDER STATUS CONSTANTS
// ============================================================
class OrderStatus {
  static const String pending   = 'pending';
  static const String accepted  = 'accepted';
  static const String rejected  = 'rejected';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
  static const String enquiry   = 'enquiry';
}

// ============================================================
// PAYMENT METHOD CONSTANTS
// ============================================================
class PaymentMethod {
  static const String upi     = 'upi';
  static const String cash    = 'cash';
  static const String card    = 'card';
  static const String wallet  = 'wallet';
  static const String enquiry = 'enquiry';
}

// ============================================================
// CANONICAL CATEGORY RESOLUTION
// ============================================================

List<String> canonicalCategoriesFor(String serviceType) {
  final key = serviceType.trim().toLowerCase();
  return serviceConfigs[key]?.serviceCategories ?? const [];
}

Set<String> _significantWords(String s) => s
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.length >= 3)
    .toSet();

String? parentCategoryForSubService(String rawSubService, String serviceType) {
  final raw = rawSubService.trim();
  if (raw.isEmpty) return null;

  final key = serviceType.trim().toLowerCase();
  final config = serviceConfigs[key];
  if (config == null || config.subServices.isEmpty) return null;

  final normRaw  = normalizeCategory(raw);
  final rawWords = _significantWords(raw);

  for (final entry in config.subServices.entries) {
    final parentCategory = entry.key;
    for (final item in entry.value) {
      final normItem = normalizeCategory(item);

      if (normItem == normRaw ||
          normItem.contains(normRaw) ||
          normRaw.contains(normItem)) {
        return parentCategory;
      }

      if (_significantWords(item).intersection(rawWords).isNotEmpty) {
        return parentCategory;
      }
    }
  }

  return null;
}

String resolveCanonicalCategory(String rawCategory, String serviceType) {
  final raw = rawCategory.trim();
  if (raw.isEmpty) return raw;

  final subParent = parentCategoryForSubService(raw, serviceType);
  if (subParent != null) return subParent;

  final canonical = canonicalCategoriesFor(serviceType);
  if (canonical.isEmpty) return raw; // unknown serviceType — nothing to snap to

  final normRaw = normalizeCategory(raw);

  for (final c in canonical) {
    if (normalizeCategory(c) == normRaw) return c;
  }

  for (final c in canonical) {
    final normC = normalizeCategory(c);
    if (normC.contains(normRaw) || normRaw.contains(normC)) return c;
  }

  final rawWords = _significantWords(raw);
  for (final c in canonical) {
    if (_significantWords(c).intersection(rawWords).isNotEmpty) return c;
  }

  debugPrint('[category-resolve] No canonical match for "$raw" in '
      '$serviceType categories $canonical — keeping raw value. '
      'If this is a real category, add it to serviceConfigs.');
  return raw;
}

/// Lightweight cleanup for `subCategory` — trims only.
String cleanSubCategory(String raw) => raw.trim();

// ============================================================
// SHARED CATEGORY-MATCHING LOGIC
//
// MUST stay byte-for-byte identical between business_dashboard_page.dart
// (what a provider SEES in Available Enquiries/Orders/Bookings) and
// this file's _notifyMatchingProviders() (who actually gets a
// `notifications` doc + push). Both must call categoryMatchFuzzy()
// from HERE — neither file should re-implement its own copy.
//
// NOTE: business_page.dart's badge counter also calls
// categoryMatchFuzzy() from here directly, so "got notified" /
// "shows in Available" / "badge count" can never disagree with each
// other.
// ============================================================

String normalizeCategory(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

String normalizeServiceType(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

/// Some provider documents store `serviceType` as a TOP-LEVEL field,
/// others store it NESTED under a `service` map. Checks both shapes.
String providerServiceType(Map<String, dynamic> providerData) {
  final direct = (providerData['serviceType'] ?? '').toString().trim();
  if (direct.isNotEmpty) return direct;

  final svc = providerData['service'];
  if (svc is Map) {
    final nested = (svc['serviceType'] ?? '').toString().trim();
    if (nested.isNotEmpty) return nested;
  }
  return '';
}

/// Reads a provider document's broad, top-level MAIN categories[]
/// field — what a provider selects at registration, drawn directly
/// from `serviceConfigs[serviceType].serviceCategories`
/// (e.g. "New Build", "Renovation").
List<String> providerCategories(Map<String, dynamic> providerData) {
  final raw = (providerData['categories'] as List?) ?? const [];
  return raw
      .map((e) => e.toString().trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Reads a provider document's SPECIFIC subCategories[] field.
List<String> providerSubCategories(Map<String, dynamic> providerData) {
  final raw = (providerData['subCategories'] as List?) ?? const [];
  return raw
      .map((e) => e.toString().trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Merges categories + subCategories into one de-duplicated pool.
List<String> providerCategoryPool(
  List<String> categories,
  List<String> subCategories,
) {
  final seen = <String>{};
  final pool = <String>[];
  for (final c in [...categories, ...subCategories]) {
    final norm = normalizeCategory(c);
    if (norm.isEmpty || !seen.add(norm)) continue;
    pool.add(c);
  }
  return pool;
}

/// Builds the full set of NORMALISED (separator-stripped) MAIN category
/// candidates for an order — used for exact matching.
Set<String> orderCategoryCandidates(Map<String, dynamic> orderData) {
  final candidates = <String>{};

  for (final k in ['category', 'serviceCategory', 'subCategory', 'jobCategory']) {
    final v = (orderData[k] ?? '').toString().trim();
    if (v.isNotEmpty) candidates.add(normalizeCategory(v));
  }

  final services = orderData['services'];
  if (services is List) {
    for (final s in services) {
      final v = s.toString().trim();
      if (v.isNotEmpty) candidates.add(normalizeCategory(v));
    }
  }

  return candidates;
}

/// Same as above but RAW (trimmed + lowercased, not separator-stripped)
/// — kept for diagnostics/logging only.
Set<String> orderCategoryCandidatesRaw(Map<String, dynamic> orderData) {
  final candidates = <String>{};

  for (final k in ['category', 'serviceCategory', 'subCategory', 'jobCategory']) {
    final v = (orderData[k] ?? '').toString().trim().toLowerCase();
    if (v.isNotEmpty) candidates.add(v);
  }

  final services = orderData['services'];
  if (services is List) {
    for (final s in services) {
      final v = s.toString().trim().toLowerCase();
      if (v.isNotEmpty) candidates.add(v);
    }
  }

  return candidates;
}

/// EXACT (normalized) match — the ONLY stage now used for deciding
/// whether an order is visible to / notifiable for a provider.
bool categoryMatch(
  Map<String, dynamic> orderData,
  List<String> providerCats, {
  String debugOrderId = '',
}) {
  if (providerCats.isEmpty) {
    debugPrint('[catMatch] $debugOrderId: provider has NO categories or '
        'subCategories registered in their profile — FAILING CLOSED '
        '(this order will NOT be shown to or notify this provider). '
        'The provider needs to select at least one category/service in '
        'their profile before they can receive matching orders.');
    return false;
  }

  final normProviderCats = providerCats
      .map(normalizeCategory)
      .where((s) => s.isNotEmpty)
      .toSet();

  final orderCandidates = orderCategoryCandidates(orderData);

  if (orderCandidates.isEmpty) {
    debugPrint('[catMatch] $debugOrderId: order has no readable '
        'category/services info — provider has categories selected. '
        'FAILING CLOSED (order will NOT be shown to this provider). '
        'Fix the originating booking/enquiry page to pass `category` '
        'or `services` if this order should ever be matched to anyone.');
    return false;
  }

  final matched = orderCandidates.any(normProviderCats.contains);
  if (!matched) {
    debugPrint('[catMatch] $debugOrderId: SKIP — order categories $orderCandidates '
        'do not EXACTLY match provider categories $normProviderCats');
  }
  return matched;
}

/// Public entry point used by business_dashboard_page.dart (tab
/// visibility), business_page.dart (badge counts), and
/// _notifyMatchingProviders() / notifyOthersOrderTaken() below (push
/// fan-out). All call sites pass `providerCats` (main categories[])
/// and `providerSubCats` (subCategories[]) — merged into one pool and
/// matched EXACTLY (normalized) against the order's category / services.
bool categoryMatchFuzzy(
  Map<String, dynamic> orderData,
  List<String> providerCats, {
  List<String> providerSubCats = const [],
  String debugOrderId = '',
}) {
  final mergedProviderCats = providerSubCats.isEmpty
      ? providerCats
      : <String>{...providerCats, ...providerSubCats}.toList();

  return categoryMatch(orderData, mergedProviderCats, debugOrderId: debugOrderId);
}

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================================
  // ORDER ID GENERATOR
  // ==========================================================
  static String generateOrderId(String userName) {
    final cleanName =
        userName.trim().toLowerCase().replaceAll(' ', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${cleanName}_$timestamp';
  }

  // ==========================================================
  // PROVIDER DOC ID RESOLVER
  // ==========================================================
  static Future<String?> _getProviderDocId(String uid) async {
    if (uid.isEmpty) return null;
    try {
      var snap = await _db
          .collection('providers')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        snap = await _db
            .collection('providers')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
      }

      return snap.docs.isNotEmpty ? snap.docs.first.id : null;
    } catch (e) {
      debugPrint('[OrderService] _getProviderDocId error: $e');
      return null;
    }
  }

  // ==========================================================
  // PLACE ORDER
  //
  // ── BUG FIX (this is the fix for "only the first registered
  //    provider ever receives orders") ─────────────────────────────
  // Previously, whenever a booking page resolved a `providerId`
  // before calling placeOrder() — which nearly every booking page
  // does, since most flows land on one specific business before
  // checkout — the order was written with:
  //
  //   'providerId':     resolvedProviderId,
  //   'providerUserId': resolvedProviderUserId,
  //   'isAssigned':     resolvedProviderId.isNotEmpty,   // TRUE
  //
  // i.e. the order was immediately LOCKED to that one provider at
  // creation time, before any fan-out or FCFS logic ever ran. Two
  // knock-on effects:
  //
  //   1. _notifyMatchingProviders() took the "direct assignment"
  //      branch and only ever notified that ONE provider — every
  //      other provider registered for the exact same category never
  //      got a notification, regardless of how many of them existed.
  //
  //   2. On business_dashboard_page.dart, _unavailableReason() saw
  //      isAssigned == true with a providerUserId that didn't match
  //      the viewing provider, and returned "Already assigned to
  //      another provider" — hiding the order from every other
  //      matching provider's Available tab too.
  //
  // Net result: whichever provider a booking page happened to resolve
  // first (often just the first result of a query) silently absorbed
  // 100% of the orders for that category, while every other provider
  // who registered for the same service/category never saw a single
  // one — exactly the behaviour reported.
  //
  // FIX: placeOrder() no longer pre-assigns or locks the order to any
  // provider. Every order is created OPEN (isAssigned: false, status:
  // pending/enquiry) and is ALWAYS broadcast to every approved
  // provider whose categories/subCategories match — the same
  // category-matching logic the dashboard itself uses to decide what
  // to display. Whichever matching provider taps Accept first wins,
  // via the existing Firestore-transaction-guarded _accept() in
  // business_dashboard_page.dart. This is the actual FCFS model the
  // app is meant to run on.
  //
  // The incoming `providerId` parameter is KEPT for backward
  // compatibility with existing booking-page call sites, but it is
  // now purely informational — stored as `requestedProviderId` on the
  // order doc for debugging/analytics only. It no longer assigns,
  // locks, or restricts who can see/accept the order. If a specific
  // "book this exact provider directly, skip the marketplace" flow is
  // ever needed (e.g. tapping "Book Now" from a provider's own
  // profile page), that should be a distinct, explicitly-flagged code
  // path — not the default behaviour of every booking page.
  // ──────────────────────────────────────────────────────────────
  // ==========================================================
  static Future<DocumentReference> placeOrder({
    required String serviceType,
    required List<String> services,

    required String userId,
    required String userName,
    required String phone,
    String? email,

    required String createdBy,
    required String createdByRole,

    required String address,
    String? note,

    required DateTime date,
    required String time,

    required double totalAmount,

    int? adults,
    int? children,
    String? visitType,

    // NOTE: no longer used to assign/lock the order — see fix note
    // above. Kept only as an optional informational hint.
    String? providerId,

    String? category,

    String? subCategory,

    bool isEnquiry = false,

    String? paymentMethod,

    bool? isPaid,

    // Legacy positional params kept for call-site compat
    String providerName = '',
    Object? providerUserId, required List<Map<String, dynamic>> itemBreakdown, required List<String> subCategories,
  }) async {
    final hasCategory = category != null && category.trim().isNotEmpty;

    final String effectiveCategory =
        hasCategory ? category : (services.isNotEmpty ? services.first : '');

    if (!hasCategory && services.isEmpty) {
      debugPrint('[OrderService.placeOrder] WARNING: neither `category` nor '
          '`services` was provided for a $serviceType order. With strict '
          'exact-category matching, this order will NOT be shown to ANY '
          '$serviceType provider (fails closed). Pass `category` and/or '
          '`services` from the booking/enquiry page so it can be matched.');
    } else if (!hasCategory) {
      debugPrint('[OrderService.placeOrder] NOTE: `category` was not passed '
          'for a $serviceType order — auto-derived "$effectiveCategory" from '
          'services[0]. Prefer passing `category` explicitly from the '
          'booking/enquiry page for more reliable routing.');
    }

    // ── Resolve payment info ────────────────────────────────────────────────
    final String effectivePaymentMethod = isEnquiry
        ? PaymentMethod.enquiry
        : ((paymentMethod ?? '').trim().isNotEmpty
            ? paymentMethod!.trim().toLowerCase()
            : PaymentMethod.upi); // preserves old hardcoded default
    final bool effectiveIsPaid = isEnquiry ? false : (isPaid ?? true);

    if (!isEnquiry && paymentMethod == null) {
      debugPrint('[OrderService.placeOrder] NOTE: `paymentMethod` was not '
          'passed for a $serviceType order — defaulting to '
          '"$effectivePaymentMethod". Pass the customer\'s actual choice '
          '(PaymentMethod.upi/cash/card/wallet) from the booking page so '
          'providers see accurate payment info on their dashboard.');
    }

    // ── requestedProviderId is informational ONLY now — it does not
    // assign, lock, or restrict the order in any way. See fix note
    // above the function signature.
    final String requestedProviderId = (providerId ?? '').trim();

    final orderId               = generateOrderId(userName);
    final docRef                = _db.collection('orders').doc(orderId);
    final normalizedServiceType = serviceType.trim().toLowerCase();

    final canonicalCategory = resolveCanonicalCategory(
      effectiveCategory,
      normalizedServiceType,
    );

    final cleanedSubCategory = cleanSubCategory(subCategory ?? '');

    final canonicalServices = services
        .map((s) => resolveCanonicalCategory(s, normalizedServiceType))
        .toList();

    await docRef.set({
      'orderId': orderId,
      'userId':  userId,

      'userName': userName,
      'phone':    phone,
      'email':    email ?? '',

      'user': {
        'id':    userId,
        'name':  userName,
        'phone': phone,
        'email': email ?? '',
      },

      // ── No provider assigned at creation. Every matching provider
      // is treated equally; whoever accepts first (via the
      // transaction-guarded _accept() on the dashboard) becomes the
      // provider on this order.
      'providerId':     '',
      'providerUserId': '',
      'providerName':   '',

      'provider': {
        'providerId':     '',
        'providerUserId': '',
        'providerName':   '',
      },

      // Purely informational — which provider's page/flow this order
      // originated from, if any. Never used for matching or locking.
      'requestedProviderId': requestedProviderId,

      'serviceType': normalizedServiceType,
      'serviceName': normalizedServiceType,
      'services':    canonicalServices,

      'category': canonicalCategory,
      'subCategory': cleanedSubCategory,
      'rawCategory': (category ?? '').trim(),

      'date': Timestamp.fromDate(date),
      'time': time,

      'schedule': {
        'date': Timestamp.fromDate(date),
        'time': time,
      },

      'address': address.isEmpty ? 'Not Provided' : address,
      'note':    note ?? '',

      'location': {
        'address': address.isEmpty ? 'Not Provided' : address,
        'note':    note ?? '',
      },

      'totalAmount': totalAmount,

      'payment': {
        'totalAmount': totalAmount,
        'paid':        effectiveIsPaid,
        'method':      effectivePaymentMethod,
      },

      'adults':    adults    ?? 0,
      'children':  children  ?? 0,
      'visitType': visitType ?? '',

      'isEnquiry': isEnquiry,

      // ── Always created OPEN. No order is ever pre-assigned to a
      // single provider anymore — see fix note above.
      'status':      isEnquiry ? OrderStatus.enquiry : OrderStatus.pending,
      'isAssigned':  false,
      'isCompleted': false,

      'declineReason': '',
      'cancelReason':  '',
      'cancelledBy':   '',
      'lastActionBy':  '',

      'createdBy':     createdBy,
      'createdByRole': createdByRole,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ── Fan-out order + notification to EVERY matching approved
    // provider — no single-provider shortcut anymore.
    await _notifyMatchingProviders(
      orderId:       orderId,
      orderData: {
        'category':    canonicalCategory,
        'subCategory': cleanedSubCategory,
        'services':    canonicalServices,
        'serviceType': normalizedServiceType,
      },
      serviceType:   normalizedServiceType,
      category:      canonicalCategory,
      subCategory:   cleanedSubCategory,
      userName:      userName,
      date:          date,
      time:          time,
      totalAmount:   totalAmount,
    );

    return docRef;
  }

  // ==========================================================
  // PROVIDER ACTIONS
  // ==========================================================

  static Future<void> acceptOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    String providerId = '',
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':     OrderStatus.accepted,
      'isAssigned': true,
      'lastActionBy': 'provider',
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '✅ Booking Accepted',
      body:    '$providerName has accepted your $serviceType booking. '
               'They will contact you soon.',
      type:    NotificationType.bookingAccepted,
      businessName: providerName,
      serviceType:  serviceType,
      providerId:   providerId,
    );
  }

  static Future<void> rejectOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    required String reason,
    String providerId = '',
  }) async {
    final trimmedReason = reason.trim();

    await _db.collection('orders').doc(orderId).update({
      'status':             OrderStatus.rejected,
      'declineReason':      trimmedReason,
      'cancelReason':       trimmedReason,
      'cancelledBy':        'provider',
      'providerCancelNote': trimmedReason,
      'lastActionBy':       'provider',
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '❌ Booking Rejected',
      body:    '$providerName has rejected your $serviceType booking. '
               'Reason: $trimmedReason',
      type:    NotificationType.bookingRejected,
      businessName: providerName,
      serviceType:  serviceType,
      providerId:   providerId,
    );
  }

  static Future<void> completeOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    String providerId = '',
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':      OrderStatus.completed,
      'isCompleted': true,
      'lastActionBy': 'provider',
      'updatedAt':   FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '🎉 Service Completed',
      body:    'Your $serviceType service by $providerName has been '
               'marked as completed. Thank you!',
      type:    NotificationType.serviceCompleted,
      businessName: providerName,
      serviceType:  serviceType,
      providerId:   providerId,
    );
  }

  static Future<void> providerCancelOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    required String reason,
    String providerId = '',
  }) async {
    final trimmedReason = reason.trim();

    await _db.collection('orders').doc(orderId).update({
      'status':             OrderStatus.cancelled,
      'declineReason':      trimmedReason,
      'cancelReason':       trimmedReason,
      'cancelledBy':        'provider',
      'providerCancelNote': trimmedReason,
      'lastActionBy':       'provider',
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '🚫 Booking Cancelled by Provider',
      body:    '$providerName cancelled your $serviceType booking. '
               'Reason: $trimmedReason',
      type:    NotificationType.bookingRejected,
      businessName: providerName,
      serviceType:  serviceType,
      providerId:   providerId,
    );
  }

  // ==========================================================
  // ADMIN DECLINES AN ORDER
  //
  // Used from admin_orders_page.dart when staff need to close out an
  // order manually — most commonly because no provider is available /
  // no one accepted it in a reasonable time, but usable for any
  // admin-side decline. Unlike rejectOrder()/providerCancelOrder(),
  // this is not tied to a specific provider (the order may still be
  // unassigned, isAssigned == false, providerId == ''), so it does not
  // reference providerName/providerId at all.
  //
  // Sets:
  //   - status            -> OrderStatus.rejected
  //   - declineReason / cancelReason -> the admin-entered reason
  //   - cancelledBy       -> 'admin'
  //   - adminDeclineNote  -> the admin-entered reason (kept alongside
  //                          cancelReason so admin-specific tooling can
  //                          query for it distinctly from provider
  //                          cancellations if needed later)
  //   - lastActionBy      -> 'admin' (admin_orders_page.dart already
  //                          reads and displays this field per order)
  //
  // Always sends a NotificationType.adminDeclined notification (in-app
  // doc + FCM queue entry via notifyUser()) to the customer so they
  // know their booking was declined and why.
  // ==========================================================
  static Future<void> adminDeclineOrder({
    required String orderId,
    required String userId,
    required String serviceType,
    required String reason,
    String adminId = '',
  }) async {
    final trimmedReason = reason.trim();

    await _db.collection('orders').doc(orderId).update({
      'status':            OrderStatus.rejected,
      'declineReason':     trimmedReason,
      'cancelReason':      trimmedReason,
      'cancelledBy':       'admin',
      'adminDeclineNote':  trimmedReason,
      'declinedByAdminId': adminId,
      'lastActionBy':      'admin',
      'updatedAt':         FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '⚠️ Booking Declined',
      body:    'Your $serviceType booking has been declined by our team. '
               'Reason: $trimmedReason',
      type:    NotificationType.adminDeclined,
      serviceType: serviceType,
    );
  }

  // ==========================================================
  // USER CANCELS ORDER
  // ==========================================================
  static Future<void> userCancelOrder({
    required String orderId,
    required String providerUserId,
    required String userName,
    required String serviceType,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':      OrderStatus.cancelled,
      'cancelledBy': 'user',
      'lastActionBy': 'user',
      'updatedAt':   FieldValue.serverTimestamp(),
    });

    if (providerUserId.isNotEmpty) {
      await _sendNotification(
        receiverId: providerUserId,
        role:       'provider',
        orderId:    orderId,
        title:      '⚠️ Order Cancelled by User',
        body:       '$userName has cancelled their $serviceType booking.',
        type:       NotificationType.userCancelled,
        serviceType: serviceType,
      );

      final docId = await _getProviderDocId(providerUserId);
      if (docId != null) {
        final providerSnap = await _db.collection('providers').doc(docId).get();
        final providerData = providerSnap.data() ?? {};
        final fcmToken     = (providerData['fcmToken'] ?? '').toString().trim();

        if (fcmToken.isNotEmpty) {
          await _db.collection('fcm_queue').add({
            'token':      fcmToken,
            'receiverId': providerUserId,
            'providerId': docId,
            'orderId':    orderId,
            'title':      '⚠️ Order Cancelled by User',
            'body':       '$userName has cancelled their $serviceType booking.',
            'type':       NotificationType.userCancelled,
            'data': {
              'type':        NotificationType.userCancelled,
              'orderId':     orderId,
              'receiverId':  providerUserId,
              'providerId':  docId,
              'serviceType': serviceType,
            },
            'sent':      false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        debugPrint('[OrderService] userCancelOrder: no providers doc found for '
            'userId=$providerUserId — FCM push skipped (in-app notification '
            'above was still saved).');
      }
    }
  }

  // ==========================================================
  // FAN-OUT: notify ALL matching approved providers
  //
  // Uses the shared, strict-exact categoryMatchFuzzy() — identical
  // function and identical arguments (providerCats + providerSubCats)
  // to business_dashboard_page.dart's `_categoryMatch()` AND
  // business_page.dart's badge counter, so "got notified" / "shows up
  // in Available" / "badge count" can never disagree.
  //
  // As of the fix documented on placeOrder() above, this is now the
  // ONLY path orders are ever notified through — there is no more
  // "direct assignment, single provider only" branch. Every approved
  // provider whose categories/subCategories match the order gets
  // notified, equally, regardless of which business the customer
  // happened to browse from.
  // ==========================================================
  static Future<void> _notifyMatchingProviders({
    required String orderId,
    required Map<String, dynamic> orderData,
    required String serviceType,
    required String category,
    String subCategory = '',
    required String userName,
    required DateTime date,
    required String time,
    required double totalAmount,
  }) async {
    try {
      final normSvc = normalizeServiceType(serviceType);

      // Primary: fast indexed query — works whenever the provider's
      // stored serviceType is byte-identical to the order's.
      final primarySnap = await _db
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .where('serviceType', isEqualTo: serviceType)
          .get();

      // Fallback: broad scan of ALL approved providers, filtered
      // client-side via normalizeServiceType(). Rescues providers
      // whose serviceType field has different casing/spacing.
      final fallbackSnap =
          await _db.collection('providers').where('status', isEqualTo: 'approved').get();

      final seen = <String>{};
      final candidateDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in primarySnap.docs) {
        if (seen.add(doc.id)) candidateDocs.add(doc);
      }
      for (final doc in fallbackSnap.docs) {
        if (seen.contains(doc.id)) continue;
        final docSvc = providerServiceType(doc.data());
        if (docSvc.isNotEmpty && normalizeServiceType(docSvc) == normSvc) {
          seen.add(doc.id);
          candidateDocs.add(doc);
        }
      }

      final rescuedCount = candidateDocs.length - primarySnap.docs.length;
      debugPrint('[OrderService] order $orderId: found ${candidateDocs.length} '
          'approved $serviceType providers to check '
          '(${primarySnap.docs.length} exact match'
          '${rescuedCount > 0 ? ', $rescuedCount rescued via normalized fallback' : ''})');

      int notifiedCount = 0;

      for (final doc in candidateDocs) {
        final provData        = doc.data();
        final providerCats    = providerCategories(provData);
        final providerSubCats = providerSubCategories(provData);

        final shouldNotify = categoryMatchFuzzy(
          orderData,
          providerCats,
          providerSubCats: providerSubCats,
          debugOrderId: '$orderId -> provider ${doc.id}',
        );

        if (!shouldNotify) continue;

        await _sendProviderNotification(
          providerId:  doc.id,
          orderId:     orderId,
          serviceType: serviceType,
          category:    category,
          subCategory: subCategory,
          userName:    userName,
          date:        date,
          time:        time,
          totalAmount: totalAmount,
        );
        notifiedCount++;
      }

      debugPrint('[OrderService] order $orderId: notified $notifiedCount / '
          '${candidateDocs.length} $serviceType providers '
          '(category="$category", subCategory="$subCategory") — EXACT match, '
          'ALL matching providers notified equally (no single-provider lock)');
    } catch (e) {
      debugPrint('[OrderService] _notifyMatchingProviders error: $e');
    }
  }

  // ==========================================================
  // FCFS "taken" notice to every OTHER matching provider.
  // ==========================================================
  static Future<void> notifyOthersOrderTaken({
    required String orderId,
    required String serviceType,
    required String category,
    String subCategory = '',
    required String acceptedProviderId,
    required String acceptedByBusinessName,
  }) async {
    try {
      final normSvc = normalizeServiceType(serviceType);

      final primarySnap = await _db
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .where('serviceType', isEqualTo: serviceType)
          .get();

      final fallbackSnap = await _db
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .get();

      final seen = <String>{};
      final candidateDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in primarySnap.docs) {
        if (seen.add(doc.id)) candidateDocs.add(doc);
      }
      for (final doc in fallbackSnap.docs) {
        if (seen.contains(doc.id)) continue;
        final docSvc = providerServiceType(doc.data());
        if (docSvc.isNotEmpty && normalizeServiceType(docSvc) == normSvc) {
          seen.add(doc.id);
          candidateDocs.add(doc);
        }
      }

      // Same shape categoryMatchFuzzy()/orderCategoryCandidates() expect.
      final orderDataForMatch = <String, dynamic>{
        'category':    category,
        'subCategory': subCategory,
        'services':    <String>[],
        'serviceType': normSvc,
      };

      int notifiedCount = 0;

      for (final doc in candidateDocs) {
        // Never tell the provider who just accepted.
        if (doc.id == acceptedProviderId) continue;

        final provData        = doc.data();
        final providerCats    = providerCategories(provData);
        final providerSubCats = providerSubCategories(provData);

        final wouldHaveSeenIt = categoryMatchFuzzy(
          orderDataForMatch,
          providerCats,
          providerSubCats: providerSubCats,
          debugOrderId: '$orderId -> taken-notice ${doc.id}',
        );
        if (!wouldHaveSeenIt) continue;

        final providerUserId =
            (provData['userId'] ?? provData['uid'] ?? '').toString().trim();
        if (providerUserId.isEmpty) continue;

        final displayCat = subCategory.isNotEmpty ? subCategory : category;
        final catLabel    = displayCat.isNotEmpty ? ' ($displayCat)' : '';
        const title = '⏰ Order No Longer Available';
        final body =
            'This $serviceType$catLabel job was accepted by another '
            'provider ($acceptedByBusinessName) — no action needed on your end.';

        await _sendNotification(
          receiverId: providerUserId,
          role:       'provider',
          orderId:    orderId,
          title:      title,
          body:       body,
          type:       NotificationType.orderTakenByOther,
          serviceType: serviceType,
          category:    displayCat,
          providerId:  doc.id,
        );

        final fcmToken = (provData['fcmToken'] ?? '').toString().trim();
        if (fcmToken.isNotEmpty) {
          await _db.collection('fcm_queue').add({
            'token':      fcmToken,
            'receiverId': providerUserId,
            'providerId': doc.id,
            'orderId':    orderId,
            'title':      title,
            'body':       body,
            'type':       NotificationType.orderTakenByOther,
            'data': {
              'type':        NotificationType.orderTakenByOther,
              'orderId':     orderId,
              'receiverId':  providerUserId,
              'providerId':  doc.id,
              'serviceType': serviceType,
              'category':    displayCat,
            },
            'sent':      false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          debugPrint('[OrderService] notifyOthersOrderTaken: provider ${doc.id} '
              '($providerUserId) has no fcmToken saved — in-app notification '
              'was still written, but no background push will be sent.');
        }
        notifiedCount++;
      }

      debugPrint('[OrderService] order $orderId: told $notifiedCount other '
          'matching provider(s) it was taken by $acceptedProviderId '
          '($acceptedByBusinessName)');
    } catch (e) {
      debugPrint('[OrderService] notifyOthersOrderTaken error: $e');
    }
  }

  // ── Send notification + FCM queue entry for one provider doc ──────────────
  static Future<void> _sendProviderNotification({
    required String providerId,
    required String orderId,
    required String serviceType,
    required String category,
    String subCategory = '',
    required String userName,
    required DateTime date,
    required String time,
    required double totalAmount,
  }) async {
    final provSnap = await _db.collection('providers').doc(providerId).get();
    if (!provSnap.exists) {
      debugPrint('[OrderService] Provider $providerId not found — skipping');
      return;
    }

    final provMap = provSnap.data()!;

    final providerUserId = (provMap['userId'] ?? provMap['uid'] ?? '').toString().trim();
    final providerName   =
        (provMap['businessName'] ?? provMap['providerName'] ?? provMap['name'] ?? '')
            .toString();

    if (providerUserId.isEmpty) {
      debugPrint('[OrderService] Provider $providerId has no userId — skipping');
      return;
    }

    final displayCat = subCategory.isNotEmpty ? subCategory : category;
    final catLabel    = displayCat.isNotEmpty ? ' ($displayCat)' : '';
    final title       = '📦 New Order Received';
    final body        =
        'Hi $providerName, new $serviceType$catLabel booking from $userName '
        'on ${_formatDate(date)} at $time.'
        '${totalAmount > 0 ? ' Amount ₹${totalAmount.toStringAsFixed(0)}' : ''}';

    // `businessName: providerName` is written here so the Firestore
    // `notifications` doc for new bookings carries the provider's own
    // name/id, which notification_router.dart needs to route straight
    // to THIS provider's dashboard (instead of the generic BusinessPage
    // list).
    await _sendNotification(
      receiverId: providerUserId,
      role:       'provider',
      orderId:    orderId,
      title:      title,
      body:       body,
      type:       NotificationType.newBooking,
      businessName: providerName,
      serviceType: serviceType,
      category:    displayCat,
      providerId:  providerId,
    );

    final fcmToken = (provMap['fcmToken'] ?? '').toString().trim();
    if (fcmToken.isNotEmpty) {
      await _db.collection('fcm_queue').add({
        'token':      fcmToken,
        'receiverId': providerUserId,
        'providerId': providerId,
        'orderId':    orderId,
        'title':      title,
        'body':       body,
        'type':       NotificationType.newBooking,
        'data': {
          'type':        NotificationType.newBooking,
          'orderId':     orderId,
          'receiverId':  providerUserId,
          // This is the actual payload that survives to a
          // locked-screen / terminated-app tap. Without these three
          // fields, notification_router.dart had nothing to route on
          // and fell back to the generic BusinessPage list every time.
          'providerId':   providerId,
          'businessName': providerName,
          'serviceType':  serviceType,
          'category':     displayCat,
        },
        'sent':      false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      debugPrint('[OrderService] Provider $providerId ($providerUserId) has no '
          'fcmToken saved — they will only ever see this order live while the '
          'dashboard is open, never a background push. Check that '
          'NotificationService successfully wrote a token to this provider doc.');
    }
  }

  // ==========================================================
  // NOTIFY USER — status updates from provider / admin
  // ==========================================================
  static Future<void> notifyUser({
    required String userId,
    required String orderId,
    required String title,
    required String body,
    required String type,
    String? businessName,
    String? serviceType,
    String? providerId,
  }) async {
    if (userId.isEmpty) return;

    try {
      await _sendNotification(
        receiverId: userId,
        role:       'user',
        orderId:    orderId,
        title:      title,
        body:       body,
        type:       type,
        businessName: businessName,
        serviceType:  serviceType,
        providerId:   providerId,
      );

      final userDoc  = await _db.collection('users').doc(userId).get();
      final fcmToken =
          (userDoc.data()?['fcmToken'] ?? '').toString().trim();

      if (fcmToken.isNotEmpty) {
        final pushData = <String, dynamic>{
          'type':       type,
          'orderId':    orderId,
          'receiverId': userId,
        };
        final bn = businessName?.trim() ?? '';
        if (bn.isNotEmpty) pushData['businessName'] = bn;
        final st = serviceType?.trim() ?? '';
        if (st.isNotEmpty) pushData['serviceType'] = st;
        final pid = providerId?.trim() ?? '';
        if (pid.isNotEmpty) pushData['providerId'] = pid;

        await _db.collection('fcm_queue').add({
          'token':      fcmToken,
          'receiverId': userId,
          'orderId':    orderId,
          'title':      title,
          'body':       body,
          'type':       type,
          'data':       pushData,
          'sent':      false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('[OrderService] notifyUser: user $userId has no fcmToken '
            'saved — in-app notification was still written, but no background '
            'push will be sent.');
      }
    } catch (e) {
      debugPrint('[OrderService] notifyUser error: $e');
    }
  }

  // ==========================================================
  // INTERNAL: write to notifications collection
  // ==========================================================
  static Future<void> _sendNotification({
    required String receiverId,
    required String role,
    required String orderId,
    required String title,
    required String body,
    required String type,
    String? businessName,
    String? serviceType,
    String? providerId,
    String? category,
  }) async {
    final doc = <String, dynamic>{
      'receiverId': receiverId,
      'senderId':   '',
      'role':       role,
      'orderId':    orderId,
      'title':      title,
      'body':       body,
      'type':       type,
      'read':       false,
      'createdAt':  FieldValue.serverTimestamp(),
    };

    final bn = businessName?.trim() ?? '';
    if (bn.isNotEmpty) doc['businessName'] = bn;

    final st = serviceType?.trim() ?? '';
    if (st.isNotEmpty) doc['serviceType'] = st;

    final pid = providerId?.trim() ?? '';
    if (pid.isNotEmpty) doc['providerId'] = pid;

    final cat = category?.trim() ?? '';
    if (cat.isNotEmpty) doc['category'] = cat;

    await _db.collection('notifications').add(doc);
  }

  // ==========================================================
  // DATE FORMATTER
  // ==========================================================
  static String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}