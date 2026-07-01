import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../profile/notification_service.dart' show NotificationType;

class ApproveProvidersPage extends StatefulWidget {
  const ApproveProvidersPage({super.key});

  @override
  State<ApproveProvidersPage> createState() => _ApproveProvidersPageState();
}

class _ApproveProvidersPageState extends State<ApproveProvidersPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String search = "";

  // =====================================================
  // STREAM — only pending providers
  // =====================================================

  Stream<QuerySnapshot> pendingProvidersStream() {
    return firestore
        .collection("providers")
        .where("status", isEqualTo: "pending")
        .snapshots();
  }

  // =====================================================
  // FIELD EXTRACTION HELPER
  // =====================================================
  // Mirrors notification_router.dart's `_first()` so the businessName /
  // serviceType we save on the notification always agree with what the
  // dashboard route expects. Tries top-level keys, then nested business/
  // service maps.
  String _firstField(Map<String, dynamic> merged, List<String> keys) {
    for (final k in keys) {
      final v = merged[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  ({String businessName, String serviceType}) _extractIdentity(
    Map<String, dynamic> data,
  ) {
    final business = (data["business"] as Map<String, dynamic>?) ?? {};
    final service = (data["service"] as Map<String, dynamic>?) ?? {};

    final merged = <String, dynamic>{
      ...data,
      ...business,
      ...service,
    };

    final businessName = _firstField(
      merged,
      ['businessName', 'business_name', 'name', 'providerName'],
    );
    final serviceType = _firstField(
      merged,
      ['serviceType', 'service_type', 'service', 'category'],
    );

    return (businessName: businessName, serviceType: serviceType);
  }

  // =====================================================
  // SEND FCM HELPER
  // =====================================================

  Future<void> _sendFcm({
    required String token,
    required String title,
    required String body,
    required String providerId,
    required String userId,     // ✅ needed for fcm_queue rules
    required String type,
    String? businessName,
    String? serviceType,
    String? reason,
  }) async {
    if (token.trim().isEmpty) return;

    final Map<String, dynamic> payload = {
      "token":      token.trim(),
      "title":      title,
      "body":       body,
      "providerId": providerId,
      "userId":     userId,     // ✅ fcm_queue rule: userId == uid()
      "receiverId": userId,     // ✅ fcm_queue rule: receiverId == uid()
      "type":       type,
      "createdAt":  FieldValue.serverTimestamp(),
      "sent":       false,
    };

    // ✅ Carried through the FCM data payload so routeNotification() can
    // open BusinessDashboardPage instantly, without a second Firestore read.
    if (businessName != null && businessName.trim().isNotEmpty) {
      payload["businessName"] = businessName.trim();
    }
    if (serviceType != null && serviceType.trim().isNotEmpty) {
      payload["serviceType"] = serviceType.trim();
    }
    if (reason != null && reason.trim().isNotEmpty) {
      payload["reason"] = reason.trim();
    }

    await firestore.collection("fcm_queue").add(payload);
  }

  // =====================================================
  // SAVE NOTIFICATION (in-app bell)
  // =====================================================

  Future<void> _saveNotification({
    required String userId,     // ✅ receiverId for notifications rules
    required String title,
    required String body,
    required String type,       // ✅ FIX: this was never being saved before,
                                 // so NotificationPage's onNotificationTap
                                 // always got a null `type` and routing fell
                                 // through to the default case.
    String? providerId,
    String? businessName,
    String? serviceType,
    String? reason,
  }) async {
    final Map<String, dynamic> notification = {
      "title":      title,
      "body":       body,
      "type":       type,       // ✅ now present — this is what
                                 // routeNotification()'s switch matches on
      "read":       false,
      "receiverId": userId,     // ✅ notifications rule: receiverId == uid()
      "createdAt":  FieldValue.serverTimestamp(),
    };

    // ✅ So the notification list (and the dashboard route) both know
    // exactly which provider + which service this notification is about.
    if (providerId != null && providerId.trim().isNotEmpty) {
      notification["providerId"] = providerId.trim();
    }
    if (businessName != null && businessName.trim().isNotEmpty) {
      notification["businessName"] = businessName.trim();
    }
    if (serviceType != null && serviceType.trim().isNotEmpty) {
      notification["serviceType"] = serviceType.trim();
    }
    if (reason != null && reason.trim().isNotEmpty) {
      notification["reason"] = reason.trim();
    }

    // ✅ Top-level notifications collection — subcollection isn't covered by rules
    await firestore.collection("notifications").add(notification);
  }

  // =====================================================
  // UPDATE USER ROLE HELPER
  // =====================================================

  Future<void> _updateUserRole(String userId, String role) async {
    // users doc ID = email in your setup, so query by uid field
    final userQuery = await firestore
        .collection("users")
        .where("uid", isEqualTo: userId)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      await userQuery.docs.first.reference.update({"role": role});
    } else {
      // Fallback: if uid field not stored, try doc ID = uid
      await firestore
          .collection("users")
          .doc(userId)
          .set({"role": role}, SetOptions(merge: true));
    }
  }

  // =====================================================
  // APPROVE
  // =====================================================

  Future<void> approveProvider(String providerId) async {
    try {
      final providerDoc =
          await firestore.collection("providers").doc(providerId).get();

      if (!providerDoc.exists) return;

      final data      = providerDoc.data() ?? {};
      final fcmToken  = (data["fcmToken"] ?? "").toString();
      final business  = (data["business"] as Map<String, dynamic>?) ?? {};
      final ownerName = (business["ownerName"] ?? "there").toString();

      // ✅ Read userId (Firebase UID) stored inside the provider doc
      final String userId = (data["userId"] ?? "").toString();
      if (userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Provider userId missing — cannot approve."),
          ),
        );
        return;
      }

      // ✅ Pull businessName + serviceType so the approval message says
      // *which* service was approved, and so the notification carries
      // everything BusinessDashboardPage needs.
      final identity = _extractIdentity(data);
      final businessName = identity.businessName.isNotEmpty
          ? identity.businessName
          : "your business";
      final serviceType = identity.serviceType;

      final String title = "🎉 Account Approved!";
      final String body = serviceType.isNotEmpty
          ? "Congratulations $ownerName! Your $serviceType business \"$businessName\" has been approved. You can now start receiving $serviceType bookings."
          : "Congratulations $ownerName! Your provider account has been approved. You can now start receiving bookings.";

      // 1 — Update provider doc status
      await firestore.collection("providers").doc(providerId).update({
        "status":    "approved",
        "isActive":  true,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // 2 — ✅ Set role: "provider" on users/{uid} so Firestore rules allow access
      await _updateUserRole(userId, "provider");

      // 3 — In-app notification (now carries type + providerId + businessName + serviceType)
      await _saveNotification(
        userId:       userId,
        title:        title,
        body:         body,
        type:         NotificationType.registrationApproved,
        providerId:   providerId,
        businessName: identity.businessName,
        serviceType:  serviceType,
      );

      // 4 — FCM push (same enriched payload, so a cold-start tap works too)
      await _sendFcm(
        token:        fcmToken,
        title:        title,
        body:         body,
        providerId:   providerId,
        userId:       userId,
        type:         NotificationType.registrationApproved,
        businessName: identity.businessName,
        serviceType:  serviceType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior:        SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16A34A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                "Provider approved & notified",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint("APPROVE ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // =====================================================
  // REJECT — with reason dialog
  // =====================================================

  Future<void> rejectProvider(String providerId) async {
    final TextEditingController reasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width:  64,
                height: 64,
                decoration: BoxDecoration(
                  color:        Colors.red.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.red, size: 32),
              ),
              const SizedBox(height: 18),
              const Text(
                "Reject Provider",
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "This provider will be notified with your reason.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: reasonController,
                maxLines:   4,
                decoration: InputDecoration(
                  hintText:  "Enter rejection reason (sent to provider)",
                  filled:    true,
                  fillColor: const Color(0xFFF5F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:   BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        elevation:       0,
                        backgroundColor: Colors.red,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "Reject",
                        style: TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    final String reason = reasonController.text.trim();

    try {
      final providerDoc =
          await firestore.collection("providers").doc(providerId).get();

      if (!providerDoc.exists) return;

      final data      = providerDoc.data() ?? {};
      final fcmToken  = (data["fcmToken"] ?? "").toString();
      final business  = (data["business"] as Map<String, dynamic>?) ?? {};
      final ownerName = (business["ownerName"] ?? "there").toString();

      // ✅ Read userId from provider doc
      final String userId = (data["userId"] ?? "").toString();
      final identity = _extractIdentity(data);

      const String title = "Account Not Approved";
      final String body  = reason.isNotEmpty
          ? "Hi $ownerName, your provider account was not approved. Reason: $reason"
          : "Hi $ownerName, your provider account was not approved at this time. Please contact support.";

      // 1 — Update provider doc status
      await firestore.collection("providers").doc(providerId).update({
        "status":       "rejected",
        "isActive":     false,
        "rejectReason": reason,
        "updatedAt":    FieldValue.serverTimestamp(),
      });

      // 2 — ✅ Reset role to "user" so provider access is revoked in rules
      if (userId.isNotEmpty) {
        await _updateUserRole(userId, "user");
      }

      // 3 — In-app notification (now correctly typed as registrationRejected,
      // not the plain "rejected" string, so the router matches it properly
      // and sends the person back to BusinessPage — not the dashboard).
      if (userId.isNotEmpty) {
        await _saveNotification(
          userId:       userId,
          title:        title,
          body:         body,
          type:         NotificationType.registrationRejected,
          providerId:   providerId,
          businessName: identity.businessName,
          serviceType:  identity.serviceType,
          reason:       reason,
        );
      }

      // 4 — FCM push
      if (userId.isNotEmpty) {
        await _sendFcm(
          token:        fcmToken,
          title:        title,
          body:         body,
          providerId:   providerId,
          userId:       userId,
          type:         NotificationType.registrationRejected,
          businessName: identity.businessName,
          serviceType:  identity.serviceType,
          reason:       reason,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior:        SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: const [
              Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text("Provider rejected & notified",
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint("REJECT ERROR: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // =====================================================
  // SERVICE ICON
  // =====================================================

  IconData getServiceIcon(String service) {
    final v = service.toLowerCase();
    if (v.contains("clean"))    return Icons.cleaning_services_rounded;
    if (v.contains("electric")) return Icons.electrical_services_rounded;
    if (v.contains("plumb"))    return Icons.plumbing_rounded;
    if (v.contains("water"))    return Icons.water_drop_rounded;
    if (v.contains("salon"))    return Icons.content_cut_rounded;
    if (v.contains("cook"))     return Icons.restaurant_rounded;
    if (v.contains("paint"))    return Icons.format_paint_rounded;
    if (v.contains("repair"))   return Icons.build_rounded;
    return Icons.miscellaneous_services_rounded;
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: pendingProvidersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return _emptyState();

            final filtered = docs.where((doc) {
              final data     = doc.data() as Map<String, dynamic>;
              final business =
                  (data['business'] as Map<String, dynamic>?) ?? {};
              final bName =
                  (business['businessName'] ?? "").toString().toLowerCase();
              final owner =
                  (business['ownerName'] ?? "").toString().toLowerCase();
              final phone =
                  (business['phone'] ?? "").toString().toLowerCase();
              return bName.contains(search) ||
                  owner.contains(search) ||
                  phone.contains(search);
            }).toList();

            return Column(
              children: [
                // ── HEADER ──────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft:  Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width:  54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.14),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.verified_user_rounded,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Provider Approvals",
                                  style: TextStyle(
                                    color:      Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize:   22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${filtered.length} pending request${filtered.length == 1 ? '' : 's'}",
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.20),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              "${docs.length}",
                              style: const TextStyle(
                                color:      Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize:   16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color:        Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          onChanged: (v) =>
                              setState(() => search = v.toLowerCase()),
                          decoration: const InputDecoration(
                            hintText:       "Search business, owner or phone",
                            border:         InputBorder.none,
                            prefixIcon:     Icon(Icons.search_rounded),
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 17),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── LIST ────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _noMatch()
                      : ListView.builder(
                          padding:     const EdgeInsets.all(16),
                          itemCount:   filtered.length,
                          itemBuilder: (_, i) =>
                              _providerCard(filtered[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =====================================================
  // PROVIDER CARD
  // =====================================================

  Widget _providerCard(DocumentSnapshot doc) {
    final data       = doc.data() as Map<String, dynamic>;
    final business   = (data['business'] as Map<String, dynamic>?) ?? {};
    final bank       = (data['bank']     as Map<String, dynamic>?) ?? {};
    final service    = (data['service']  as Map<String, dynamic>?) ?? {};
    final categories = List.from(data['categories'] ?? []);

    final Timestamp? createdAt = data['createdAt'];
    final providerId           = doc.id;
    final businessName         = business['businessName'] ?? "No Name";
    final ownerName            = business['ownerName']    ?? "-";
    final phone                = business['phone']        ?? "-";
    final email                = business['email']        ?? "-";
    final address              = business['address']      ?? "-";
    final serviceType =
        service['serviceType'] ?? data['serviceType'] ?? "-";
    final providerType = data['providerType'] ?? "Provider";
    // ✅ Show UID so admin can verify the link to users collection
    final userId = (data['userId'] ?? "-").toString();

    final String appliedDate = createdAt != null
        ? DateFormat('dd MMM yyyy').format(createdAt.toDate())
        : "-";

    return Container(
      margin:  const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset:     const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── TOP ROW ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width:  74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(getServiceIcon(serviceType),
                    color: Colors.white, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ownerName,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing:    8,
                      runSpacing: 8,
                      children: [
                        _badge("PENDING", Colors.orange),
                        _badge(providerType, const Color(0xFF4F46E5),
                            bg: const Color(0xFFEEF2FF)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── INFO BOX ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _compactInfo(Icons.phone_rounded, phone)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _compactInfo(Icons.email_rounded, email)),
                  ],
                ),
                const SizedBox(height: 12),
                _compactInfo(Icons.location_on_rounded, address),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _compactInfo(
                          Icons.miscellaneous_services_rounded,
                          serviceType),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _compactInfo(
                          Icons.calendar_month_rounded, appliedDate),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _compactInfo(Icons.account_balance_rounded,
                    bank['accountHolder']?.toString() ?? "-"),
                const SizedBox(height: 12),
                // ✅ Show UID to help admin debug mismatches
                _compactInfo(Icons.fingerprint_rounded, "UID: $userId"),
                const SizedBox(height: 12),
                _compactInfo(
                    Icons.badge_rounded, "Doc ID: $providerId"),
              ],
            ),
          ),

          // ── CATEGORIES ───────────────────────────
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Categories",
                style: TextStyle(
                    color:      Colors.grey.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing:    8,
              runSpacing: 8,
              children: categories
                  .map((c) => _badge(c.toString(),
                      const Color(0xFF4F46E5),
                      bg: const Color(0xFFEEF2FF)))
                  .toList(),
            ),
          ],

          const SizedBox(height: 22),

          // ── NOTIFICATION NOTE ─────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: const [
                Icon(Icons.notifications_active_rounded,
                    color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Provider will receive a push notification + in-app alert on your decision.",
                    style: TextStyle(
                        color: Color(0xFF15803D), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── ACTION BUTTONS ────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => rejectProvider(providerId),
                  icon:  const Icon(Icons.close_rounded, color: Colors.red),
                  label: const Text("Reject",
                      style: TextStyle(
                          color:      Colors.red,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side:    const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => approveProvider(providerId),
                  icon:  const Icon(Icons.check_rounded,
                      color: Colors.white),
                  label: const Text("Approve",
                      style: TextStyle(
                          color:      Colors.white,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    elevation:       0,
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // BADGE
  // =====================================================

  Widget _badge(String label, Color text, {Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:        bg ?? text.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: text, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  // =====================================================
  // COMPACT INFO ROW
  // =====================================================

  Widget _compactInfo(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              value.trim().isEmpty ? "-" : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  height:     1.4),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width:  96,
            height: 96,
            decoration: BoxDecoration(
              color:        const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.verified_user_rounded,
                size: 44, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 20),
          const Text("No Pending Providers",
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("All provider requests have been reviewed",
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // =====================================================
  // NO MATCH
  // =====================================================

  Widget _noMatch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(
            "No Matching Providers",
            style: TextStyle(
                color:      Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize:   16),
          ),
        ],
      ),
    );
  }
}