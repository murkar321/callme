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
// booking pages *should* draw from. `resolveCanonicalCategory()`
// snaps whatever a booking page sends onto the matching entry in
// `serviceConfigs` for that serviceType — including recognizing a
// SPECIFIC bookable item (e.g. "20L Water Jar Exchange") and
// snapping it to its PARENT category (e.g. "Jar Exchange/Return")
// via `parentCategoryForSubService()` below (Stage 0).
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

// ============================================================
// SUB-SERVICE → CANONICAL CATEGORY REVERSE LOOKUP
//
// See `ServiceConfig.subServices` in service_config.dart for the
// full story. Short version: a customer often books a SPECIFIC
// item ("20L Water Jar Exchange", "Residential House Construction")
// that lives inside a broader category a provider registers under
// ("Jar Exchange/Return", "New Build"). Those two strings frequently
// share zero significant words, so plain fuzzy word-overlap matching
// alone can't connect them — this bridges that gap.
// ============================================================
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

/// Snaps `rawCategory` onto the closest entry in
/// `serviceConfigs[serviceType].serviceCategories`, if any.
/// Returns the original trimmed string if no confident match is found.
///
/// Used for the `category` field. Deliberately NOT used for
/// `subCategory` — see `cleanSubCategory()` below — since a
/// subCategory's whole purpose is to preserve the SPECIFIC item
/// being booked, and this function's Stage 0 would otherwise
/// collapse it straight to its parent category, making it
/// redundant with `category`.
String resolveCanonicalCategory(String rawCategory, String serviceType) {
  final raw = rawCategory.trim();
  if (raw.isEmpty) return raw;

  // Stage 0: is `raw` actually a SPECIFIC bookable item rather than
  // a top-level category? If so, snap straight to its parent.
  final subParent = parentCategoryForSubService(raw, serviceType);
  if (subParent != null) return subParent;

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

/// Lightweight cleanup for `subCategory` — trims only. Deliberately
/// does NOT run through resolveCanonicalCategory()'s Stage 0, which
/// would collapse a specific item straight to its parent category
/// and make `subCategory` redundant with `category`. The specific
/// item name is exactly what makes `subCategory` useful for display
/// and for matching against a provider's own `subCategories[]`
/// selections (if your registration flow lets providers opt into
/// specific items, not just broad categories).
String cleanSubCategory(String raw) => raw.trim();

// ============================================================
// SHARED CATEGORY-MATCHING LOGIC
//
// IMPORTANT: This logic MUST stay byte-for-byte identical between
// business_dashboard_page.dart (what a provider SEES in Available
// Enquiries/Orders/Bookings) and this file's
// _notifyMatchingProviders() (what a provider is PUSH NOTIFIED
// about). Both call categoryMatchFuzzy() below — neither file
// re-implements its own copy. If they ever drift apart, a provider
// can get a push notification for an order that never shows up in
// their "Available" tab, or vice versa.
//
// categoryMatchFuzzy() now takes an OPTIONAL `providerSubCats` list
// alongside `providerCats`, and merges the two into one pool before
// running:
//   Stage 1 — exact match (categoryMatch())
//   Stage 2 — fuzzy word-overlap on RAW (un-normalized) strings
//   Stage 3 — sub-service reverse lookup (parentCategoryForSubService())
// This means a provider who only ever picked SPECIFIC subCategories
// (never a broad top-level category) is matched correctly too, not
// just providers who picked broad categories.
// ============================================================

/// Normalise a string for category comparison: trim, lowercase,
/// collapse whitespace/underscores/hyphens.
String normalizeCategory(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

/// Normalise a string for serviceType comparison.
String normalizeServiceType(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');

/// Some provider documents store `serviceType` as a TOP-LEVEL field,
/// others store it NESTED under a `service` map. This checks both
/// shapes so a provider is matched correctly no matter which one
/// its document uses.
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

/// Reads a provider document's broad, top-level categories[] field —
/// what a provider selects at registration (e.g. "Jar Exchange/Return").
List<String> providerCategories(Map<String, dynamic> providerData) {
  final raw = (providerData['categories'] as List?) ?? const [];
  return raw
      .map((e) => e.toString().trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Reads a provider document's SPECIFIC subCategories[] field, if
/// your registration flow supports granular sub-service selection
/// (e.g. "20L Water Jar Exchange"). Safe to call even if the field
/// doesn't exist yet — just returns an empty list, so this is fully
/// backward-compatible with providers who only ever picked broad
/// categories.
List<String> providerSubCategories(Map<String, dynamic> providerData) {
  final raw = (providerData['subCategories'] as List?) ?? const [];
  return raw
      .map((e) => e.toString().trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// Merges categories + subCategories into one de-duplicated display
/// list (de-duped by normalized value, but keeping original casing
/// of the first occurrence). Used for debug logs and anywhere the UI
/// wants to show "everything this provider is matched on" as one
/// combined pool rather than two separate lists.
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

/// Builds the full set of NORMALISED (separator-stripped) category
/// candidates for an order — used for Stage-1 exact matching. Reads
/// `category`, `serviceCategory`, `subCategory`, `jobCategory`, and
/// every string in `services[]`.
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

/// Builds the full set of RAW (trimmed + lowercased, but NOT
/// separator-stripped) category strings for an order — used for
/// Stage 2/3 fuzzy + sub-service matching, since word-splitting
/// requires the original spaces/punctuation.
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

/// Returns true if `orderData` should be visible/notified to a
/// provider who has selected `providerCats` — STAGE 1 (exact) only.
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

Set<String> _significantRawWords(String raw) => raw
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.length >= 3)
    .toSet();

/// Full pipeline: Stage 1 (exact) → Stage 2 (fuzzy word overlap) →
/// Stage 3 (sub-service reverse lookup) — run against the MERGED
/// pool of `providerCats` ∪ `providerSubCats`.
///
/// `providerSubCats` is optional and defaults to empty, so every
/// existing call site that only ever passed broad categories keeps
/// working exactly as before with zero changes required.
bool categoryMatchFuzzy(
  Map<String, dynamic> orderData,
  List<String> providerCats, {
  List<String> providerSubCats = const [],
  String debugOrderId = '',
}) {
  // Merge once, up front, so all three stages see the same pool —
  // a provider matches if EITHER their broad categories OR their
  // specific subCategories line up with the order.
  final mergedProviderCats = providerSubCats.isEmpty
      ? providerCats
      : <String>{...providerCats, ...providerSubCats}.toList();

  // Stage 1: exact — handles the large majority of correctly
  // canonicalized orders without ever reaching fuzzy logic.
  if (categoryMatch(orderData, mergedProviderCats, debugOrderId: debugOrderId)) {
    return true;
  }

  // Stage 2: fuzzy word-overlap on RAW (un-normalized) strings —
  // reaching here means both sides have real data but Stage 1 found
  // no exact overlap.
  final orderWords = orderCategoryCandidatesRaw(orderData)
      .expand(_significantRawWords)
      .toSet();
  final providerWords = mergedProviderCats
      .expand(_significantRawWords)
      .toSet();

  if (orderWords.intersection(providerWords).isNotEmpty) {
    debugPrint('[catMatch:fuzzy] $debugOrderId: MATCHED via fuzzy word overlap — '
        'order words $orderWords ~ provider words $providerWords (no exact '
        'match).');
    return true;
  }

  // Stage 3 — sub-service reverse lookup. Bridges the case where the
  // order's category/subCategory/services values are a SPECIFIC
  // bookable item ("20L Water Jar Exchange") while the provider
  // registered under the BROADER category it belongs to ("Jar
  // Exchange/Return") — those two strings can share zero significant
  // words, so Stage 2 can't connect them.
  final serviceType = (orderData['serviceType'] ?? '').toString();
  if (serviceType.isNotEmpty) {
    final normProviderCats = mergedProviderCats
        .map(normalizeCategory)
        .where((s) => s.isNotEmpty)
        .toSet();

    for (final rawCandidate in orderCategoryCandidatesRaw(orderData)) {
      final parent = parentCategoryForSubService(rawCandidate, serviceType);
      if (parent == null) continue;
      if (normProviderCats.contains(normalizeCategory(parent))) {
        debugPrint('[catMatch:fuzzy] $debugOrderId: MATCHED via sub-service '
            'lookup — order item "$rawCandidate" resolves to parent category '
            '"$parent", which is in provider categories $mergedProviderCats.');
        return true;
      }
    }
  }

  debugPrint('[catMatch:fuzzy] $debugOrderId: SKIP — no exact, fuzzy, OR '
      'sub-service match. order words $orderWords vs provider words '
      '$providerWords. Genuinely unrelated categories — nothing more to do '
      'here.');
  return false;
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
  // NEW: `subCategory` — the SPECIFIC item being booked (e.g. "20L
  // Water Jar Exchange"), stored alongside the broader `category`
  // (e.g. "Jar Exchange/Return"). Both are included in the
  // notification fan-out's matching data, so a provider who only
  // ever selected subCategories (never broad categories) still gets
  // notified — see categoryMatchFuzzy()'s merged-pool matching above.
  //
  // `category` is canonicalized via resolveCanonicalCategory()
  // (snaps onto serviceConfigs vocabulary, including resolving a
  // specific item straight to its parent category). `subCategory` is
  // only lightly cleaned via cleanSubCategory() — see that function's
  // doc comment for why it's NOT run through the same canonicalizer.
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
    // Only supplied when the caller already knows which provider to assign
    // (a genuine pinned assignment) — see booking_page.dart's
    // `_isPinnedProvider`. Passing this makes placeOrder() take the
    // DIRECT-ASSIGNMENT path below, which skips category matching
    // entirely and notifies ONLY this one provider.
    String? providerId,

    // Broad category (e.g. "Jar Exchange/Return"). Snapped onto the
    // canonical serviceConfigs category list for `serviceType` via
    // resolveCanonicalCategory(). If omitted, auto-derived from
    // `services.first` when possible.
    String? category,

    // NEW: the SPECIFIC item being booked (e.g. "20L Water Jar
    // Exchange"). Optional — omit for multi-item cart orders where
    // `services[]` already carries per-item detail.
    String? subCategory,

    bool isEnquiry = false,

    // Legacy positional params kept for call-site compat
    String providerName = '',
    Object? providerUserId,
  }) async {
    final hasCategory = category != null && category.trim().isNotEmpty;

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
    // queries from the dashboard match reliably.
    final normalizedServiceType = serviceType.trim().toLowerCase();

    // Snap the (possibly auto-derived) category onto the canonical
    // serviceConfigs list for this serviceType.
    final canonicalCategory = resolveCanonicalCategory(
      effectiveCategory,
      normalizedServiceType,
    );

    // Sub-category: lightly cleaned only, NOT canonicalized to a
    // parent category — see cleanSubCategory()'s doc comment.
    final cleanedSubCategory = cleanSubCategory(subCategory ?? '');

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

      'serviceType': normalizedServiceType,   // lowercase — queried by dashboard
      'serviceName': normalizedServiceType,
      'services':    canonicalServices,

      // Category stored in canonical casing whenever a confident
      // match was found; otherwise the original raw value is kept.
      'category': canonicalCategory,

      // NEW: the specific item being booked, kept as-is (trimmed)
      // so it stays distinct from `category` for display and for
      // matching against a provider's subCategories[] selections.
      'subCategory': cleanedSubCategory,

      // Kept for debugging/audit — what the customer/booking page
      // actually sent before canonicalization/auto-derivation.
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
  // UPDATED: now reads BOTH providerCategories() and
  // providerSubCategories() for each candidate provider and passes
  // both into categoryMatchFuzzy()'s merged-pool matching — a
  // provider who only ever picked specific subCategories (never a
  // broad category) is now notified correctly too, exactly matching
  // what the dashboard's Available tab will show them.
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
          subCategory: subCategory,
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
        final provData    = doc.data();
        final providerCats    = providerCategories(provData);
        final providerSubCats = providerSubCategories(provData);

        // ── Every provider ONLY gets notified for orders that match
        // ── their own categories AND/OR subCategories, via the SAME
        // ── merged-pool exact+fuzzy+sub-service logic the dashboard
        // ── uses to decide what's visible. Providers with BOTH lists
        // ── empty are treated as "unrestricted" (categoryMatch()
        // ── rule: providerCats.isEmpty → true) by design.
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
          '(category="$category", subCategory="$subCategory")');
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

    // Prefer the more specific subCategory in the notification text
    // when available, since that's what the provider actually cares
    // about seeing at a glance; fall back to the broad category.
    final displayCat = subCategory.isNotEmpty ? subCategory : category;
    final catLabel    = displayCat.isNotEmpty ? ' ($displayCat)' : '';
    final title       = '📦 New Order Received';
    final body        =
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