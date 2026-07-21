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

  // ═══════════════════════════════════════════════════════════════
  // FIX: DUPLICATE NOTIFICATION GUARD.
  // (unchanged from before — see previous comments)
  // ═══════════════════════════════════════════════════════════════
  final Set<String> _processingIds = {};

  bool _isProcessing(String providerId) => _processingIds.contains(providerId);

  void _lock(String providerId) {
    if (mounted) setState(() => _processingIds.add(providerId));
  }

  void _unlock(String providerId) {
    if (mounted) setState(() => _processingIds.remove(providerId));
  }

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
  //
  // ═══════════════════════════════════════════════════════════════
  // FIX (THIS IS THE MAIN CHANGE): _sendFcm() used to just return a
  // bool, so approveProvider()/rejectProvider() only ever knew
  // "it worked" or "it didn't" — never WHY. That's why the SnackBar
  // you saw only said "may not have been delivered. Check debug logs"
  // with no way to act on it from the UI.
  //
  // Now it returns a record: (success, reason). Two reasons cover
  // the two real-world failure modes:
  //
  //   1) "no_token"        → provider doc has no fcmToken saved yet.
  //      This happens when the provider registered but never actually
  //      logged into the app afterward (NotificationService._writeToken
  //      only runs once the app initializes for a logged-in user, so a
  //      provider who signed up and closed the app has no token yet).
  //      This is NOT an error — it's expected. The provider will still
  //      see the in-app bell notification the next time they open the
  //      app and log in; they just won't get an OS-level push this time.
  //
  //   2) "permission-denied" (or the raw exception text) → the write
  //      to fcm_queue was rejected by Firestore Security Rules. This
  //      is almost always because the rule looks like:
  //         allow create: if request.resource.data.receiverId == request.auth.uid;
  //      That rule is written assuming the PROVIDER writes their own
  //      queue doc, but here the ADMIN is writing a doc addressed to
  //      the provider. You need a rule that also allows the hardcoded
  //      admin UID/email to write to fcm_queue regardless of
  //      receiverId, e.g.:
  //
  //        match /fcm_queue/{doc} {
  //          allow create: if request.auth != null && (
  //            request.resource.data.receiverId == request.auth.uid ||
  //            request.auth.uid == '<ADMIN_UID>' ||
  //            request.auth.token.email == 'allinonecallme@gmail.com'
  //          );
  //        }
  // ═══════════════════════════════════════════════════════════════

  Future<({bool success, String? reason})> _sendFcm({
    required String token,
    required String title,
    required String body,
    required String providerId,
    required String userId,     // needed for fcm_queue rules
    required String type,
    String? businessName,
    String? serviceType,
    String? reason,
  }) async {
    if (token.trim().isEmpty) {
      debugPrint('[approve-fcm] No fcmToken saved for provider $providerId '
          '($userId) — push skipped (in-app notification still saved). '
          'This provider likely has not logged into the app since '
          'registering, so no token has been written to their provider '
          'doc yet.');
      return (success: false, reason: 'no_token');
    }

    final Map<String, dynamic> payload = {
      "token":      token.trim(),
      "title":      title,
      "body":       body,
      "providerId": providerId,
      "userId":     userId,     // fcm_queue rule: receiverId == uid()
      "receiverId": userId,     // fcm_queue rule: receiverId == uid()
      "type":       type,
      "createdAt":  FieldValue.serverTimestamp(),
      "sent":       false,
      "data": {
        "type":       type,
        "providerId": providerId,
        "receiverId": userId,
      },
    };

    if (businessName != null && businessName.trim().isNotEmpty) {
      payload["businessName"] = businessName.trim();
    }
    if (serviceType != null && serviceType.trim().isNotEmpty) {
      payload["serviceType"] = serviceType.trim();
    }
    if (reason != null && reason.trim().isNotEmpty) {
      payload["reason"] = reason.trim();
    }

    try {
      await firestore.collection("fcm_queue").add(payload);
      return (success: true, reason: null);
    } catch (e) {
      final msg = e.toString();
      final isPerm = msg.contains('permission-denied') ||
          msg.contains('PERMISSION_DENIED');
      debugPrint('[approve-fcm] fcm_queue write FAILED for provider '
          '$providerId ($userId): $e');
      if (isPerm) {
        debugPrint('[approve-fcm] This looks like a Firestore security '
            'rules issue: the admin (not the provider) is writing this '
            'doc, so a rule like "receiverId == request.auth.uid" will '
            'always reject it. Update the fcm_queue rule to also allow '
            'admin-initiated writes — see the comment above _sendFcm().');
        return (success: false, reason: 'permission-denied');
      }
      return (success: false, reason: msg);
    }
  }

  // =====================================================
  // SAVE NOTIFICATION (in-app bell)
  // =====================================================

  Future<bool> _saveNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? providerId,
    String? businessName,
    String? serviceType,
    String? reason,
  }) async {
    final Map<String, dynamic> notification = {
      "title":      title,
      "body":       body,
      "type":       type,
      "read":       false,
      "receiverId": userId,
      "createdAt":  FieldValue.serverTimestamp(),
    };

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

    try {
      await firestore.collection("notifications").add(notification);
      return true;
    } catch (e) {
      debugPrint('[approve-notif] notifications write FAILED for '
          '$userId: $e');
      return false;
    }
  }

  // =====================================================
  // UPDATE USER ROLE HELPER
  // =====================================================

  Future<void> _updateUserRole(String userId, String role) async {
    final userQuery = await firestore
        .collection("users")
        .where("uid", isEqualTo: userId)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      await userQuery.docs.first.reference.update({"role": role});
    } else {
      await firestore
          .collection("users")
          .doc(userId)
          .set({"role": role}, SetOptions(merge: true));
    }
  }

  // =====================================================
  // HELPER: turn a failure reason into a human-readable message
  // shown directly in the SnackBar, so you don't have to go dig
  // through debug logs to know which of the two cases it is.
  // =====================================================

  String _describeNotifFailure({
    required bool savedInApp,
    required bool pushQueued,
    required String? pushFailReason,
  }) {
    if (!savedInApp && !pushQueued) {
      return "Approved, but BOTH the in-app notification and push failed to "
          "save. This is likely a Firestore permission issue on the "
          "'notifications' or 'fcm_queue' collection — check your rules.";
    }
    if (savedInApp && !pushQueued) {
      if (pushFailReason == 'no_token') {
        return "Approved & in-app notification saved. No push sent — this "
            "provider hasn't logged into the app since registering, so no "
            "device token is on file yet. They'll see the bell notification "
            "once they log in.";
      }
      if (pushFailReason == 'permission-denied') {
        return "Approved & in-app notification saved, but the push was "
            "blocked by Firestore rules on 'fcm_queue' (admin writes need "
            "to be allowed there — see code comment in _sendFcm()).";
      }
      return "Approved & in-app notification saved, but push failed: "
          "${pushFailReason ?? 'unknown error'}";
    }
    // savedInApp == false, pushQueued == true (rare)
    return "Approved & push queued, but the in-app notification failed to "
        "save. Check Firestore rules on the 'notifications' collection.";
  }

  // =====================================================
  // APPROVE
  // =====================================================

  Future<void> approveProvider(String providerId) async {
    if (_isProcessing(providerId)) return; // already running — ignore
    _lock(providerId);

    Map<String, dynamic> data;
    String userId;
    String ownerName;
    ({String businessName, String serviceType}) identity;

    // ── STEP 1 — the actual approval action (idempotent) ────────────
    try {
      final ref = firestore.collection("providers").doc(providerId);

      final result = await firestore.runTransaction<Map<String, dynamic>?>(
        (tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) return null;

          final cur = snap.data() as Map<String, dynamic>;
          final curStatus = (cur["status"] ?? "").toString().toLowerCase();

          if (curStatus != "pending") {
            throw Exception('already_handled');
          }

          tx.update(ref, {
            "status":    "approved",
            "isActive":  true,
            "updatedAt": FieldValue.serverTimestamp(),
          });

          return cur;
        },
      );

      if (result == null) {
        _unlock(providerId);
        return;
      }

      data = result;
      final business = (data["business"] as Map<String, dynamic>?) ?? {};
      ownerName = (business["ownerName"] ?? "there").toString();

      userId = (data["userId"] ?? "").toString();
      if (userId.isEmpty) {
        _unlock(providerId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Provider userId missing — cannot approve."),
          ),
        );
        return;
      }

      identity = _extractIdentity(data);

      await _updateUserRole(userId, "provider");
    } catch (e) {
      _unlock(providerId);
      final isAlreadyHandled = e.toString().contains('already_handled');
      if (isAlreadyHandled) {
        debugPrint('[approve] Skipped — provider $providerId already '
            'handled by another call.');
        return;
      }
      debugPrint("APPROVE ERROR (core action): $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      return;
    }

    // ── STEP 2 — notify (best-effort, never blocks the success state,
    // and guaranteed to run at most ONCE thanks to Step 1's guard) ──
    final fcmToken = (data["fcmToken"] ?? "").toString();
    final businessName =
        identity.businessName.isNotEmpty ? identity.businessName : "your business";
    final serviceType = identity.serviceType;

    final String title = "🎉 Account Approved!";
    final String body = serviceType.isNotEmpty
        ? "Congratulations $ownerName! Your $serviceType business \"$businessName\" has been approved. You can now start receiving $serviceType bookings."
        : "Congratulations $ownerName! Your provider account has been approved. You can now start receiving bookings.";

    final savedInApp = await _saveNotification(
      userId:       userId,
      title:        title,
      body:         body,
      type:         NotificationType.registrationApproved,
      providerId:   providerId,
      businessName: identity.businessName,
      serviceType:  serviceType,
    );

    final pushResult = await _sendFcm(
      token:        fcmToken,
      title:        title,
      body:         body,
      providerId:   providerId,
      userId:       userId,
      type:         NotificationType.registrationApproved,
      businessName: identity.businessName,
      serviceType:  serviceType,
    );

    _unlock(providerId);
    if (!mounted) return;

    if (savedInApp && pushResult.success) {
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
    } else {
      // FIX: now shows the SPECIFIC reason instead of a generic message.
      final message = _describeNotifFailure(
        savedInApp:     savedInApp,
        pushQueued:     pushResult.success,
        pushFailReason: pushResult.reason,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration:        const Duration(seconds: 6),
          behavior:        SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // =====================================================
  // REJECT — with reason dialog
  // =====================================================

  Future<void> rejectProvider(String providerId) async {
    if (_isProcessing(providerId)) return;

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
    if (_isProcessing(providerId)) return; // re-check after the await
    _lock(providerId);

    final String reason = reasonController.text.trim();

    Map<String, dynamic> data;
    String userId;
    String ownerName;
    ({String businessName, String serviceType}) identity;

    // ── STEP 1 — the actual rejection action (idempotent) ───────────
    try {
      final ref = firestore.collection("providers").doc(providerId);

      final result = await firestore.runTransaction<Map<String, dynamic>?>(
        (tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) return null;

          final cur = snap.data() as Map<String, dynamic>;
          final curStatus = (cur["status"] ?? "").toString().toLowerCase();

          if (curStatus != "pending") {
            throw Exception('already_handled');
          }

          tx.update(ref, {
            "status":       "rejected",
            "isActive":     false,
            "rejectReason": reason,
            "updatedAt":    FieldValue.serverTimestamp(),
          });

          return cur;
        },
      );

      if (result == null) {
        _unlock(providerId);
        return;
      }

      data = result;
      final business = (data["business"] as Map<String, dynamic>?) ?? {};
      ownerName = (business["ownerName"] ?? "there").toString();

      userId = (data["userId"] ?? "").toString();
      identity = _extractIdentity(data);

      if (userId.isNotEmpty) {
        await _updateUserRole(userId, "user");
      }
    } catch (e) {
      _unlock(providerId);
      final isAlreadyHandled = e.toString().contains('already_handled');
      if (isAlreadyHandled) {
        debugPrint('[reject] Skipped — provider $providerId already '
            'handled by another call.');
        return;
      }
      debugPrint("REJECT ERROR (core action): $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      return;
    }

    // ── STEP 2 — notify (best-effort, guaranteed to run at most ONCE) ──
    final fcmToken = (data["fcmToken"] ?? "").toString();

    const String title = "Account Not Approved";
    final String body  = reason.isNotEmpty
        ? "Hi $ownerName, your provider account was not approved. Reason: $reason"
        : "Hi $ownerName, your provider account was not approved at this time. Please contact support.";

    bool savedInApp = true;
    ({bool success, String? reason}) pushResult = (success: true, reason: null);

    if (userId.isNotEmpty) {
      savedInApp = await _saveNotification(
        userId:       userId,
        title:        title,
        body:         body,
        type:         NotificationType.registrationRejected,
        providerId:   providerId,
        businessName: identity.businessName,
        serviceType:  identity.serviceType,
        reason:       reason,
      );

      pushResult = await _sendFcm(
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

    _unlock(providerId);
    if (!mounted) return;

    if (savedInApp && pushResult.success) {
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
    } else {
      final message = _describeNotifFailure(
        savedInApp:     savedInApp,
        pushQueued:     pushResult.success,
        pushFailReason: pushResult.reason,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration:        const Duration(seconds: 6),
          behavior:        SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
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
    final userId = (data['userId'] ?? "-").toString();

    // FIX: surfaced in the UI so you can see at a glance, BEFORE
    // tapping Approve, whether this provider even has a push token on
    // file yet — instead of only finding out after the fact via the
    // warning SnackBar.
    final hasToken = (data['fcmToken'] ?? '').toString().trim().isNotEmpty;

    final String appliedDate = createdAt != null
        ? DateFormat('dd MMM yyyy').format(createdAt.toDate())
        : "-";

    final bool busy = _isProcessing(providerId);

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
                        // FIX (NEW): visible warning chip when this
                        // provider has no push token on file yet, so
                        // you're not surprised by the orange SnackBar
                        // after tapping Approve.
                        if (!hasToken)
                          _badge("NO PUSH TOKEN YET", Colors.grey.shade700,
                              bg: Colors.grey.shade200),
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
              color: hasToken
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: hasToken
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFDBA74)),
            ),
            child: Row(
              children: [
                Icon(
                  hasToken
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: hasToken
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFC2410C),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasToken
                        ? "Provider will receive a push notification + in-app alert on your decision."
                        : "No device token on file yet — provider will only see the in-app alert once they next log in. No push will fire right now.",
                    style: TextStyle(
                        color: hasToken
                            ? const Color(0xFF15803D)
                            : const Color(0xFFC2410C),
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── ACTION BUTTONS ────────────────────────
          if (busy)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Color(0xFF4F46E5)),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Processing…",
                    style: TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
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