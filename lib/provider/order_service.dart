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
// CANONICAL CATEGORY RESOLUTION
//
// `serviceConfigs` (service_config.dart) is the single source of
// truth both the provider-registration category picker AND
// booking pages *should* draw from. In practice they can still
// drift (typos, differently-worded booking-page labels, older
// app versions). `resolveCanonicalCategory()` snaps whatever a
// booking page sends onto the matching entry in `serviceConfigs`
// for that serviceType, so what actually gets written to
// Firestore is byte-identical to what a provider picked at
// registration — which is what makes Stage-1 EXACT matching in
// `categoryMatch()` succeed almost every time, instead of relying
// on the fuzzy fallback in business_dashboard_page.dart.
//
// If no canonical entry is found (unknown serviceType, or a
// genuinely new category not yet in service_config.dart), the
// original raw string is kept as-is — nothing is silently
// dropped, it just falls back to fuzzy matching downstream.
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

/// Snaps `rawCategory` onto the closest entry in
/// `serviceConfigs[serviceType].serviceCategories`, if any.
/// Returns the original trimmed string if no confident match is found.
String resolveCanonicalCategory(String rawCategory, String serviceType) {
  final raw = rawCategory.trim();
  if (raw.isEmpty) return raw;

  final canonical = canonicalCategoriesFor(serviceType);
  if (canonical.isEmpty) return raw; // unknown serviceType — nothing to snap to

  final normRaw = normalizeCategory(raw);

  // 1. Exact normalised match
  for (final c in canonical) {
    if (normalizeCategory(c) == normRaw) return c;
  }

  // 2. Substring match either direction
  for (final c in canonical) {
    final normC = normalizeCategory(c);
    if (normC.contains(normRaw) || normRaw.contains(normC)) return c;
  }

  // 3. Shared significant word (3+ chars)
  final rawWords = _significantWords(raw);
  for (final c in canonical) {
    if (_significantWords(c).intersection(rawWords).isNotEmpty) return c;
  }

  debugPrint('[category-resolve] No canonical match for "$raw" in '
      '$serviceType categories $canonical — keeping raw value. '
      'If this is a real category, add it to serviceConfigs.');
  return raw;
}

// ============================================================
// SHARED CATEGORY-MATCHING LOGIC
//
// IMPORTANT: This logic MUST stay byte-for-byte identical to
// `_categoryMatch()` / `_orderCategoryCandidates()` in
// business_dashboard_page.dart. If they drift apart, a provider
// can get a push notification for an order that never shows up
// in their "Available" tab (or vice versa).
//
// Rules:
//   1. Build the order's candidate set from EVERY legacy category
//      field (category, serviceCategory, subCategory, jobCategory)
//      PLUS every string in services[].
//   2. providerCats empty  → provider is unrestricted, show/notify
//      everything for their serviceType.
//   3. providerCats NOT empty AND orderCandidates empty → we have
//      no category info to check against at all, so fall back to
//      showing/notifying (can't restrict what we can't read).
//   4. Otherwise → require at least one overlap between the two
//      normalised sets.
// ============================================================

