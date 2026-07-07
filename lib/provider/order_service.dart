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

  // FIX: NEW — sent to every OTHER matching provider the instant one
  // provider accepts an order, so it doesn't just silently vanish from
  // their Available tab with no explanation. See
  // OrderService.notifyOthersOrderTaken() below.
  static const String orderTakenByOther = 'order_taken_by_other';
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
  // FIX: `providerCats.isEmpty` used to short-circuit straight to
 
  // fixing it here fixes both places at once, by design.
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
/// Public entry point used by both business_dashboard_page.dart (tab
/// visibility) and _notifyMatchingProviders() / notifyOthersOrderTaken()
/// below (push fan-out). All call sites pass `providerCats` (main
/// categories[]) and `providerSubCats` (subCategories[]) — merged into
/// one pool and matched EXACTLY (normalized) against the order's
/// category / services.
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

    String? providerId,

    String? category,

    String? subCategory,

    bool isEnquiry = false,

    String? paymentMethod,

    bool? isPaid,

    // Legacy positional params kept for call-site compat
    String providerName = '',
    Object? providerUserId, required List<Map<String, dynamic>> itemBreakdown,
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

    // ── Resolve provider details (direct-assignment only) ─────────────────────
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

      'providerId':     resolvedProviderId,
      'providerUserId': resolvedProviderUserId,
      'providerName':   resolvedProviderName,

      'provider': {
        'providerId':     resolvedProviderId,
        'providerUserId': resolvedProviderUserId,
        'providerName':   resolvedProviderName,
      },

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

    // ── Fan-out order + notification to matching providers ─────────────────────
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
    String providerId = '',
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
              'type':       NotificationType.userCancelled,
              'orderId':    orderId,
              'receiverId': providerUserId,
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
  // to business_dashboard_page.dart's `_categoryMatch()`, so "got
  // notified" and "shows up in Available" can never disagree.
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
          '(category="$category", subCategory="$subCategory") — EXACT match only');
    } catch (e) {
      debugPrint('[OrderService] _notifyMatchingProviders error: $e');
    }
  }

  // ==========================================================
  // FIX: NEW — FCFS "taken" notice to every OTHER matching provider.
  //
  // Previously, the instant one provider accepted an order, it just
  // disappeared from every other matching provider's Available tab
  // (via _isAvailable()'s isAssigned/providerUserId check) with zero
  // explanation — the order's `notifications` doc from creation time
  // stayed in their Notifications list forever, looking like a job
  // that's still up for grabs. That's exactly the confusion reported:
  // "message stays and provider gets confused."
  //
  // This runs the EXACT SAME candidate-gathering + categoryMatchFuzzy()
  // pipeline as _notifyMatchingProviders() (so "who got the original
  // alert" and "who gets the taken notice" always agree), skips the
  // provider who just accepted, and sends both a `notifications` doc
  // and an `fcm_queue` entry — so it rings on-screen (via
  // FirebaseMessaging.onMessage) AND off-screen/terminated (via the
  // background handler + Cloud Function), exactly like every other
  // push in this app.
  //
  // Call this from the dashboard's `_accept()` right after the order
  // is transactionally marked accepted.
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
              'type':       NotificationType.orderTakenByOther,
              'orderId':    orderId,
              'receiverId': providerUserId,
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

    await _sendNotification(
      receiverId: providerUserId,
      role:       'provider',
      orderId:    orderId,
      title:      title,
      body:       body,
      type:       NotificationType.newBooking,
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
          'type':       NotificationType.newBooking,
          'orderId':    orderId,
          'receiverId': providerUserId,
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
  // NOTIFY USER — status updates from provider
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