/// Normalise a string for category comparison: trim, lowercase,
/// collapse whitespace/underscores/hyphens.
String normalizeCategory(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

/// Normalise a string for serviceType comparison. Same rules as
/// normalizeCategory() — kept as a separate named function so the
/// intent is clear at call sites and so the two can diverge later
/// if a serviceType-specific quirk ever needs different handling.
///
/// ── WHY THIS EXISTS ──
/// `category` matching has always been normalised (see above) to
/// survive wording drift between a provider's registration picker
/// and whatever a booking page sends. Historically `serviceType`
/// matching was NOT normalised — it used a strict Firestore
/// `isEqualTo` query. That meant a provider doc with
/// `serviceType: "Civil "` (trailing space) or `"civil-work"`
/// instead of `"civil"` would silently never match ANY order for
/// that vertical, regardless of category — the same class of bug
/// that used to break water-order routing, just one field over.
/// `_notifyMatchingProviders()` below now uses this to catch that
/// case via a client-side fallback scan.
String normalizeServiceType(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

/// Builds the full set of normalised category candidates for an
/// order: every legacy category-ish field + every entry in
/// `services`.
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

/// Returns true if `orderData` should be visible/notified to a
/// provider who has selected `providerCats`.
bool categoryMatch(
  Map<String, dynamic> orderData,
  List<String> providerCats, {
  String debugOrderId = '',
}) {
  if (providerCats.isEmpty) return true;

  final normProviderCats = providerCats
      .map(normalizeCategory)
      .where((s) => s.isNotEmpty)
      .toSet();

  final orderCandidates = orderCategoryCandidates(orderData);

  if (orderCandidates.isEmpty) {
    debugPrint('[catMatch] $debugOrderId: order has no category/services info '
        '— provider has categories selected, falling back to SHOW (cannot restrict '
        'what we cannot read). Fix the originating booking page to pass `category` '
        'or `services` if this should actually be filtered.');
    return true;
  }

  final matched = orderCandidates.any(normProviderCats.contains);
  if (!matched) {
    debugPrint('[catMatch] $debugOrderId: SKIP — order candidates $orderCandidates '
        'do not overlap with provider categories $normProviderCats');
  }
  return matched;
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
  //
  // Provider Firestore documents now use a readable ID
  // (e.g. CIV-765791) instead of the Firebase UID.
  // This helper resolves uid → readable doc ID via the
  // provider_uid_lookup collection written at registration.
  //
  // Returns null when no lookup entry exists.
  // ==========================================================
  static Future<String?> _getProviderDocId(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final snap =
          await _db.collection('provider_uid_lookup').doc(uid).get();
      final id = (snap.data()?['providerId'] ?? '').toString().trim();
      return id.isNotEmpty ? id : null;
    } catch (e) {
      debugPrint('[OrderService] _getProviderDocId error: $e');
      return null;
    }
  }

  // ==========================================================
  // PLACE ORDER
  //
  // After writing the order, this fans out a notification to
  // every APPROVED provider whose:
  //   • serviceType  matches the order's serviceType
  //   • categories[] overlaps with categoryMatch() candidates
  //     (see the shared categoryMatch()/orderCategoryCandidates()
  //     functions above — kept IN SYNC with the dashboard).
  //
  // `category` is snapped onto the canonical serviceConfigs list
  // for this serviceType via resolveCanonicalCategory() BEFORE
  // it's stored or matched. This is what makes "provider only
  // gets orders in their selected categories" actually reliable —
  // both sides of the comparison now draw from the same
  // vocabulary whenever possible, instead of hoping booking-page
  // wording and registration-form wording happen to agree.
  //
  // NEW: if the caller doesn't pass `category` at all, it is now
  // auto-seeded from `services.first` (when available) before
  // canonicalization. This shrinks the "no category info at all"
  // case that otherwise falls back to broadcasting the order to
  // every approved provider in that vertical — it does not
  // replace passing `category` explicitly from booking pages,
  // which is still the most reliable fix.
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

    // The readable provider doc ID (e.g. CIV-765791), not the Firebase UID.
    // Only supplied when the caller already knows which provider to assign.
    String? providerId,

    // Category chosen by the customer (e.g. "Ice Blocks").
    // Used to filter which providers see/receive this order.
    // Snapped onto the canonical serviceConfigs category list for
    // `serviceType` before storage/matching — see
    // resolveCanonicalCategory() above. If omitted, this is now
    // auto-derived from `services.first` when possible — but
    // passing it explicitly from the booking page is still the
    // #1 fix for "order isn't showing up for the right provider"
    // bugs, since a single category string is far less ambiguous
    // than the first item of a multi-item services list.
    String? category,

    bool isEnquiry = false,

    // Legacy positional params kept for call-site compat
    String providerName = '',
    Object? providerUserId,
  }) async {
    final hasCategory = category != null && category.trim().isNotEmpty;

    // Auto-seed category from services[] when the caller forgot to
    // pass one explicitly, so fewer orders fall through to the
    // "no category info → broadcast to everyone" fallback in
    // categoryMatch(). rawCategory below still records exactly
    // what the caller sent, for audit purposes.
    final String effectiveCategory =
        hasCategory ? category : (services.isNotEmpty ? services.first : '');

    if (!hasCategory && services.isEmpty) {
      debugPrint('[OrderService.placeOrder] WARNING: neither `category` nor '
          '`services` was provided for a $serviceType order. This order will '
          'be shown to ALL approved $serviceType providers regardless of their '
          'selected categories. Pass `category` and/or `services` from the '
          'booking page to enable correct filtering.');
    } else if (!hasCategory) {
      debugPrint('[OrderService.placeOrder] NOTE: `category` was not passed '
          'for a $serviceType order — auto-derived "$effectiveCategory" from '
          'services[0]. Prefer passing `category` explicitly from the '
          'booking page for more reliable routing.');
    }

    // ── Resolve provider details ──────────────────────────────────────────────
    String resolvedProviderId     = providerId ?? '';
    String resolvedProviderName   = '';
    String resolvedProviderUserId = '';

    if (resolvedProviderId.isNotEmpty) {
      final snap = await _db
          .collection('providers')
          .doc(resolvedProviderId)
          .get();
      final d = snap.data() ?? {};
      resolvedProviderName   =
          (d['businessName'] ?? d['providerName'] ?? d['name'] ?? '')
              .toString();
      resolvedProviderUserId =
          (d['userId'] ?? d['uid'] ?? '').toString();
    }

    final orderId               = generateOrderId(userName);
    final docRef                = _db.collection('orders').doc(orderId);
    // Always store serviceType as lowercase so Firestore equality
    // queries from the dashboard (_svcNorm) match reliably.
    final normalizedServiceType = serviceType.trim().toLowerCase();

    // Snap the (possibly auto-derived) category onto the canonical
    // serviceConfigs list for this serviceType. Stored in the
    // canonical casing so it lines up exactly with what providers
    // pick at registration.
    final canonicalCategory = resolveCanonicalCategory(
      effectiveCategory,
      normalizedServiceType,
    );

    // Also canonicalize each entry in `services` where possible —
    // multi-item bookings (e.g. laundry) rely on this list for
    // matching just as much as `category` does.
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

      'providerId':     resolvedProviderId,
      'providerUserId': resolvedProviderUserId,
      'providerName':   resolvedProviderName,

      'provider': {
        'providerId':     resolvedProviderId,
        'providerUserId': resolvedProviderUserId,
        'providerName':   resolvedProviderName,
      },

      // Stored BOTH forms so old and new clients can read it.
      'serviceType': normalizedServiceType,   // lowercase — queried by dashboard
      'serviceName': normalizedServiceType,
      'services':    canonicalServices,

      // Category stored in canonical casing (snapped to
      // serviceConfigs) whenever a confident match was found;
      // otherwise the original raw value is kept. Matching always
      // normalises both sides regardless — see normalizeCategory().
      'category': canonicalCategory,

      // Kept for debugging/audit — what the customer/booking page
      // actually sent before canonicalization/auto-derivation, in
      // case you ever need to trace a mismatch back to its source.
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
        'paid':        !isEnquiry,
        'method':      isEnquiry ? 'enquiry' : 'upi',
      },

      'adults':    adults    ?? 0,
      'children':  children  ?? 0,
      'visitType': visitType ?? '',

      'isEnquiry': isEnquiry,

      'status':      isEnquiry ? OrderStatus.enquiry : OrderStatus.pending,
      'isAssigned':  resolvedProviderId.isNotEmpty,
      'isCompleted': false,

      'declineReason': '',
      'cancelReason':  '',
      'cancelledBy':   '',

      'createdBy':     createdBy,
      'createdByRole': createdByRole,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ── Fan-out notification to matching providers ──────────────────────────
    // Applies to BOTH regular orders and enquiries — isEnquiry only
    // affects `status`/`payment`, not whether matching providers get
    // notified. An enquiry with a category should reach exactly the
    // same set of providers a paid order in that category would.
    await _notifyMatchingProviders(
      orderId:       orderId,
      orderData: {
        'category': canonicalCategory,
        'services': canonicalServices,
      },
      serviceType:   normalizedServiceType,
      category:      canonicalCategory,
      userName:      userName,
      date:          date,
      time:          time,
      totalAmount:   totalAmount,
      specificProviderId: resolvedProviderId.isNotEmpty
          ? resolvedProviderId
          : null,
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
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':     OrderStatus.accepted,
      'isAssigned': true,
      'updatedAt':  FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '✅ Booking Accepted',
      body:    '$providerName has accepted your $serviceType booking. '
               'They will contact you soon.',
      type:    NotificationType.bookingAccepted,
    );
  }

  static Future<void> rejectOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();

    await _db.collection('orders').doc(orderId).update({
      'status':             OrderStatus.rejected,
      'declineReason':      trimmedReason,
      'cancelReason':       trimmedReason,
      'cancelledBy':        'provider',
      'providerCancelNote': trimmedReason,
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '❌ Booking Rejected',
      body:    '$providerName has rejected your $serviceType booking. '
               'Reason: $trimmedReason',
      type:    NotificationType.bookingRejected,
    );
  }

  static Future<void> completeOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
  }) async {
    await _db.collection('orders').doc(orderId).update({
      'status':      OrderStatus.completed,
      'isCompleted': true,
      'updatedAt':   FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '🎉 Service Completed',
      body:    'Your $serviceType service by $providerName has been '
               'marked as completed. Thank you!',
      type:    NotificationType.serviceCompleted,
    );
  }

  static Future<void> providerCancelOrder({
    required String orderId,
    required String userId,
    required String providerName,
    required String serviceType,
    required String reason,
  }) async {
    final trimmedReason = reason.trim();

    await _db.collection('orders').doc(orderId).update({
      'status':             OrderStatus.cancelled,
      'declineReason':      trimmedReason,
      'cancelReason':       trimmedReason,
      'cancelledBy':        'provider',
      'providerCancelNote': trimmedReason,
      'updatedAt':          FieldValue.serverTimestamp(),
    });

    await notifyUser(
      userId:  userId,
      orderId: orderId,
      title:   '🚫 Booking Cancelled by Provider',
      body:    '$providerName cancelled your $serviceType booking. '
               'Reason: $trimmedReason',
      type:    NotificationType.bookingRejected,
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
              'type':       NotificationType.userCancelled,
              'orderId':    orderId,
              'receiverId': providerUserId,
            },
            'sent':      false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  // ==========================================================
  // FAN-OUT: notify ALL matching approved providers
  //
  // Matching happens in two layers, both now defended with a
  // primary (fast, indexed) query + a client-side normalized
  // fallback — the same defensive pattern business_dashboard_page
  // already uses for its Available Jobs streams:
  //
  //   1. serviceType — primary: exact Firestore `isEqualTo` query.
  //      fallback: broad scan of all approved providers, filtered
  //      by normalizeServiceType() equality. Catches providers
  //      whose serviceType field has different casing/spacing from
  //      the order's serviceType.
  //
  //   2. category    — delegated entirely to the shared
  //      categoryMatch() function above so this stays byte-for-byte
  //      consistent with `_categoryMatch()` in
  //      business_dashboard_page.dart. A provider only ever gets a
  //      push notification for an order that will actually show up
  //      in their Available tab, and vice versa.
  //
  // When specificProviderId is given (direct assignment), only
  // that one provider is notified — no filtering applies since the
  // assignment was already explicit.
  // ==========================================================
  static Future<void> _notifyMatchingProviders({
    required String orderId,
    required Map<String, dynamic> orderData,
    required String serviceType,
    required String category,
    required String userName,
    required DateTime date,
    required String time,
    required double totalAmount,
    String? specificProviderId,
  }) async {
    try {
      if (specificProviderId != null && specificProviderId.isNotEmpty) {
        // Direct assignment — notify only this provider, no category check.
        final doc = await _db
            .collection('providers')
            .doc(specificProviderId)
            .get();
        if (!doc.exists) return;
        await _sendProviderNotification(
          providerId:  doc.id,
          orderId:     orderId,
          serviceType: serviceType,
          category:    category,
          userName:    userName,
          date:        date,
          time:        time,
          totalAmount: totalAmount,
        );
        return;
      }

      final normSvc = normalizeServiceType(serviceType);

      // Primary: fast indexed query — works whenever the provider's
      // stored serviceType is byte-identical to the order's.
      final primarySnap = await _db
          .collection('providers')
          .where('status', isEqualTo: 'approved')
          .where('serviceType', isEqualTo: serviceType)
          .get();

      // Fallback: broad scan of ALL approved providers, filtered
      // client-side via normalizeServiceType(). Only the extra
      // (non-primary) docs are added, so this never duplicates work
      // for the common case where serviceType strings already match
      // exactly — it only rescues providers that would otherwise be
      // silently skipped due to a casing/spacing mismatch.
      final fallbackSnap =
          await _db.collection('providers').where('status', isEqualTo: 'approved').get();

      final seen = <String>{};
      final candidateDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (final doc in primarySnap.docs) {
        if (seen.add(doc.id)) candidateDocs.add(doc);
      }
      for (final doc in fallbackSnap.docs) {
        if (seen.contains(doc.id)) continue;
        final docSvc = (doc.data()['serviceType'] ?? '').toString();
        if (normalizeServiceType(docSvc) == normSvc) {
          seen.add(doc.id);
          candidateDocs.add(doc);
        }
      }

      final rescuedCount = candidateDocs.length - primarySnap.docs.length;
      debugPrint('[OrderService] order $orderId: found ${candidateDocs.length} '
          'approved $serviceType providers to check '
          '(${primarySnap.docs.length} exact match'
          '${rescuedCount > 0 ? ', $rescuedCount rescued via normalized fallback — '
              'check those providers\' serviceType field for casing/spacing drift' : ''})');

      int notifiedCount = 0;

      for (final doc in candidateDocs) {
        final provData = doc.data();

        final rawCats      = (provData['categories'] as List?) ?? [];
        final providerCats = rawCats.map((e) => e.toString()).toList();

        // ── Every provider ONLY gets notified for orders that match
        // ── their own selected categories. Providers with an empty
        // ── categories[] are treated as "unrestricted" — see
        // ── categoryMatch() rule #2 above — by design, so a provider
        // ── who hasn't picked specific categories still gets all
        // ── work for their serviceType.
        final shouldNotify = categoryMatch(
          orderData,
          providerCats,
          debugOrderId: '$orderId -> provider ${doc.id}',
        );

        if (!shouldNotify) continue;

        await _sendProviderNotification(
          providerId:  doc.id,
          orderId:     orderId,
          serviceType: serviceType,
          category:    category,
          userName:    userName,
          date:        date,
          time:        time,
          totalAmount: totalAmount,
        );
        notifiedCount++;
      }

      debugPrint('[OrderService] order $orderId: notified $notifiedCount / '
          '${candidateDocs.length} $serviceType providers (category="$category")');
    } catch (e) {
      debugPrint('[OrderService] _notifyMatchingProviders error: $e');
    }
  }

  // ── Send notification + FCM queue entry for one provider doc ──────────────
  static Future<void> _sendProviderNotification({
    required String providerId,
    required String orderId,
    required String serviceType,
    required String category,
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

    final catLabel = category.isNotEmpty ? ' ($category)' : '';
    final title    = '📦 New Order Received';
    final body     =
        'Hi $providerName, new $serviceType$catLabel booking from $userName '
        'on ${_formatDate(date)} at $time.'
        '${totalAmount > 0 ? ' Amount ₹${totalAmount.toStringAsFixed(0)}' : ''}';

    // In-app notification document
    await _sendNotification(
      receiverId: providerUserId,
      role:       'provider',
      orderId:    orderId,
      title:      title,
      body:       body,
      type:       NotificationType.newBooking,
    );

    // FCM push via Cloud Function queue
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
          'type':       NotificationType.newBooking,
          'orderId':    orderId,
          'receiverId': providerUserId,
        },
        'sent':      false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ==========================================================
  // NOTIFY USER — status updates from provider
  // ==========================================================
  static Future<void> notifyUser({
    required String userId,
    required String orderId,
    required String title,
    required String body,
    required String type,
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
      );

      final userDoc  = await _db.collection('users').doc(userId).get();
      final fcmToken =
          (userDoc.data()?['fcmToken'] ?? '').toString().trim();

      if (fcmToken.isNotEmpty) {
        await _db.collection('fcm_queue').add({
          'token':      fcmToken,
          'receiverId': userId,
          'orderId':    orderId,
          'title':      title,
          'body':       body,
          'type':       type,
          'data': {
            'type':       type,
            'orderId':    orderId,
            'receiverId': userId,
          },
          'sent':      false,
          'createdAt': FieldValue.serverTimestamp(),
        });
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
  }) async {
    await _db.collection('notifications').add({
      'receiverId': receiverId,
      'senderId':   '',
      'role':       role,
      'orderId':    orderId,
      'title':      title,
      'body':       body,
      'type':       type,
      'read':       false,
      'createdAt':  FieldValue.serverTimestamp(),
    });
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